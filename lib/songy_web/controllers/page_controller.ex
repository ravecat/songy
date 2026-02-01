defmodule SongyWeb.PageController do
  use SongyWeb, :controller

  alias Songy.Boundary.GameSession
  alias Songy.Boundary.Provider
  alias Songy.Providers

  def home(conn, _params) do
    user_id = conn.assigns.current_user.uuid

    conn
    |> assign_prop(:tracks, inertia_defer(fn -> fetch_tracks(user_id, 50) end))
    |> render_inertia("home")
  end

  defp fetch_tracks(user_id, limit) do
    with {:ok, _id, provider} <- Providers.ensure(user_id),
         {:ok, tracks} <- Provider.search(provider, term: <<Enum.random(?a..?z)>>, limit: limit, entity: "song") do
      tracks
    else
      _ -> []
    end
  end

  def create(conn, _params) do
    user_id = conn.assigns.current_user.uuid

    with {:ok, _id, _provider} <- Providers.ensure(user_id),
         {:ok, game} <- GameSession.create_game_session(user_id) do
      redirect(conn, to: ~p"/#{game.id}")
    else
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
