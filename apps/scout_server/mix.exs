defmodule ScoutServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :scout_server,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Scout.Server.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:scout, in_umbrella: true},
      {:amqp, "~> 4.1"},
      {:dns_cluster, "~> 0.2.0"},
      {:jason, "~> 1.2"},
      {:phoenix_pubsub, "~> 2.1"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"]
    ]
  end
end
