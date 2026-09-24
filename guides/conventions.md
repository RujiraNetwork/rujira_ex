# Coding Conventions

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

`Rujira.Assets` converts an `Asset` into whichever form a caller needs. A form that
does not exist for that asset is an error, never a silent substitution:

| Conversion | Returns | When the form does not exist |
|------------|---------|------------------------------|
| `to_native/1` | the bank denom (`rune`, `x/ruji`, `btc-btc`) | `{:error, :no_native_denom}` — layer-1 on another chain, synth, trade |
| `to_secured/1` | the secured `Asset` (`BTC-BTC`) | `{:error, :not_supported}` — THOR-chain assets |
| `to_layer1/1` | the layer-1 `Asset` (`BTC.BTC`) | `{:error, :not_supported}` — token-factory (`x/`) denoms |
| `pool_id/1` | the THORChain pool id string | propagates `to_layer1/1` |

`from_denom/1` is the inverse of `to_native/1` and takes bank denoms only. An asset id
such as `BTC.BTC` is not a denom — resolve those with `from_string/1` / `from_id/1`.

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
| `:invalid_id` | ID format doesn't match expected pattern |
| `:invalid_denom` | Denom not recognized by `Assets.from_denom/1` |
| `:no_native_denom` | `Assets.to_native/1` on an asset that is not held as a bank denom |
| `:invalid_coin_format` | `Coin.parse/1` cannot tokenize the input |
| `:invalid_event` | `Events.parse/1` given a non-event shape |
| `:invalid_attrs` | Sub-event `new/1` got a map missing required keys |
| `:not_found` | Resource lookup returns nothing |
| `:not_supported` | Operation valid in shape but disallowed (e.g. `Assets.to_secured/1` on a THOR-chain asset) |
| `:unknown_protocol` | `Deployments` saw an on-chain contract with no protocol mapping |
| `:no_price` | `Prices.get/1` could not resolve an oracle or FIN mid-price |

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
