defmodule SongyWeb.SpotifyController do
  use SongyWeb, :controller

  alias Spotify.Authorization

  require Logger

  import SongyWeb.Auth

  def authorize(conn, _params) do
    case Authorization.url() do
      url when is_binary(url) ->
        redirect(conn, external: url)

      error ->
        Logger.error("Failed to generate Spotify auth URL: #{inspect(error)}")

        conn
        |> put_flash(:error, "Failed to connect to Spotify. Please try again.")
        |> redirect(to: ~p"/")
    end
  end

  def callback(conn, %{"code" => code}) do
    %{assigns: %{current_user: %{id: user_id}}} = conn

    with {:ok, provider} <- Songy.Boundary.Provider.Spotify.authenticate(conn, %{"code" => code}),
         :ok <- Songy.Providers.insert(user_id, provider) do
      redirect_to(conn)
    else
      {:error, _} ->
        conn
        |> delete_session(:return_to)
        |> put_flash(:error, "Failed to authenticate with Spotify. Please try again.")
        |> redirect(to: ~p"/")
    end
  end

  def callback(conn, %{"error" => error}) do
    Logger.error("Spotify OAuth error: #{error}")

    conn
    |> delete_session(:return_to)
    |> put_flash(:error, "Authentication was cancelled or failed.")
    |> redirect(to: ~p"/")
  end

  def callback(conn, _) do
    conn
    |> delete_session(:return_to)
    |> put_flash(:error, "Authentication was cancelled or failed.")
    |> redirect(to: ~p"/")
  end

  def disconnect(conn, _params) do
    %{assigns: %{current_user: %{id: user_id}}} = conn
    Songy.Providers.remove(user_id)

    conn
    |> delete()
    |> put_flash(:info, "Disconnected from Spotify.")
    |> redirect(to: ~p"/")
  end

  defp redirect_to(conn) do
    return_to = get_session(conn, :return_to)
    conn = delete_session(conn, :return_to)

    case return_to do
      return_to when is_binary(return_to) ->
        redirect(conn, to: return_to)

      _ ->
        conn
        |> put_flash(:info, "Successfully connected to Spotify!")
        |> redirect(to: ~p"/")
    end
  end
end
