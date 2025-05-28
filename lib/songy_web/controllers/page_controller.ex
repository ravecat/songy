defmodule SongyWeb.PageController do
  use SongyWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
