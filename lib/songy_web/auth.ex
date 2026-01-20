defmodule SongyWeb.Auth do
  use SongyWeb, :verified_routes
  require Logger

  import Plug.Conn
  import Phoenix.Controller

  alias Songy.Core.Provider.Apple
  alias Songy.Core.Provider.ITunes
  alias Songy.Core.Provider.Spotify
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

  def fetch_current_provider(conn, _opts) do
    %{assigns: %{current_user: %{uuid: user_id}}} = conn

    case Songy.Providers.lookup(:providers, user_id) do
      {:ok, %Spotify{}} ->
        assign(conn, :provider, :spotify)

      {:ok, %Apple{}} ->
        assign(conn, :provider, :apple)

      {:ok, %ITunes{}} ->
        assign(conn, :provider, :itunes)

      _ ->
        assign(conn, :provider, Application.fetch_env!(:songy, :default_provider))
    end
  end

  def put_user_token(%{assigns: %{current_user: user}} = conn, _) do
    token = Phoenix.Token.sign(conn, "current_user", user.uuid)
    assign(conn, :user_token, token)
  end

  def put_user_token(conn, _), do: conn

  def delete(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end
end
