defmodule SongyWeb.PageController do
  use SongyWeb, :controller
  require Logger

  alias Songy.Boundary.GameSession

  def home(conn, _params) do
    conn
    |> assign_prop(:provider, conn.assigns[:provider])
    |> render_inertia("Home")
  end

  def create(conn, _params) do
    owner_uuid = conn.assigns.current_user.uuid
    provider_id = conn.assigns.provider.id

    case GameSession.create_game_session(owner_uuid, provider_id) do
      {:ok, game} ->
        redirect(conn, to: ~p"/#{game.id}")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to create game session: #{reason}")
        |> redirect(to: ~p"/")
    end
  end

  def join(conn, %{"room_id" => room_id}) do
    case GameSession.lookup_game_session(room_id) do
      {:ok, game} ->
        conn
        |> assign_prop(:room_id, game.id)
        |> render_inertia("Room")

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
