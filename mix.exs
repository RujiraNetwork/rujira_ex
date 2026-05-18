defmodule RujiraEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :rujira_ex,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Domain library for the Rujira protocol",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      licenses: ["MIT"],
      links: %{}
    ]
  end

  defp deps do
    [
      {:decimal, "~> 2.0"},
      {:grpc, "~> 0.9"},
      {:protobuf, "~> 0.12"},
      {:yaml_elixir, "~> 2.11"},
      {:json, "~> 1.4"},
      {:bech32, "~> 1.0"},
      {:memoize, "~> 1.4"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
