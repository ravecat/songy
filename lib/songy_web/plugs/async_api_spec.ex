defmodule SongyWeb.Plugs.AsyncApiSpec do
  @behaviour Plug

  @spec_path "priv/specs/asyncapi.yaml"

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    spec_path = Application.app_dir(:songy, @spec_path)

    conn
    |> Plug.Conn.put_resp_content_type("text/yaml")
    |> Plug.Conn.send_resp(200, File.read!(spec_path))
  end
end
