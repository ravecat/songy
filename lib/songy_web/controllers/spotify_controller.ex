defmodule SongyWeb.SpotifyController do
  use SongyWeb, :controller

  require Logger

  import SongyWeb.Auth

  def authorize(conn, _params) do
    case Spotify.Authorization.url() do
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
    authenticate_with_spotify(conn, %{"code" => code})
  end

  def callback(conn, %{"error" => error}) do
    Logger.error("Spotify OAuth error: #{error}")

    conn
    |> put_flash(:error, "Authentication was cancelled or failed.")
    |> redirect(to: ~p"/")
  end

  def disconnect(conn, _params) do
    conn
    |> delete()
    |> put_flash(:info, "Disconnected from Spotify.")
    |> redirect(to: ~p"/")
  end
end
