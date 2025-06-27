defmodule SongyWeb.Auth do
  use SongyWeb, :verified_routes
  require Logger

  import Plug.Conn
  alias Songy.Core.User

  def fetch_current_user(conn, _opts) do
    user = get_session(conn, :current_user)

    if user do
      assign(conn, :current_user, user)
    else
      assign(conn, :current_user, User.new())
    end
  end

  def put_channel_token(%{assigns: %{current_user: %{uuid: uuid}}} = conn, _) do
    assign(conn, :channel_token, Phoenix.Token.sign(conn, "user uuid", uuid))
  end

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
