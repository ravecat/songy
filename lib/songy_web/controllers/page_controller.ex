defmodule SongyWeb.PageController do
  use SongyWeb, :controller
  require Logger

  alias Songy.Boundary.GameSession
  alias Songy.Core.Provider.Apple
  alias Songy.Providers

  def home(conn, _params) do
    render_inertia(conn, "home")
  end

  def create(conn, params) do
    %{assigns: %{current_user: %{uuid: user_id}}} = conn

    provider = resolve_provider(params)

    with {:ok, conn} <- ensure_provider_ready(conn, provider),
         {:ok, game} <- GameSession.create_game_session(user_id) do
      redirect(conn, to: ~p"/#{game.id}")
    else
      {:redirect, conn} ->
        conn

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

  defp ensure_provider_ready(%{assigns: %{provider: :spotify}} = conn, :spotify),
    do: {:ok, conn}

  defp ensure_provider_ready(conn, :spotify) do
    return_to = current_path(conn, provider: :spotify)

    conn =
      conn
      |> put_session(:return_to, return_to)
      |> force_inertia_redirect()
      |> redirect(to: ~p"/auth/spotify")

    {:redirect, conn}
  end

  defp ensure_provider_ready(%{assigns: %{current_user: %{uuid: user_id}}} = conn, :apple) do
    Providers.insert(:providers, user_id, Apple.new())
    {:ok, conn}
  end

  defp ensure_provider_ready(conn, _provider), do: {:ok, conn}

  defp resolve_provider(%{"provider" => "apple"}), do: :apple
  defp resolve_provider(%{"provider" => "spotify"}), do: :spotify
  defp resolve_provider(_params), do: Application.fetch_env!(:songy, :default_provider)
end
