# Rujira

Domain library for [Rujira](https://rujira.com), built on THORChain.

Provides shared types, query APIs, and event parsing for blockchain protocol data across 20+ chains.

## Installation

Add `rujira_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rujira_ex, "~> 0.1.0"}
  ]
end
```

## Modules

- `Rujira.Amount` — integer amounts normalized to 8 decimal places
- `Rujira.Assets` — blockchain asset resolution across 20+ chains (ETH, BTC, BSC, GAIA, SOL, etc.)
- `Rujira.Coin` — asset + amount pairs
- `Rujira.Fin` — FIN DEX query API (pairs, order books, orders, ranges)
- `Rujira.Events` — multi-protocol event parser with typed envelopes
- `Rujira.Contracts` — CosmWasm smart contract queries (memoized)
- `Rujira.Deployments` — on-chain contract registry resolved live from THORChain
- `Rujira.Node` — pluggable gRPC node abstraction
- `Rujira.Prices` — pluggable price provider with oracle and FIN book fallback
- `Rujira.Math` — decimal arithmetic and numeric parsing

## Configuration

```elixir
config :rujira_ex,
  node: MyApp.Node,           # required — implement Rujira.Node behaviour
  prices: Rujira.Prices.Default,  # optional — defaults to oracle + FIN mid-price fallback
  cache_ttl: 15_000           # optional — memoization TTL in ms (default: 15s)
```

## Usage

### Amounts and Coins

```elixir
# Amounts are normalized to 8 decimal places (1.0 = 100_000_000)
{:ok, amount} = Rujira.Amount.new("1.5")

# Parse coin strings
{:ok, coin} = Rujira.Coin.new(%{asset: "ETH.ETH", amount: "1500000000"})

# Parse comma-separated coins
{:ok, coins} = Rujira.Coin.parse("1000rune,500uatom")
```

### Asset Resolution

```elixir
{:ok, asset} = Rujira.Assets.from_denom("uatom")
{:ok, asset} = Rujira.Assets.from_string("GAIA.ATOM")
decimals = Rujira.Assets.decimals(asset)
```

### Event Parsing

```elixir
# Parse raw blockchain events into typed structs
{:ok, event} = Rujira.Events.parse(%{type: "wasm-rujira-fin/trade", attributes: attrs})

# Pattern match on protocol-specific event data
%Rujira.Fin.Events.Event{address: addr, data: %Rujira.Fin.Events.Trade{} = trade} = event
```

### FIN DEX Queries

```elixir
{:ok, pairs} = Rujira.Fin.list_pairs()
{:ok, pair} = Rujira.Fin.get_pair(pair_address)
{:ok, book} = Rujira.Fin.load_pair(pair, limit)
mid_price = Rujira.Fin.book_price(book)
```

## Guides

- [Coding Conventions](guides/conventions.md) — style, naming, return values, numeric parsing
- [Architecture](guides/architecture.md) — protocol structure, event pipeline, adding new protocols

## Development

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix credo --strict
mix dialyzer
```

## License

MIT — see [LICENSE](LICENSE) for details.
