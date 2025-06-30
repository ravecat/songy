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
      new_user = User.new()

      conn
      |> put_session(:current_user, new_user)
      |> assign(:current_user, new_user)
    end
  end

  def put_channel_token(%{assigns: %{current_user: user}} = conn, _) do
    token_data = %{
      user_uuid: user.uuid,
      credentials: get_spotify_credentials(conn),
      provider: determine_provider(conn)
    }

    token = Phoenix.Token.sign(conn, "user_data", token_data)
    assign(conn, :channel_token, token)
  end

  def fetch_current_media_provider(conn, _opts) do
    provider = determine_provider(conn)
    assign(conn, :provider, provider)
  end

  defp determine_provider(conn) do
    if authenticated_with_spotify?(conn) do
      :spotify
    else
      nil
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
