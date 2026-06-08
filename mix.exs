defmodule RujiraEx.MixProject do
  use Mix.Project

  @version "0.0.4"
  @source_url "https://github.com/RujiraNetwork/rujira_ex"

  def project do
    [
      app: :rujira_ex,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Domain library for Rujira",
      package: package(),
      source_url: @source_url,
      docs: docs()
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
      name: "rujira_ex",
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib config .formatter.exs mix.exs README.md LICENSE CONTRIBUTING.md guides)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "CONTRIBUTING.md",
        "guides/conventions.md",
        "guides/architecture.md"
      ]
    ]
  end

  defp deps do
    [
      {:decimal, "~> 2.0"},
      {:grpc, "~> 0.9"},
      {:protobuf, "~> 0.12"},
      {:bech32, "~> 1.0"},
      {:memoize, "~> 1.4"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end
end
