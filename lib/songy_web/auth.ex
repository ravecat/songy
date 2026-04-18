defmodule SongyWeb.Auth do
  use SongyWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller, only: [delete_csrf_token: 0]

  alias Songy.Core.User

  def fetch_current_user(conn, _opts) do
    case get_session(conn, :current_user) do
      nil ->
        new_user = User.new()

        conn
        |> put_session(:current_user, new_user)
        |> assign(:current_user, new_user)

      user ->
        normalized_user = normalize_current_user(user)

        conn
        |> put_session(:current_user, normalized_user)
        |> assign(:current_user, normalized_user)
    end
  end

  def fetch_current_provider(conn, _opts) do
    %{assigns: %{current_user: %{id: user_id}}} = conn

    case Songy.Providers.ensure(user_id) do
      {:ok, %{id: id}} -> assign(conn, :provider, id)
      {:error, _reason} -> conn
    end
  end

  def put_user_token(%{assigns: %{current_user: user}} = conn, _) do
    token = Phoenix.Token.sign(conn, "current_user", user.id)
    assign(conn, :user_token, token)
  end

  def put_user_token(conn, _), do: conn

  def delete(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp normalize_current_user(%User{id: id, name: name, avatar_url: avatar_url}) do
    hydrate_user(id, name, avatar_url)
  end

  defp normalize_current_user(%{"id" => id} = user) when is_binary(id) do
    hydrate_user(id, user["name"], user["avatar_url"])
  end

  defp normalize_current_user(%{id: id} = user) when is_binary(id) do
    hydrate_user(id, Map.get(user, :name), Map.get(user, :avatar_url))
  end

  defp normalize_current_user(%{"uuid" => id} = user) when is_binary(id) do
    hydrate_user(id, user["name"], user["avatar_url"])
  end

  defp normalize_current_user(%{uuid: id} = user) when is_binary(id) do
    hydrate_user(id, Map.get(user, :name), Map.get(user, :avatar_url))
  end

  defp normalize_current_user(_user), do: User.new()

  defp hydrate_user(id, name, avatar_url) do
    user = User.get_user(id)

    %User{
      user
      | name: name || user.name,
        avatar_url: avatar_url || user.avatar_url
    }
  end
end
