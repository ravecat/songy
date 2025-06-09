defmodule SongyWeb.SpotifyController do
  use SongyWeb, :controller
  require Logger

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
    conn
    |> Spotify.Credentials.new()
    |> Spotify.Authentication.authenticate(%{"code" => code})
    |> case do
      {:ok, credentials} ->
        conn
        |> set_spotify_credentials(credentials)
        |> put_flash(:info, "Successfully connected to Spotify!")
        |> redirect(to: ~p"/")

      {:error, reason} ->
        Logger.error("Spotify authentication failed: #{inspect(reason)}")

        conn
        |> put_flash(:error, "Failed to authenticate with Spotify. Please try again.")
        |> redirect(to: ~p"/")
    end
  end

  def callback(conn, %{"error" => error}) do
    Logger.error("Spotify OAuth error: #{error}")

    conn
    |> put_flash(:error, "Authentication was cancelled or failed.")
    |> redirect(to: ~p"/")
  end

  def disconnect(conn, _params) do
    conn
    |> delete_spotify_credentials()
    |> put_flash(:info, "Disconnected from Spotify.")
    |> redirect(to: ~p"/")
  end

  defp set_spotify_credentials(conn, credentials) do
    put_session(conn, :spotify_credentials, credentials)
  end

  defp delete_spotify_credentials(conn) do
    delete_session(conn, :spotify_credentials)
  end
end
