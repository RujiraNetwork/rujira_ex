defmodule RujiraEx.MixProject do
  use Mix.Project

  @version "0.7.3"
  @source_url "https://github.com/RujiraNetwork/rujira_ex"

  def project do
    [
      app: :rujira_ex,
      version: @version,
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Domain library for Rujira",
      package: package(),
      source_url: @source_url,
      docs: docs(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.json": :test,
        "coveralls.post": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Rujira.Application, []}
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
        "CHANGELOG.md",
        "CONTRIBUTING.md",
        "guides/conventions.md",
        "guides/architecture.md",
        "guides/event_pipeline.md",
        "guides/caching.md",
        "LICENSE"
      ],
      # The generated gRPC stub is hidden from the docs; name it as plain code.
      skip_code_autolink_to: [
        "Thorchain.Types.Query.Stub.contract_infos/2",
        "Thorchain.Types.Query.Stub.contract_infos/3"
      ],
      # The changelog names functions that have since been removed or renamed.
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp deps do
    [
      {:decimal, "~> 3.1 and >= 3.1.2"},
      {:grpc, "~> 1.0"},
      {:protobuf, "~> 0.17.1"},
      {:telemetry, "~> 1.0"},
      {:bech32, "~> 1.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: [:test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      # dev-only: the gRPC client adapter scripts/refresh_chain_assets.exs needs; not a runtime or Hex dependency
      {:mint, "~> 1.9", only: :dev}
    ]
  end
end
