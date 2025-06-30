defmodule SongyWeb.PageController do
  use SongyWeb, :controller
  require Logger

  alias Songy.Boundary.GameSession

  def home(conn, _params) do
    render(conn, :home)
  end

  def start(conn, _params) do
    case GameSession.create_game_session() do
      {:ok, game} ->
        redirect(conn, to: ~p"/#{game.uuid}")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to create game session: #{reason}")
        |> redirect(to: ~p"/")
    end
  end

  def room(conn, %{"room_id" => room_id}) do
    case GameSession.get_game_session(room_id) do
      {:ok, _game} ->
        spotify_token = get_spotify_access_token(conn)

        conn
        |> assign_prop(:room_id, room_id)
        |> assign_prop(:spotify_token, spotify_token)
        |> render_inertia("Room")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Game session not found")
        |> redirect(to: ~p"/")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to access game session: #{reason}")
        |> redirect(to: ~p"/")
    end
  end

  defp get_spotify_access_token(conn) do
    case get_session(conn, :spotify_credentials) do
      %Spotify.Credentials{access_token: token} when not is_nil(token) -> token
      _ -> nil
    end
  end
end
