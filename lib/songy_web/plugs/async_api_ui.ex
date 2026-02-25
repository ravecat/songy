defmodule SongyWeb.Plugs.AsyncApiUI do
  @behaviour Plug

  @impl true
  def init(opts) do
    %{spec_url: Keyword.fetch!(opts, :spec_url)}
  end

  @impl true
  def call(conn, %{spec_url: spec_url}) do
    html = """
    <!doctype html>
    <html>
      <head>
        <title>AsyncAPI Reference</title>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="stylesheet" href="https://unpkg.com/@asyncapi/react-component@3/styles/default.min.css" />
        <style>
          body { font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif; }
        </style>
      </head>
      <body>
        <script src="https://unpkg.com/@asyncapi/react-component@3/browser/standalone/index.js"></script>
        <script>
          AsyncApiStandalone.render({
            schema: { url: '#{spec_url}' },
            config: { show: { sidebar: true } }
          }, document.body);
        </script>
      </body>
    </html>
    """

    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> Plug.Conn.send_resp(200, html)
  end
end
