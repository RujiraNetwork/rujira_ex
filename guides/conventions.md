# Coding Conventions

## Typed chain access

Released in 0.6.0 as a breaking release-wide principle:

A struct's fields are exactly the chain data for the entity the caller asked
for — decoded, cast, normalised from that one read — or computed only from
that same read. Nothing is enriched from a second source. A second read's
math (a fee share, a redeemable value, a filled fee) is never a struct field;
it is an explicit pure function taking the structs the caller already holds
(e.g. `Order.filled_fee/2`, `Staking.Pool.Account.revenue_share/2`,
`Staking.Pool.Account.liquid_size/2`, `Ghost.Vault.Account.value/2`).

Pricing a position is one instance of this: nothing computes a `value_usd`
field internally — a caller who wants a USD value calls `Rujira.Prices`
itself, passing the amounts and ticker off the struct it already holds.

No silent defaults. An error is returned unchanged as `{:error, reason}` —
never replaced by `0`, `[]`, `nil`, a placeholder struct, or a default value,
and never re-labelled into a different error. A contract's "not found" is
`{:error, :not_found}` — check with `Rujira.Contracts.not_found?/1` rather
than matching the raw node error. Paging that terminates on an empty page is
not a silent default and stays as-is.

An absent chain value (a field the chain never set) is `nil`, not a
placeholder.

One entity family per read: a query returns data for the one entity kind the
caller asked about, not a composite of that entity plus another that happens
to be reachable from it.

## Entity ids

Every entity struct exposes an `id` field and a public `from_id(id, opts \\
[])` that resolves it at any `height:` and round-trips:
`from_id(x.id)` returns `x` (up to the read being live vs. historical).

- A well-formed id that names no entity on chain is `{:error, :not_found}`.
- A malformed id is `{:error, :invalid_id}`.

Exceptions:

- `Rujira.Brune.LoggedEvent` has no `from_id/2` — the contract's
  `events { start_after, limit }` only walks the log **descending from its
  current tip**, so no query can jump straight to an arbitrary older `seq`.
  Only `list/4`, paging back from the tip, can locate one.
- Embedded value structs with no on-chain address of their own, such as
  `Rujira.Thorchain.Oracle`, have no `from_id/2`.
- `Rujira.Assets.Asset` is resolved by `Rujira.Assets.from_id/1`, not a
  `from_id/2` on the struct itself — asset ids are not read at a height.

## Aliases

Always use explicit, fully qualified aliases. Never use the `{}` grouping syntax. Alphabetical order within each group.

```elixir
# good
alias Rujira.Fin.Events.Submit
alias Rujira.Fin.Events.Trade

# bad — grouped, unordered
alias Rujira.Fin.Events.{Trade, Submit}
```

## Return Values

**Fallible functions** (I/O, parsing, construction that can fail) must return `{:ok, term()} | {:error, term()}`.

**Infallible pure functions** (getters, math, formatting, predicates) return bare values.

Never return `nil` as a failure — use `{:error, :not_found}` or similar.

```elixir
# fallible — I/O or parsing
def from_denom(denom), do: {:ok, asset}
def from_denom(_), do: {:error, :invalid_denom}

# infallible pure — getter
def decimals(%Asset{chain: "ETH"}), do: 18
def label(%Asset{ticker: ticker}), do: ticker

# predicate
def eq_denom?(asset, denom), do: true
```

## Typespecs

Every public `def` must have `@spec`. Use defined types (`Asset.t()`, `Amount.t()`) not raw structs.

```elixir
# good
@spec from_denom(String.t()) :: {:ok, Asset.t()} | {:error, term()}

# bad — missing spec, raw struct
def from_denom(d), do: {:ok, %Asset{...}}
```

## Naming

| Pattern | Use | Returns |
|---------|-----|---------|
| `new/N` | Struct constructor | Bare struct (infallible) or `{:ok, struct()} \| {:error, _}` |
| `from_X/N` | Parse/convert from X format | `{:ok, _} \| {:error, _}` |
| `to_X/N` | Convert to X format | `{:ok, _} \| {:error, _}` (fallible) or bare (infallible) |
| `bang!/N` | Raises on error, returns bare | Bare value |

## Map Access

Use `Map.get/2` instead of bracket syntax for string-keyed maps.

```elixir
# good
Map.get(attrs, "key")

# bad
attrs["key"]
```

## Pattern Matching

Always prefer pattern matching in function heads over `case`, `cond`, or `if` inside the body.

## Numeric Parsing

One function per type. Absent values (`nil` and `""`) in → `{:ok, nil}` out. Use `with` chains. Never use raw `Decimal.parse` or `Integer.parse` with `{val, ""}` pattern.

Chain queries and event attributes render an absent field as `""`, not as a missing
key, so `""` is an absent value rather than a parse failure.

| Domain | Function | nil / `""` → | valid → | invalid → |
|--------|----------|-------|---------|-----------|
| Financial amount | `Amount.new/1` | `{:ok, nil}` | `{:ok, integer}` | `{:error, :invalid_amount}` |
| Decimal/price | `Math.to_decimal/1` | `{:ok, nil}` | `{:ok, Decimal.t}` | `{:error, :invalid_decimal}` |
| Plain integer | `Math.to_integer/1` | `{:ok, nil}` | `{:ok, integer}` | `{:error, :invalid_integer}` |

For plain strings, `Rujira.String.nil_if_empty/1` applies the same rule.

## Tokens

`Asset.t()` is the single token identity. Consumers pass a token in as an `Asset` and
get a quantity of one back as a `Coin` (asset + amount). Denom strings exist only at
the wire boundary — inside the memoized query that talks to the node.

| Type | Use | Example |
|------|-----|---------|
| `Asset.t()` | Token identity — arguments, struct fields, cache keys | `Assets.from_denom("btc-btc")` |
| `Coin.t()` | Asset + amount — user-facing, cross-protocol | `Coin.new("rune", 1000)` |
| `Amount.t()` | Bare integer — only where the token is fixed by the enclosing struct, e.g. order amounts inside a pair | `total: 0`, `Amount.new("500")` |

All amounts are integers normalized to 8 decimal places (`1.0 = 100_000_000`). Use
`Amount.new/1` for construction.

Denom metadata (symbol, name, display) is the one exception to height reads: it is
token identity, not chain state, so it is always read at latest - see "Query options".

`Rujira.Assets` converts an `Asset` into whichever form a caller needs. A form that
does not exist for that asset is an error, never a silent substitution:

| Conversion | Returns | When the form does not exist |
|------------|---------|------------------------------|
| `to_native/1` | the bank denom (`rune`, `x/ruji`, `btc-btc`) | `{:error, :no_native_denom}` — layer-1 on another chain, synth, trade |
| `to_secured/1` | the secured `Asset` (`BTC-BTC`) of a layer-1 asset; a secured asset unchanged | `{:error, :not_supported}` — THOR-chain assets, token-factory (`x/`) denoms, synth, trade |
| `to_layer1/1` | the layer-1 `Asset` (`BTC.BTC`) | `{:error, :not_supported}` — token-factory (`x/`) denoms |
| `pool_id/1` | the THORChain pool id string | propagates `to_layer1/1` |

`from_denom/1` is the inverse of `to_native/1` and takes bank denoms only. An asset id
such as `BTC.BTC` is not a denom — resolve those with `from_id/1`, which validates the
id and returns `{:error, :invalid_asset_id}` on a malformed one, or `from_string/1`,
which trusts its input and returns a bare `Asset`. Both are case-insensitive and
normalise chain and symbol to uppercase (`eth.eth` → `ETH.ETH`); `x/…` token-factory
ids are case-sensitive and kept as given.

## Struct Defaults

Every `defstruct` must declare explicit defaults — never use the bare `[:field]` syntax.

- Strings/references: `nil`
- Lists: `[]`
- Integers: `0`
- Decimals: `Decimal.new(0)`
- Loadable associations: `:not_loaded`
- Enums: the most common value (e.g. `side: :base`)

```elixir
# good
defstruct id: nil,
          items: [],
          total: 0,
          price: Decimal.new(0),
          book: :not_loaded

# bad — all nil, no type hints
defstruct [:id, :items, :total, :price, :book]
```

## Query Boundaries

Public query functions take and return **domain types**, never wire strings. If a
function hands back a typed value (an enum atom, a struct), callers must be able to
query — and therefore invalidate — with that same typed value.

- Wire serialization happens in exactly one place per query: the gRPC call inside
  the `defmemo`. Keep `Atom.to_string/1`, struct→map encoders, etc. there.
- `defmemo` cache keys are domain types (e.g. `Range.query(address, idx)` keys on
  the integer `idx`; `Order.query/4` keys on `:base | :quote` + `Price.order()`).
- Construction **canonicalizes** so equal values are equal terms — otherwise a typed
  cache key can miss (e.g. `1.5` vs `1.50`). `Price.parse/1` normalizes decimals for
  this reason.

Because keys are typed, invalidation needs no special API — invalidate with the same
typed values you query with:

```elixir
Memoize.invalidate(Rujira.Fin.Order, :query, [pair, owner, side, price])
```

## Visibility

Every public function on a resource module must be delegated from the facade (`defdelegate` in `Rujira.Protocol`) or be a `new` constructor. Everything else must be `defp`.

## Error Atoms

Use consistent error atoms across the codebase:

| Atom | When |
|------|------|
| `:invalid_amount` | `Amount.new/1` fails |
| `:invalid_integer` | `Math.to_integer/1` fails |
| `:invalid_decimal` | `Math.to_decimal/1` fails |
| `:invalid_time` | An RFC3339 timestamp from the chain cannot be parsed |
| `:invalid_id` | ID format doesn't match expected pattern |
| `:invalid_denom` | Denom not recognized by `Assets.from_denom/1` |
| `:invalid_asset_id` | Asset id rejected by `Assets.from_id/1` |
| `:no_native_denom` | `Assets.to_native/1` on an asset that is not held as a bank denom |
| `:invalid_coin_format` | `Coin.parse/1` cannot tokenize the input |
| `:invalid_event` | `Events.parse/1` given a non-event shape |
| `:invalid_attrs` | Sub-event `new/1`, or a resource `new/1`/`new/2`, got a map missing required keys |
| `:invalid_status` | `Brune.Node.new/1` got a node status string it doesn't recognise |
| `:invalid_response` | `Bank.Balance.get/3` or `Bank.Supply.get/2` got a node reply with no `balance`/`amount` — a malformed response, not a real chain value |
| `:not_found` | Resource lookup returns nothing — see "Entity ids" |
| `:not_loaded` | A calculation over a struct's `status: :not_loaded` association (e.g. `Staking.Pool.Account.revenue_share/2`, `Ghost.Vault.Account.value/2`) — load the association first |
| `:not_supported` | Operation valid in shape but disallowed (e.g. `Assets.to_secured/1` on a THOR-chain asset) |
| `:unknown_protocol` | `Deployments` saw an on-chain contract with no protocol mapping |
| `:no_price` | `Prices.get/1` could not resolve an oracle or FIN mid-price |
| `:invalid_height` | `Rujira.Node.query/3` given a `:height` opt - or `Rujira.Thorchain.block/2` a height - that isn't an integer in `1..9_223_372_036_854_775_807` |
| `:height_not_supported` | `Rujira.Node.query/3` given `:height` with an arity-2 `fun` (can't carry metadata); also `Prices.get/4`/`value_usd/4` given `:height` against an implementation with no opts arity |
| `{:height_mismatch, height, returned}` | The reply's `returned` height doesn't match the requested `height` - `Rujira.Node.query/3` reads it from the headers (`nil` when they were dropped), `Rujira.Thorchain.block/2` from the block header |
| `{:height_unavailable, height}` | A node error from `Rujira.Node.query/3` or `Rujira.Thorchain.block/2` means the requested `height` cannot be served (pruned, in the future, etc.) |

## Query options

`Rujira.Node.query/3` forwards `opts` unchanged to the configured impl, except
for the reserved `:height` key, which it pops before calling the impl.

Without `:height`, behaviour is unchanged. With a valid `:height`, `fun` must
be arity 3: `query/3` merges in `metadata: %{"x-cosmos-block-height" =>
height}` (keeping existing metadata keys) and `return_headers: true`, then
verifies the impl's reply actually carries that height before returning it -
a reply without a matching height is never returned as data, only as
`{:error, {:height_mismatch, height, returned}}`.

Every public function that reaches the node takes `opts` as its trailing
argument and passes it down to every query it makes, so a caller can read a
whole composite at one height. Pure functions take no `opts`.

The one documented exception is denom metadata (`Rujira.Assets.Metadata`,
`Rujira.Assets.load_metadata/2`): it is token identity, not chain state, so it
is always read at latest and memoized, and a `:height` in `opts` is accepted
(for arity parity) but ignored. An admin metadata change shows the current
symbol even in a historical read; every other field of that read still
reflects the requested height.

### Memoization

A height read is never cached — it is a read of the past, and caching it would
serve it as the present. So a memoized query keeps its name, arity and cache key
(`Memoize.invalidate(Mod, :fun, args)` keeps working) and gains a sibling one
arity higher that takes `opts`:

```elixir
@spec list() :: {:ok, [t()]} | {:error, term()}
defmemo list, do: fetch_list([])

@doc "As `list/0`; with `height:` it reads the node uncached, otherwise it is `list/0`."
@spec list(Node.opts()) :: {:ok, [t()]} | {:error, term()}
def list(opts), do: Node.at_height(opts, fn -> fetch_list(opts) end, &list/0)

defp fetch_list(opts), do: Node.query(&Stub.x/3, request, opts)
```

`Rujira.Node.at_height/3` is the only place the `:height` check lives. Without
`:height` the sibling is the memoized function, so any other opt is *not*
applied — a cached value cannot honour it. Pass `height:` to bypass the cache.

### Prices

Pricing a position is the caller's job, not the struct's — see "Typed chain
access". A caller that prices a position read at a height threads that same
`opts` into `Rujira.Prices`. `get/2` and `value_usd/4` are *optional*
callbacks, so an implementation predating them still satisfies the behaviour.
Asked for a `:height` such an implementation cannot serve, both return
`{:error, :height_not_supported}` — a price from the present is not a price at
that height, and returning one would misvalue the position silently.

### Coverage

`test/rujira/height_coverage_test.exs` holds one table per protocol facade
naming every public function that reaches the node, calls each with `height:`,
and asserts the first node call carries `x-cosmos-block-height`. A function
that never reaches the node is listed in its `@excluded` map with why. The two
lists together must name every public function of the facade, so a new one
fails the test until it is classified.

## Logger

Always use `Rujira.Logger` — never raw `Logger`. Pass `__MODULE__` as the first argument.

```elixir
Logger.error(__MODULE__, "load #{pair.address} #{inspect(err)}")
Logger.info(__MODULE__, "refreshed #{count} pairs")
```

## Section Comments

Organize resource modules with these section headers:

```elixir
# --- Struct ---
# --- Construction ---
# --- Queries ---
# --- Calculations ---     # if applicable
# --- Deployment protocol --- # if applicable
# --- Private ---
```

## Structure

- 1 module per file, 1 responsibility per module
- Structs with multiple sub-concerns get their own folder
- Event structs live in `events/` subfolder with `new/1` constructors

## Verification

All of these must pass before merge:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix credo --strict
mix dialyzer
```

## Dialyzer

Typespecs must be accurate — dialyzer warnings are treated as errors. Common pitfalls:

- Struct fields that default to `nil` must include `| nil` in `@type` (e.g. `id: String.t() | nil`)
- Return types must match all code paths (e.g. if a function can return `info: nil`, the type must allow it)
- Use `@spec` on every public function — dialyzer infers, but explicit specs catch contract mismatches early
