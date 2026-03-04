import Config

# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
# Database connection disabled - uncomment if needed
# config :songy, Songy.Repo,
#   username: "postgres",
#   password: "postgres",
#   hostname: "localhost",
#   database: "songy_test#{System.get_env("MIX_TEST_PARTITION")}",
#   pool: Ecto.Adapters.SQL.Sandbox,
#   pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
port = String.to_integer(System.get_env("PORT") || "4002")
static_server_port = String.to_integer(System.get_env("VITE_PORT") || "5174")

config :songy, SongyWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: port],
  secret_key_base: "Puh1NLtCsE4ZyuOAo+juoEz4Hjh/8LI5nUOGBIhzx00Ewl661pI30SCVZ3oVfBNg",
  server: false,
  watchers: [vite: {Bun, :install_and_run, [:vite, ~w(dev --port #{static_server_port})]}],
  static_url: [host: "localhost", port: static_server_port]

# In test we don't send emails
config :songy, Songy.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Disable logging during tests
config :logger, level: :emergency

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :songy,
  game_session_termination_timeout: 0,
  challenging_phase_timeout: 0

config :mix_test_watch,
  tasks: ["test"],
  clear: true,
  exclude: [
    ~r/\.#/,
    ~r{priv/repo/migrations},
    ~r{\.worktrees/}
  ]
