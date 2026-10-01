defmodule Songy.MixProject do
  use Mix.Project

  def project do
    [
      app: :songy,
      version: "0.1.0",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  def cli do
    [
      preferred_envs: [
        "test.watch": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Songy.Application, []},
      extra_applications: [:logger, :runtime_tools] ++ extra_applications(Mix.env())
    ]
  end

  defp extra_applications(:dev), do: [:wx, :observer]
  defp extra_applications(_), do: []

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:e2e), do: ["lib", "e2e/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.3"},
      {:dotenvy, "~> 1.1"},
      {:phoenix_vite, github: "ravecat/phoenix_vite", ref: "bbc672c"},
      {:phoenix, "~> 1.8.3"},
      {:phoenix_ecto, "~> 4.7"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.3"},
      {:phoenix_live_reload, "~> 1.6", only: :dev},
      {:phoenix_live_view, "~> 1.1.0"},
      {:floki, ">= 0.38.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:heroicons, github: "tailwindlabs/heroicons", tag: "v2.1.1", sparse: "optimized", app: false, compile: false},
      {:swoosh, "~> 1.16"},
      {:inertia, "~> 2.6"},
      {:req, "~> 0.5.17"},
      {:telemetry_metrics, "~> 1.1"},
      {:telemetry_poller, "~> 1.3"},
      {:gettext, "~> 0.26.2"},
      {:jason, "~> 1.4"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:typed_struct, "~> 0.3.0"},
      {:nimble_options, "~> 1.1"},
      {:gen_state_machine, "~> 3.0"},
      {:repatch, "~> 1.6", only: :test},
      {:mix_test_watch, "~> 1.4", only: [:dev, :test], runtime: false},
      {:recode, "~> 0.8.0", only: [:dev, :test], runtime: false},
      {:unique_names_generator, "~> 0.2"},
      {:polymorphic_embed, git: "https://github.com/mathieuprog/polymorphic_embed.git", tag: "v5.0.3"},
      {:spotify_ex, github: "jsncmgs1/spotify_ex", tag: "v2.4.0"},
      {:stream_data, "~> 1.2"},
      {:bodyguard, "~> 2.4.3"},
      {:qr_code, "~> 3.2"}
    ]
  end

  defp aliases do
    [
      serve: ["phx.server"],
      "test.only": ["test --only only"]
    ]
  end
end
