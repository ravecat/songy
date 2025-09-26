defmodule SongyWeb.PageControllerTest do
  use SongyWeb.ConnCase

  import Inertia.Testing

  alias Songy.Boundary.GameSession

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert inertia_component(conn) == "Home"
  end

  describe "create/2" do
    test "creates game session authenticated by valid provider", %{conn: conn} do
      Repatch.patch(Songy.Providers, :lookup, fn :providers, _user_uuid ->
        {:ok, {:spotify, %{access_token: "test_token", expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)}}}
      end)

      conn = post(conn, ~p"/create")

      assert redirected_to(conn, 302) =~ ~r"^/[A-Za-z0-9_-]+$"

      location = redirected_to(conn, 302)
      uuid = String.trim_leading(location, "/")

      assert {:ok, _game} = GameSession.lookup_game_session(uuid)

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

    test "allows access to existing game session", %{conn: conn} do
      {:ok, game} = GameSession.create_game_session("owner123", :spotify)

      conn = get(conn, ~p"/#{game.id}")

      assert inertia_component(conn) == "Room"

      GameSession.end_game_session(game.id)
    end
  end
end
