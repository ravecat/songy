defmodule SongyWeb.Plugs.Inertia do
  @behaviour Plug

  import Inertia.Controller, only: [assign_prop: 3]

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    assign_prop(conn, :scope, %{
      user: conn.assigns.current_user,
      provider: conn.assigns[:provider]
    })
  end
end
