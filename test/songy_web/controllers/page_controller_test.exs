defmodule SongyWeb.PageControllerTest do
  use SongyWeb.ConnCase

  import Inertia.Testing

  alias Songy.Boundary.GameSession
  alias Songy.Provider.Session

  describe "home/2" do
    test "GET / renders home inertia component", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert inertia_component(conn) == "home"
    end

    test "GET / includes shared current user inertia prop", %{conn: conn} do
      conn = get(conn, ~p"/")

      props = inertia_props(conn)
      assert props.scope.user.uuid == conn.assigns.current_user.uuid
      assert props.scope.user.name == conn.assigns.current_user.name
    end
  end

  describe "create/2" do
    test "creates game session with default provider", %{conn: conn} do
      conn = post(conn, ~p"/create")
      assert redirected_to(conn, 302) =~ ~r"^/[A-Za-z0-9_-]+$"

      location = redirected_to(conn, 302)
      uuid = String.trim_leading(location, "/")

      assert {:ok, pid} = GameSession.lookup_game_session(uuid)
      assert Process.alive?(pid)

      GameSession.end_game_session(uuid)
    end
  end

  describe "create/2 error handling" do
    test "returns error when game session creation fails", %{conn: conn} do
      Repatch.patch(GameSession, :create_game_session, fn _user_id ->
        {:error, :database_error}
      end)

      conn = post(conn, ~p"/create")
      assert redirected_to(conn) == "/"

      assert "Failed to create game session: :database_error" =
               Phoenix.Flash.get(conn.assigns.flash, :error)
    end
  end

  describe "join/2" do
    test "returns error when accessing non-existent room", %{conn: conn} do
      room_id = "nonexistent_room"

      conn = get(conn, ~p"/#{room_id}")

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Game session not found"
    end

    test "allows access to existing game session", %{conn: conn} do
      {:ok, game} = GameSession.create_game_session("owner123")
      conn = get(conn, ~p"/#{game.id}")
      assert inertia_component(conn) == "room"
      GameSession.end_game_session(game.id)
    end

    test "returns error for other game session errors", %{conn: conn} do
      Repatch.patch(GameSession, :get_state, fn _room_id ->
        {:error, :timeout}
      end)

      room_id = "timeout_room"
      conn = get(conn, ~p"/#{room_id}")
      assert redirected_to(conn) == "/"

      assert "Failed to access game session: timeout" =
               Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "passes provider assignment to inertia", %{conn: conn} do
      {:ok, game} = GameSession.create_game_session("owner123")

      Repatch.patch(Songy.Providers, :lookup, fn _user_uuid ->
        {:ok, Session.normalize!(%Songy.Core.Provider.ITunes{})}
      end)

      conn = get(conn, ~p"/#{game.id}")
      assert inertia_component(conn) == "room"

      props = inertia_props(conn)
      assert props.roomId == game.id
      assert props.scope.provider == :itunes

      GameSession.end_game_session(game.id)
    end

    test "passes current user to inertia", %{conn: conn} do
      {:ok, game} = GameSession.create_game_session("owner123")

      conn = get(conn, ~p"/#{game.id}")

      props = inertia_props(conn)
      assert props.scope.user.uuid == conn.assigns.current_user.uuid
      assert props.scope.user.name == conn.assigns.current_user.name

      GameSession.end_game_session(game.id)
    end

    test "generates QR code SVG for room URL", %{conn: conn} do
      {:ok, game} = GameSession.create_game_session("owner123")

      conn = get(conn, ~p"/#{game.id}")

      props = inertia_props(conn)
      assert is_binary(props.qrSvg)
      assert props.qrSvg =~ "<svg"
      assert props.qrSvg =~ "<path"
      assert props.qrSvg =~ ~s(fill="transparent")

      GameSession.end_game_session(game.id)
    end
  end
end
