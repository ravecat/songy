defmodule SongyWeb.PageController do
  use SongyWeb, :controller

  alias Songy.Boundary.GameSession
  alias Songy.Music

  def home(conn, _params) do
    user_id = conn.assigns.current_user.uuid

    conn
    |> assign_prop(:tracks, inertia_defer(fn -> Music.fetch_cover_tracks(user_id) end))
    |> render_inertia("home")
  end

  def create(conn, _params) do
    user_id = conn.assigns.current_user.uuid

    case GameSession.create_game_session(user_id) do
      {:ok, game} ->
        redirect(conn, to: ~p"/#{game.id}")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to create game session: #{inspect(reason)}")
        |> redirect(to: ~p"/")
    end
  end

  def join(conn, %{"room_id" => room_id}) do
    case GameSession.get_state(room_id) do
      {:ok, game} ->
        %{assigns: %{provider: provider}} = conn

        conn
        |> assign_prop(:room_id, game.id)
        |> assign_prop(:provider, provider)
        |> render_inertia("room")

      {:error, :game_session_not_found} ->
        conn
        |> put_flash(:error, "Game session not found")
        |> redirect(to: ~p"/")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to access game session: #{reason}")
        |> redirect(to: ~p"/")
    end
  end
end
