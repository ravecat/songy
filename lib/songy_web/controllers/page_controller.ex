defmodule SongyWeb.PageController do
  use SongyWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def room(conn, %{"room_id" => room_id}) do
    conn
    |> assign_prop(:room_id, room_id)
    |> render_inertia("Room")
  end
end
