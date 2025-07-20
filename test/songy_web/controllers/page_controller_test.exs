defmodule SongyWeb.PageControllerTest do
  use SongyWeb.ConnCase

  alias Songy.Boundary.GameSession
  alias Songy.Core.Provider

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Spotify"
  end

  describe "start/2" do
    test "creates game session authenticated by Spotify provider", %{conn: conn} do
      provider = %Provider{
        id: :spotify,
        meta: %{
          access_token: "test_token",
          expires_at: DateTime.utc_now() |> DateTime.add(3600, :second)
        }
      }

      conn = conn |> put_session(:provider, provider) |> post(~p"/start")

      assert redirected_to(conn, 302) =~ ~r"^/[A-Za-z0-9_-]+$"

      location = redirected_to(conn, 302)
      uuid = String.trim_leading(location, "/")

      assert {:ok, _game} = GameSession.lookup_game_session(uuid)

      GameSession.end_game_session(uuid)
    end

    test "returns error when provider is not authenticated", %{conn: conn} do
      conn = post(conn, ~p"/start")

      assert redirected_to(conn, 302) == "/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must be authenticated by one of the supported providers."
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
      provider = Provider.new(:spotify)
      {:ok, game} = GameSession.create_game_session("owner123", provider)

      conn = get(conn, ~p"/#{game.uuid}")

      assert html_response(conn, 200)

      GameSession.end_game_session(game.uuid)
    end
  end
end
