defmodule Rujira do
  @moduledoc """
  Domain library for Rujira.

  Provides shared types, query APIs, and event parsing for the Rujira
  DeFi suite built on Cosmos/THORChain.

  ## Modules

  - `Rujira.Amount` — integer amounts normalized to 8 decimal places
  - `Rujira.Assets` — blockchain asset resolution across 20+ chains
  - `Rujira.Coin` — asset + amount pairs
  - `Rujira.Contracts` — CosmWasm contract queries
  - `Rujira.Deployments` — on-chain contract registry resolved live from THORChain
  - `Rujira.Events` — generic multi-protocol event parser
  - `Rujira.Fin` — FIN DEX query API (pairs, orders, ranges)
  - `Rujira.Math` — decimal arithmetic and numeric parsing
  - `Rujira.Node` — pluggable gRPC node abstraction
  - `Rujira.Prices` — pluggable price provider

  ## Configuration

      config :rujira_ex,
        node: MyApp.Node,
        prices: Rujira.Prices.Default,
        cache_ttl: 15_000
  """

  @doc """
  Returns the global cache TTL in milliseconds.

  Used by all `defmemo` calls with expiration. Configurable via:

      config :rujira_ex, cache_ttl: 15_000

  Defaults to 15 seconds. Set to 0 to disable expiration.
  """
  @spec cache_ttl() :: non_neg_integer()
  def cache_ttl do
    Application.get_env(:rujira_ex, :cache_ttl, 15_000)
  end

  @doc """
  Returns the TTL in milliseconds for a memoized block read.

  A block at a height never changes, so this bounds how long one is kept in
  memory rather than how stale it may be. Configurable via:

      config :rujira_ex, block_cache_ttl: 60_000

  Defaults to `cache_ttl/0`. Set to 0 to disable expiration.
  """
  @spec block_cache_ttl() :: non_neg_integer()
  def block_cache_ttl do
    Application.get_env(:rujira_ex, :block_cache_ttl, cache_ttl())
  end
end
