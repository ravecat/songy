import Config

port = String.to_integer(System.get_env("PORT") || "4001")
static_server_port = String.to_integer(System.get_env("VITE_PORT") || "5174")

config :songy, SongyWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: port],
  secret_key_base: "Puh1NLtCsE4ZyuOAo+juoEz4Hjh/8LI5nUOGBIhzx00Ewl661pI30SCVZ3oVfBNg",
  server: false,
  watchers: [vite: {Bun, :install_and_run, [:vite, ~w(dev --port #{static_server_port})]}],
  static_url: [host: "localhost", port: static_server_port]

config :songy, Songy.Mailer, adapter: Swoosh.Adapters.Test
config :swoosh, :api_client, false
config :logger, level: :emergency
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :songy,
  game_session_termination_timeout: 0,
  challenging_phase_timeout: 0,
  providers: [
    default: Songy.Core.Provider.Mock
  ]
