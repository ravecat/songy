defmodule SongyWeb.AuthTest do
  use SongyWeb.ConnCase, async: true

  alias SongyWeb.Auth
  alias Songy.Core.User

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

  describe "put_channel_token/2" do
    test "creates channel token from user uuid", %{conn: conn} do
      user = User.new()

      conn =
        conn
        |> assign(:current_user, user)
        |> Auth.put_channel_token([])

      assert is_binary(conn.assigns.channel_token)

      # Verify token can be verified with same uuid
      {:ok, token_uuid} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "user uuid", conn.assigns.channel_token)

      assert token_uuid == user.uuid
    end

    test "works with user from session", %{conn: conn} do
      user = User.new()

      conn =
        conn
        |> put_session(:current_user, user)
        |> Auth.fetch_current_user([])
        |> Auth.put_channel_token([])

      assert is_binary(conn.assigns.channel_token)

      # Verify token integrity
      {:ok, token_uuid} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "user uuid", conn.assigns.channel_token)

      assert token_uuid == user.uuid
    end

    test "generates different tokens for different users", %{conn: conn} do
      user1 = User.new()
      user2 = User.new()

      conn1 =
        conn
        |> assign(:current_user, user1)
        |> Auth.put_channel_token([])

      conn2 =
        conn
        |> assign(:current_user, user2)
        |> Auth.put_channel_token([])

      assert conn1.assigns.channel_token != conn2.assigns.channel_token

      # Verify both tokens work correctly
      {:ok, token_uuid1} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "user uuid", conn1.assigns.channel_token)

      {:ok, token_uuid2} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "user uuid", conn2.assigns.channel_token)

      assert token_uuid1 == user1.uuid
      assert token_uuid2 == user2.uuid
    end
  end

  describe "plug pipeline integration" do
    test "fetch_current_user and put_channel_token work together", %{conn: conn} do
      conn =
        conn
        |> Auth.fetch_current_user([])
        |> Auth.put_channel_token([])

      assert %User{} = conn.assigns.current_user
      assert is_binary(conn.assigns.channel_token)

      # Verify token matches user
      {:ok, token_uuid} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "user uuid", conn.assigns.channel_token)

      assert token_uuid == conn.assigns.current_user.uuid
    end

    test "preserves existing user through pipeline", %{conn: conn} do
      original_user = User.new()

      conn =
        conn
        |> put_session(:current_user, original_user)
        |> Auth.fetch_current_user([])
        |> Auth.put_channel_token([])

      assert conn.assigns.current_user == original_user

      {:ok, token_uuid} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "user uuid", conn.assigns.channel_token)

      assert token_uuid == original_user.uuid
    end
  end
end
