defmodule Digitalocean.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/dymmer/digitalocean"

  def project do
    [
      app: :digitalocean,
      version: @version,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      name: "Digitalocean",
      description: "DigitalOcean API v2 Client and OAuth integration for Elixir",
      docs: docs(),
      package: package(),
      preferred_cli_env: [
        check: :test
      ]
    ]
  end

  defp dialyzer do
    [
      plt_local_path: ".plts",
      plt_core_path: ".plts",
      plt_add_apps: [:inets, :ssl, :public_key, :logger],
      flags: [:error_handling, :unknown]
    ]
  end

  defp package do
    [
      files: ~w(lib mix.exs README* COPYING* LICENSE* .formatter.exs),
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "Digitalocean",
      source_ref: "v#{@version}",
      canonical: "https://hexdocs.pm/digitalocean",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      mod: {Digitalocean.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:finch, "~> 0.17"},
      {:typed_ecto_schema, "~> 0.4"},
      {:ecto, "~> 3.12"},
      {:plug, "~> 1.0", only: :test},

      # only for dev / test
      {:dialyxir, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:doctor, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:ex_check, "~> 0.14", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:mix_audit, ">= 0.0.0", only: [:dev, :test], runtime: false}
    ]
  end
end
