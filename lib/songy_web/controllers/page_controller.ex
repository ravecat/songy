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
end
