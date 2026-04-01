# Rujira Core — Conventions

## Elixir Style

### Aliases
Always use explicit, fully qualified aliases. Never use the `{}` grouping syntax.

```elixir
# good
alias Rujira.Fin.Events.Trade
alias Rujira.Fin.Events.Submit

# bad
alias Rujira.Fin.Events.{Trade, Submit}
```

### Return Values

**Fallible functions** (I/O, parsing, construction that can fail) must return `{:ok, term()} | {:error, term()}`.

**Infallible pure functions** (getters, math, formatting, predicates) return bare values.

Never return `nil` as a failure — use `{:error, :not_found}` or similar.

```elixir
# fallible — I/O or parsing
def from_denom(denom), do: {:ok, asset}
def from_denom(_), do: {:error, :unknown_denom}

# infallible pure — getter
def decimals(%Asset{chain: "ETH"}), do: 18
def label(%Asset{ticker: ticker}), do: ticker

# predicate
def eq_denom?(asset, denom), do: true
```

### Typespecs

Every public `def` must have `@spec`. Use defined types (`Asset.t()`, `Amount.t()`) not raw structs.

```elixir
# good
@spec from_denom(String.t()) :: {:ok, Asset.t()} | {:error, term()}

# bad — missing spec, raw struct
def from_denom(d), do: {:ok, %Asset{...}}
```

### Naming

| Pattern | Use | Returns |
|---------|-----|---------|
| `new/N` | Struct constructor | Bare struct (infallible) or `{:ok, struct()} \| {:error, _}` |
| `from_query/N` | Parse from chain/contract response | `{:ok, struct()} \| {:error, _}` |
| `from_X/N` | Parse/convert from X format | `{:ok, _} \| {:error, _}` |
| `to_X/N` | Convert to X format | `{:ok, _} \| {:error, _}` (fallible) or bare (infallible) |
| `bang!/N` | Raises on error, returns bare | Bare value |

### Map Access
Use `Map.get/2` instead of bracket syntax for string-keyed maps.

```elixir
# good
Map.get(attrs, "key")

# bad
attrs["key"]
```

### Pattern Matching
Always prefer pattern matching in function heads over `case`, `cond`, or `if` inside the body.

### Numeric Parsing

One function per type. `nil` in → `{:ok, nil}` out. Use `with` chains.

| Domain | Function | nil → | valid → | invalid → |
|--------|----------|-------|---------|-----------|
| Financial amount | `Amount.new/1` | `{:ok, nil}` | `{:ok, integer}` | `{:error, :invalid_amount}` |
| Decimal/price | `Math.to_decimal/1` | `{:ok, nil}` | `{:ok, Decimal.t}` | `{:error, :invalid_decimal}` |
| Plain integer | `Math.to_integer/1` | `{:ok, nil}` | `{:ok, integer}` | `{:error, :invalid_integer}` |

### Amounts
All amounts are integers normalized to 8 decimal places (`1.0 = 100_000_000`). Use `Rujira.Amount.t()` in typespecs and `Amount.new/1` for construction.

### Structure
- 1 module per file, 1 responsibility per module
- Structs with multiple sub-concerns get their own folder
- Event structs live in `events/` subfolder with `new/1` constructors

## Project

- `mix compile --warnings-as-errors` must pass
- `mix test` must pass
- `mix credo` must pass with no issues
