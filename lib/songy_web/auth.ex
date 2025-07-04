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
    case get_session(conn, :provider) do
      nil ->
        assign(conn, :provider, nil)

      provider ->
        {conn, provider} = ensure_provider(conn, provider)

        assign(conn, :provider, provider)
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

  def authenticate_with_spotify(conn, %{"code" => code}) do
    conn
    |> Spotify.Credentials.new()
    |> Spotify.Authentication.authenticate(%{"code" => code})
    |> case do
      {:ok, credentials} ->
        conn
        |> put_session(:provider, Provider.new(:spotify, credentials))
        |> put_flash(:info, "Successfully connected to Spotify!")
        |> redirect(to: ~p"/")

      {:error, reason} ->
        Logger.error("Spotify authentication failed: #{inspect(reason)}")

        conn
        |> put_flash(:error, "Failed to authenticate with Spotify. Please try again.")
        |> redirect(to: ~p"/")
    end
  end

  def delete(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp ensure_provider(conn, %{id: :spotify, meta: meta} = provider) do
    case Map.get(meta, :expires_at) do
      nil ->
        {delete_session(conn, :provider), nil}

      expires_at ->
        time_until_expiry = DateTime.diff(expires_at, DateTime.utc_now(), :second)

        if time_until_expiry <= @token_refresh_threshold do
          refresh_spotify_credentials(conn, meta)
        else
          {conn, provider}
        end
    end
  end

  defp ensure_provider(conn, _unsupported_provider) do
    {delete_session(conn, :provider), nil}
  end

  defp refresh_spotify_credentials(conn, meta) do
    credentials = struct(Spotify.Credentials, meta)

    case Spotify.Authentication.refresh(credentials) do
      {:ok, credentials} ->
        provider = Provider.new(:spotify, credentials)

        {put_session(conn, :provider, provider), provider}

      _error ->
        {delete_session(conn, :provider), nil}
    end
  end
end
