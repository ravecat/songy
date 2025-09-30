defmodule SongyWeb.AuthTest do
  use SongyWeb.ConnCase

  alias Songy.Core.User
  alias SongyWeb.Auth

  describe "fetch_current_user/2" do
    test "assigns existing user from session", %{conn: conn} do
      existing_user = User.new()

      conn =
        conn
        |> put_session(:current_user, existing_user)
        |> Auth.fetch_current_user([])

      assert conn.assigns.current_user == existing_user
    end

    test "creates new user when session is empty", %{conn: conn} do
      conn = Auth.fetch_current_user(conn, [])

      assert %User{} = conn.assigns.current_user
      assert is_binary(conn.assigns.current_user.uuid)
      assert String.length(conn.assigns.current_user.uuid) == 32
    end

    test "creates new user when session has nil", %{conn: conn} do
      conn =
        conn
        |> put_session(:current_user, nil)
        |> Auth.fetch_current_user([])

      assert %User{} = conn.assigns.current_user
      assert is_binary(conn.assigns.current_user.uuid)
    end
  end

  describe "put_user_token/2" do
    test "creates user token from user uuid", %{conn: conn} do
      user = User.new()

      conn =
        conn
        |> assign(:current_user, user)
        |> Auth.put_user_token([])

      assert is_binary(conn.assigns.user_token)

      # Verify token can be verified with new structure
      {:ok, user_uuid} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_user", conn.assigns.user_token)

      assert user_uuid == user.uuid
    end

    test "works with user from session", %{conn: conn} do
      user = User.new()

      conn =
        conn
        |> put_session(:current_user, user)
        |> Auth.fetch_current_user([])
        |> Auth.put_user_token([])

      assert is_binary(conn.assigns.user_token)

      # Verify token integrity
      {:ok, user_uuid} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_user", conn.assigns.user_token)

      assert user_uuid == user.uuid
    end

    test "generates different tokens for different users", %{conn: conn} do
      user1 = User.new()
      user2 = User.new()

      conn1 =
        conn
        |> assign(:current_user, user1)
        |> Auth.put_user_token([])

      conn2 =
        conn
        |> assign(:current_user, user2)
        |> Auth.put_user_token([])

      assert conn1.assigns.user_token != conn2.assigns.user_token

      # Verify both tokens work correctly
      {:ok, user_uuid1} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_user", conn1.assigns.user_token)

      {:ok, user_uuid2} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_user", conn2.assigns.user_token)

      assert user_uuid1 == user1.uuid
      assert user_uuid2 == user2.uuid
    end

    test "returns conn unchanged when no current_user", %{conn: conn} do
      conn_result = Auth.put_user_token(conn, [])
      assert conn_result == conn
      refute Map.has_key?(conn_result.assigns, :user_token)
    end
  end

  describe "put_provider_token/2" do
    test "creates provider token when provider exists", %{conn: conn} do
      provider = %{type: :spotify, data: %{token: "abc123"}}

      conn =
        conn
        |> assign(:provider, provider)
        |> Auth.put_provider_token([])

      assert is_binary(conn.assigns.provider_token)

      # Verify token can be verified
      {:ok, verified_provider} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_provider", conn.assigns.provider_token)

      assert verified_provider == provider
    end

    test "returns conn unchanged when no provider", %{conn: conn} do
      conn_result = Auth.put_provider_token(conn, [])
      assert conn_result == conn
      refute Map.has_key?(conn_result.assigns, :provider_token)
    end

    test "returns conn unchanged when provider is nil", %{conn: conn} do
      conn_result =
        conn
        |> assign(:provider, nil)
        |> Auth.put_provider_token([])

      assert conn_result.assigns.provider == nil
      refute Map.has_key?(conn_result.assigns, :provider_token)
    end
  end

  describe "plug pipeline integration" do
    test "fetch_current_user and put_user_token work together", %{conn: conn} do
      conn =
        conn
        |> Auth.fetch_current_user([])
        |> Auth.put_user_token([])

      assert %User{} = conn.assigns.current_user
      assert is_binary(conn.assigns.user_token)

      # Verify token matches user
      {:ok, user_uuid} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_user", conn.assigns.user_token)

      assert user_uuid == conn.assigns.current_user.uuid
    end

    test "preserves existing user through pipeline", %{conn: conn} do
      original_user = User.new()

      conn =
        conn
        |> put_session(:current_user, original_user)
        |> Auth.fetch_current_user([])
        |> Auth.put_user_token([])

      assert conn.assigns.current_user == original_user

      {:ok, user_uuid} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_user", conn.assigns.user_token)

      assert user_uuid == original_user.uuid
    end

    test "both tokens work together in pipeline", %{conn: conn} do
      user = User.new()
      provider = %{type: :spotify, data: %{token: "abc123"}}

      conn =
        conn
        |> assign(:current_user, user)
        |> assign(:provider, provider)
        |> Auth.put_user_token([])
        |> Auth.put_provider_token([])

      assert is_binary(conn.assigns.user_token)
      assert is_binary(conn.assigns.provider_token)

      # Verify both tokens work correctly
      {:ok, user_uuid} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_user", conn.assigns.user_token)

      {:ok, verified_provider} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_provider", conn.assigns.provider_token)

      assert user_uuid == user.uuid
      assert verified_provider == provider
    end
  end

  describe "fetch_current_provider/2" do
    test "assigns default provider when user has no provider in ETS", %{conn: conn} do
      user = User.new()

      Repatch.patch(Songy.Providers, :lookup, fn :providers, _user_uuid ->
        {:error, :not_found}
      end)

      conn =
        conn
        |> assign(:current_user, user)
        |> Auth.fetch_current_provider([])

      assert conn.assigns.provider == :spotify
    end

    test "assigns provider ID when provider data found in ETS", %{conn: conn} do
      user = User.new()
      credentials = %{access_token: "test_token"}

      Repatch.patch(Songy.Providers, :lookup, fn :providers, _user_uuid ->
        {:ok, {:spotify, credentials}}
      end)

      conn =
        conn
        |> assign(:current_user, user)
        |> Auth.fetch_current_provider([])

      assert conn.assigns.provider == :spotify
    end

    test "assigns default provider when ETS returns error", %{conn: conn} do
      user = User.new()

      Repatch.patch(Songy.Providers, :lookup, fn :providers, _user_uuid ->
        {:error, :timeout}
      end)

      conn =
        conn
        |> assign(:current_user, user)
        |> Auth.fetch_current_provider([])

      assert conn.assigns.provider == :spotify
    end

    test "assigns different provider IDs correctly", %{conn: conn} do
      user = User.new()

      # Test with :youtube provider
      Repatch.patch(Songy.Providers, :lookup, fn :providers, _user_uuid ->
        {:ok, {:youtube, %{token: "youtube_token"}}}
      end)

      conn =
        conn
        |> assign(:current_user, user)
        |> Auth.fetch_current_provider([])

      assert conn.assigns.provider == :youtube
    end
  end
end
