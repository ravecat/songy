defmodule SongyWeb.Auth do
  use SongyWeb, :verified_routes
  require Logger

  import Plug.Conn
  import Phoenix.Controller

  alias Songy.Core.Provider
  alias Songy.Core.User

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

  @doc """
  Plug for routes that require provider authentication.
  """
  def require_provider(conn, _opts) do
    if Map.get(conn.assigns, :provider) do
      conn
    else
      conn
      |> put_flash(:error, "You must be authenticated by one of the supported providers.")
      |> redirect(to: ~p"/")
      |> halt()
    end
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

  defp ensure_provider(conn, %Provider{meta: nil}) do
    Logger.warning("Provider credentials data are missing or invalid")
    {delete_session(conn, :provider), nil}
  end

  defp ensure_provider(conn, %Provider{id: :spotify} = provider) do
    ensure_spotify_provider(conn, provider)
  end

  defp ensure_provider(conn, _unsupported_provider) do
    {delete_session(conn, :provider), nil}
  end

  defp ensure_spotify_provider(conn, %Provider{meta: meta} = provider) do
    expires_at = meta.expires_at || DateTime.utc_now()
    threshold_time = DateTime.add(DateTime.utc_now(), @token_refresh_threshold, :second)

    with :lt <- DateTime.compare(expires_at, threshold_time),
         credentials <- struct(Spotify.Credentials, Map.from_struct(meta)),
         {:ok, refreshed_credentials} <- try_refresh_spotify_credentials(credentials) do
      credentials_map = Map.from_struct(refreshed_credentials)
      provider_with_credentials = Provider.new(:spotify, credentials_map)
      {put_provider_in_session(conn, provider_with_credentials), provider_with_credentials}
    else
      :gt ->
        {conn, provider}

      :eq ->
        {conn, provider}

      error ->
        Logger.warning("Failed to refresh Spotify credentials: #{inspect(error)}")
        {delete_session(conn, :provider), nil}
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
