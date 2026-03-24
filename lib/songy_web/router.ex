defmodule SongyWeb.Router do
  use SongyWeb, :router

  import SongyWeb.Auth

  pipeline :inertia do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SongyWeb.Layouts, :inertia_root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Inertia.Plug
    plug :fetch_current_user
    plug :fetch_current_provider
    plug :put_user_token
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SongyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :fetch_current_provider
    plug :put_user_token
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SongyWeb do
    pipe_through [:inertia]

    get "/create", PageController, :create
    post "/create", PageController, :create
  end

  scope "/", SongyWeb do
    pipe_through :browser

    get "/storybook", SongyWeb.Plugs.Storybook, :index, alias: false
  end

  scope "/", SongyWeb do
    pipe_through [:inertia]

    get "/", PageController, :home
    get "/:room_id", PageController, :join
  end

  scope "/api" do
    forward "/asyncapi/raw", SongyWeb.Plugs.AsyncApi, spec: "priv/specs/asyncapi.yaml"
    forward "/asyncapi", SongyWeb.Plugs.AsyncApi, url: "/api/asyncapi/raw"
  end

  scope "/auth/spotify", SongyWeb do
    pipe_through :browser

    get "/", SpotifyController, :authorize
    get "/callback", SpotifyController, :callback
    delete "/disconnect", SpotifyController, :disconnect
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:songy, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SongyWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
