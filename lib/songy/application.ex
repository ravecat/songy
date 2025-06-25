defmodule Songy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SongyWeb.Telemetry,
      Songy.Repo,
      {DNSCluster, query: Application.get_env(:songy, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Songy.PubSub},
      # Start a worker by calling: Songy.Worker.start_link(arg)
      # {Songy.Worker, arg},
      # Registry for game session process registration
      {Registry, [name: Songy.Registry, keys: :unique]},
      # Dynamic supervisor for game sessions
      {DynamicSupervisor, [name: Songy.Supervisor.GameSession, strategy: :one_for_one]},
      # Start Presence for tracking user presence in channels
      SongyWeb.Presence,
      # Start the SSR process pool for Inertia/Svelte
      # You must specify a `path` option to locate `ssr.js`
      {Inertia.SSR, path: Path.join([Application.app_dir(:songy), "priv"])},
      # Start to serve requests, typically the last entry
      SongyWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Songy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SongyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
