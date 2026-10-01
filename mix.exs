defmodule RujiraEx.MixProject do
  use Mix.Project

  @version "0.7.2"
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
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      hex: hex()
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

  # Advisories `mix hex.audit` reports but that are accepted, each with its reason.
  # An entry that stops matching is reported as stale by the audit; remove it then.
  defp hex do
    [
      ignore_advisories: [
        # gun 2.4.1 / cowlib 2.20.0: HTTP request/response splitting (MEDIUM).
        # Dev-only (never in the Hex package): gun is the gRPC adapter for
        # scripts/refresh_chain_assets.exs, whose only inputs (endpoint, bearer
        # token) come from the operator's own environment. No fixed cowlib exists
        # and grpc 1.0.5 pins gun ~> 2.4.0; gun >= 2.4.0 raises on CR/LF in
        # outgoing request headers.
        "CVE-2026-43966",
        # cowlib 2.20.0: cookie header injection via cow_cookie:cookie/1 (LOW).
        # Same dev-only path; the script sets no cookies. No fixed version exists.
        "CVE-2026-43969"
      ]
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
        "guides/caching.md"
      ]
    ]
  end

  defp deps do
    [
      {:decimal, "~> 2.4 or ~> 3.0"},
      {:grpc, "~> 0.9 or ~> 1.0"},
      {:protobuf, "~> 0.12"},
      {:telemetry, "~> 1.0"},
      {:bech32, "~> 1.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: [:test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      # dev-only: the gRPC client adapter scripts/refresh_chain_assets.exs needs; not a runtime or Hex dependency
      {:gun, "~> 2.4.0", only: :dev}
    ]
  end
end
