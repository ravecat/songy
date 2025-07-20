defmodule SongyWeb.PageController do
  use SongyWeb, :controller
  require Logger

  alias Songy.Boundary.GameSession
  alias Songy.Core.Provider

  def home(conn, _params) do
    render(conn, :home)
  end

  def start(conn, _params) do
    owner_uuid = conn.assigns.current_user.uuid
    %{id: provider_id} = conn.assigns.provider

    provider = Provider.new(provider_id)

    case GameSession.create_game_session(owner_uuid, provider) do
      {:ok, game} ->
        redirect(conn, to: ~p"/#{game.uuid}")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to create game session: #{reason}")
        |> redirect(to: ~p"/")
    end
  end

  def join(conn, %{"room_id" => room_id}) do
    case GameSession.lookup_game_session(room_id) do
      {:ok, _game} ->
        conn
        |> assign_prop(:room_id, room_id)
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
end
