# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :bun,
  version: "1.3.8",
  assets: [args: [], cd: Path.expand("../assets", __DIR__)],
  storybook: [
    args: ~w(x storybook dev --no-open --port 6006 --exact-port),
    cd: Path.expand("../assets", __DIR__)
  ],
  vite: [args: ~w(x vite), cd: Path.expand("../assets", __DIR__)],
  "e2e.watch": [
    args: [
      "x",
      "nodemon",
      "--watch",
      "../lib",
      "--watch",
      "e2e",
      "--watch",
      "js",
      "--ext",
      "ex,exs,heex,ts,js,svelte",
      "--ignore",
      "**/node_modules/**",
      "--ignore",
      "**/.git/**",
      "--delay",
      "50ms",
      "--signal",
      "SIGINT",
      "--exec",
      "playwright test --reporter=list"
    ],
    cd: Path.expand("../assets", __DIR__)
  ]

config :songy,
  # Ecto disabled for this project - using in-memory state management
  ecto_repos: [],
  generators: [timestamp_type: :utc_datetime],
  game_session_termination_timeout: :timer.minutes(3),
  challenging_phase_timeout: :timer.seconds(8),
  providers: [
    default: Songy.Core.Provider.ITunes,
    apple: [
      url: "https://api.music.apple.com/v1"
    ],
    itunes: [
      url: "https://itunes.apple.com"
    ]
  ]

# Configures the endpoint
config :songy, SongyWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: SongyWeb.ErrorHTML, json: SongyWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Songy.PubSub,
  live_view: [signing_salt: "lIwSQ/DK"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :songy, Songy.Mailer, adapter: Swoosh.Adapters.Local

config :inertia,
  # The Phoenix Endpoint module for your application. This is used for building
  # asset URLs to compute a unique version hash to track when something has
  # changed (and a reload is required on the frontend).
  endpoint: SongyWeb.Endpoint,

  # An optional list of static file paths to track for changes. You'll generally
  # want to include any JavaScript assets that may require a page refresh when
  # modified.
  static_paths: ["/assets/js/app.js"],

  # The default version string to use (if you decide not to track any static
  # assets using the `static_paths` config). Defaults to "1".
  default_version: "1",

  # Enable automatic conversion of prop keys from snake case (e.g. `inserted_at`),
  # which is conventional in Elixir, to camel case (e.g. `insertedAt`), which is
  # conventional in JavaScript. Defaults to `false`.
  camelize_props: true,

  # Instruct the client side whether to encrypt the page object in the window history
  # state. This can also be set/overridden on a per-request basis, using the `encrypt_history`
  # controller helper. Defaults to `false`.
  history: [encrypt: false],

  # Enable server-side rendering for page responses (requires some additional setup,
  # see instructions below). Defaults to `false`.
  ssr: false,

  # Whether to raise an exception when server-side rendering fails (only applies
  # when SSR is enabled). Defaults to `true`.
  #
  # Recommended: enable in non-production environments and disable in production,
  # so that SSR failures will not cause 500 errors (but instead will fallback to
  # CSR).
  raise_on_ssr_failure: config_env() != :prod

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
