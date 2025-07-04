defmodule SongyWeb.PageControllerTest do
  use SongyWeb.ConnCase

  alias Songy.Boundary.GameSession

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Spotify"
  end

  describe "start/2" do
    test "creates game session and redirects to room", %{conn: conn} do
      conn = post(conn, ~p"/start")

      assert redirected_to(conn, 302) =~ ~r"^/[A-Za-z0-9_-]+$"

      location = redirected_to(conn, 302)
      uuid = String.trim_leading(location, "/")

      assert GameSession.session_exists?(uuid)

      GameSession.end_game_session(uuid)
    end
  end

  describe "join/2" do
    test "returns error when accessing non-existent room", %{conn: conn} do
      room_id = "nonexistent_room"

      conn = get(conn, ~p"/#{room_id}")

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Game session not found"
    end

    test "accesses existing game session", %{conn: conn} do
      {:ok, game} = GameSession.create_game_session("owner123")

      conn = get(conn, ~p"/#{game.uuid}")

      assert html_response(conn, 200)

      # Cleanup
      GameSession.end_game_session(game.uuid)
    end
  end
end
