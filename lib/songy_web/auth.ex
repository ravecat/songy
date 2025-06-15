defmodule SongyWeb.Auth do
  use SongyWeb, :verified_routes

  import Plug.Conn

  def fetch_current_media_provider(conn, _opts) do
    if authenticated_with_spotify?(conn) do
      assign(conn, :provider, :spotify)
    else
      assign(conn, :provider, nil)
    end
  end

  defp authenticated_with_spotify?(conn) do
    get_spotify_credentials(conn)
    |> Spotify.Authentication.authenticated?()
  end

  defp get_spotify_credentials(conn) do
    get_session(conn, :spotify_credentials, Spotify.Credentials.new(conn))
  end
end
