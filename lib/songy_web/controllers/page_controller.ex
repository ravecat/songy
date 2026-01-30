defmodule SongyWeb.PageController do
  use SongyWeb, :controller

  alias Songy.Boundary.GameSession
  alias Songy.Boundary.Provider
  alias Songy.Providers

  def home(conn, _params) do
    conn
    |> assign_prop(:tracks, inertia_defer(fn -> fetch_tracks(50) end))
    |> render_inertia("home")
  end

  defp fetch_tracks(limit) do
    case Provider.search(Providers.default(), term: <<Enum.random(?a..?z)>>, limit: limit, entity: "song") do
      {:ok, tracks} -> tracks
      _ -> []
    end
  end

  def create(conn, params) do
    user_id = conn.assigns.current_user.uuid
    provider = resolve_provider(params)

    case Providers.ensure_ready(:providers, user_id, provider) do
      :ok ->
        case GameSession.create_game_session(user_id) do
          {:ok, game} ->
            redirect(conn, to: ~p"/#{game.id}")

          {:error, reason} ->
            conn
            |> put_flash(:error, "Failed to create game session: #{inspect(reason)}")
            |> redirect(to: ~p"/")
        end

      {:redirect, :spotify} ->
        conn
        |> put_session(:return_to, current_path(conn, provider: :spotify))
        |> force_inertia_redirect()
        |> redirect(to: ~p"/auth/spotify")
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

  defp resolve_provider(%{"provider" => "apple"}), do: :apple
  defp resolve_provider(%{"provider" => "itunes"}), do: :itunes
  defp resolve_provider(%{"provider" => "spotify"}), do: :spotify
  defp resolve_provider(_params), do: Application.fetch_env!(:songy, :default_provider)
end
