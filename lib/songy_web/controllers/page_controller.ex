defmodule SongyWeb.PageController do
  use SongyWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def inertia(conn, _params) do
    conn
    |> assign_prop(:message, "Phoenix and Inertia and Svelte")
    |> assign_prop(:name, "Songy")
    |> render_inertia("welcome")
  end

  def room(conn, %{"room_id" => room_id}) do
    conn
    |> assign_prop(:room_id, room_id)
    |> render_inertia("Room")
  end
end
