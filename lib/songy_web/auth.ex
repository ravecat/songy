defmodule SongyWeb.Auth do
  use SongyWeb, :verified_routes
  require Logger

  import Plug.Conn
  import Phoenix.Controller

  alias Songy.Core.User
  alias Songy.Core.Provider

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
    with provider when not is_nil(provider) <- get_session(conn, :provider),
         {conn, provider} <- ensure_provider(conn, provider) do
      assign(conn, :provider, provider)
    else
      _ -> assign(conn, :provider, nil)
    end
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

  def authenticate(conn, :spotify, %{"code" => code}) do
    conn
    |> Spotify.Credentials.new()
    |> Spotify.Authentication.authenticate(%{"code" => code})
    |> case do
      {:ok, credentials} ->
        conn
        |> put_provider_in_session(Provider.new(:spotify, credentials))
        |> put_flash(:info, "Successfully connected to Spotify!")
        |> redirect(to: ~p"/")

      {:error, reason} ->
        Logger.error("Spotify authentication failed: #{inspect(reason)}")

        conn
        |> put_flash(:error, "Failed to authenticate with Spotify. Please try again.")
        |> redirect(to: ~p"/")
    end
  end

  def authenticate(conn, _provider, _params) do
    conn
    |> put_flash(:error, "Unsupported provider or missing parameters.")
    |> redirect(to: ~p"/")
  end

  def delete(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp put_provider_in_session(conn, provider) do
    put_session(conn, :provider, provider)
  end

  defp ensure_provider(conn, %{id: :spotify} = provider) do
    ensure_spotify_provider(conn, provider)
  end

  defp ensure_provider(conn, _unsupported_provider) do
    {delete_session(conn, :provider), nil}
  end

  defp ensure_spotify_provider(conn, provider) do
    expires_at = Map.get(provider.meta, :expires_at, DateTime.utc_now())
    time_until_expiry = DateTime.diff(expires_at, DateTime.utc_now(), :second)

    if time_until_expiry > @token_refresh_threshold do
      {conn, provider}
    else
      credentials = struct(Spotify.Credentials, provider.meta)

      case try_refresh_spotify_credentials(credentials) do
        {:ok, credentials} ->
          updated_provider = Provider.new(:spotify, credentials)

          {put_provider_in_session(conn, updated_provider), updated_provider}

        _error ->
          Logger.warning("Failed to refresh Spotify credentials")

          {delete_session(conn, :provider), nil}
      end
    end
  end

  defp try_refresh_spotify_credentials(credentials) do
    try do
      Spotify.Authentication.refresh(credentials)
    rescue
      Spotify.AuthenticationError -> {:error, :invalid_credentials_data}
    end
  end
end
