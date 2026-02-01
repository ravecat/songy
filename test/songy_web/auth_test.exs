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
      {:ok, user_id} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_user", conn.assigns.user_token)

      assert user_id == user.uuid
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
      {:ok, user_id} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_user", conn.assigns.user_token)

      assert user_id == user.uuid
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

  describe "plug pipeline integration" do
    test "fetch_current_user and put_user_token work together", %{conn: conn} do
      conn =
        conn
        |> Auth.fetch_current_user([])
        |> Auth.put_user_token([])

      assert %User{} = conn.assigns.current_user
      assert is_binary(conn.assigns.user_token)

      # Verify token matches user
      {:ok, user_id} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_user", conn.assigns.user_token)

      assert user_id == conn.assigns.current_user.uuid
    end

    test "preserves existing user through pipeline", %{conn: conn} do
      original_user = User.new()

      conn =
        conn
        |> put_session(:current_user, original_user)
        |> Auth.fetch_current_user([])
        |> Auth.put_user_token([])

      assert conn.assigns.current_user == original_user

      {:ok, user_id} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_user", conn.assigns.user_token)

      assert user_id == original_user.uuid
    end
  end

  describe "fetch_current_provider/2" do
    test "assigns default provider when ensure creates default", %{conn: conn} do
      user = User.new()

      Repatch.patch(Songy.Providers, :ensure, fn _user_uuid ->
        {:ok, :itunes, %Songy.Core.Provider.ITunes{}}
      end)

      conn =
        conn
        |> assign(:current_user, user)
        |> Auth.fetch_current_provider([])

      assert conn.assigns.provider == :itunes
    end

    test "assigns :spotify when user has Spotify provider", %{conn: conn} do
      user = User.new()

      Repatch.patch(Songy.Providers, :ensure, fn _user_uuid ->
        {:ok, :spotify, %Songy.Core.Provider.Spotify{access_token: "token", refresh_token: "refresh"}}
      end)

      conn =
        conn
        |> assign(:current_user, user)
        |> Auth.fetch_current_provider([])

      assert conn.assigns.provider == :spotify
    end

    test "assigns :itunes when user has ITunes provider", %{conn: conn} do
      user = User.new()

      Repatch.patch(Songy.Providers, :ensure, fn _user_uuid ->
        {:ok, :itunes, %Songy.Core.Provider.ITunes{}}
      end)

      conn =
        conn
        |> assign(:current_user, user)
        |> Auth.fetch_current_provider([])

      assert conn.assigns.provider == :itunes
    end

    test "assigns :apple when user has Apple provider", %{conn: conn} do
      user = User.new()

      Repatch.patch(Songy.Providers, :ensure, fn _user_uuid ->
        {:ok, :apple, %Songy.Core.Provider.Apple{}}
      end)

      conn =
        conn
        |> assign(:current_user, user)
        |> Auth.fetch_current_provider([])

      assert conn.assigns.provider == :apple
    end

    test "does not assign provider when ensure returns error", %{conn: conn} do
      user = User.new()

      Repatch.patch(Songy.Providers, :ensure, fn _user_uuid ->
        {:error, :network_error}
      end)

      conn =
        conn
        |> assign(:current_user, user)
        |> Auth.fetch_current_provider([])

      refute Map.has_key?(conn.assigns, :provider)
    end
  end
end
