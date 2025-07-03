defmodule SongyWeb.Auth do
  use SongyWeb, :verified_routes
  require Logger

  import Plug.Conn
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  alias Songy.Core.User
  alias Songy.Core.Provider

  @spotify_token_expires_in 3600
  @token_refresh_threshold 300

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

  def fetch_current_provider(conn, _opts) do
    assign(conn, :provider, get_session(conn, :provider))
  end

  def put_user_token(%{assigns: %{current_user: user}} = conn, _) do
    token = Phoenix.Token.sign(conn, "current_user", user.uuid)
    assign(conn, :user_token, token)
  end

  def put_user_token(conn, _), do: conn

  def put_provider_token(%{assigns: %{provider: provider}} = conn, _) when provider != nil do
    token = Phoenix.Token.sign(conn, "current_provider", provider)
    assign(conn, :provider_token, token)
  end

  def put_provider_token(conn, _), do: conn

  def authenticate_with_spotify(conn, %{"code" => code}) do
    conn
    |> Spotify.Credentials.new()
    |> Spotify.Authentication.authenticate(%{"code" => code})
    |> case do
      {:ok, credentials} ->
        credentials_with_expiry = set_expires_at(credentials)
        provider = Provider.new(:spotify, credentials_with_expiry)

        conn
        |> put_session(:provider, provider)
        |> put_flash(:info, "Successfully connected to Spotify!")
        |> redirect(to: ~p"/")

      {:error, reason} ->
        Logger.error("Spotify authentication failed: #{inspect(reason)}")

        conn
        |> put_flash(:error, "Failed to authenticate with Spotify. Please try again.")
        |> redirect(to: ~p"/")
    end
  end

  def ensure_credentials(conn) do
    case get_session(conn, :credentials) do
      nil ->
        {:error, :unauthorized}

      %{expires_at: nil} ->
        delete_session(conn, :credentials)
        {:error, :invalid_credentials}

      credentials ->
        validate_and_refresh_credentials(conn, credentials)
    end
  end

  defp validate_and_refresh_credentials(conn, credentials) do
    time_until_expiry =
      DateTime.diff(Map.get(credentials, :expires_at), DateTime.utc_now(), :second)

    if time_until_expiry <= @token_refresh_threshold do
      refresh_credentials(conn, credentials)
    else
      {:ok, credentials}
    end
  end

  defp refresh_credentials(conn, credentials) do
    case Spotify.Authentication.refresh(credentials) do
      {:ok, refreshed_credentials} ->
        updated_credentials = set_expires_at(refreshed_credentials)
        put_session(conn, :credentials, updated_credentials)
        {:ok, updated_credentials}

      {:error, reason} ->
        Logger.warning("Failed to refresh Spotify token: #{inspect(reason)}")
        delete_session(conn, :credentials)
        {:error, reason}
    end
  end

  defp set_expires_at(credentials) do
    expires_at = DateTime.utc_now() |> DateTime.add(@spotify_token_expires_in, :second)

    Map.put(credentials, :expires_at, expires_at)
  end

  def delete_spotify_credentials(conn) do
    delete_session(conn, :credentials)
  end
end
