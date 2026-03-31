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
All public functions must return `{:ok, term()}` or `{:error, term()}`. Never return bare values, `nil`, or `:error` without a reason.

```elixir
# good
def get(id), do: {:ok, value}
def get(_), do: {:error, :not_found}

# bad
def get(id), do: value
def get(_), do: nil
```

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

```elixir
# good
def parse(%{type: "swap"} = event), do: ...
def parse(%{type: "transfer"} = event), do: ...
def parse(_), do: {:error, :unknown_event}

# bad
def parse(event) do
  case event.type do
    "swap" -> ...
    "transfer" -> ...
  end
end
```

### Numeric Parsing

One function per type. `nil` in → `{:ok, nil}` out. Use `with` chains.

| Domain | Function | nil → | valid → | invalid → |
|--------|----------|-------|---------|-----------|
| Financial amount | `Amount.new/1` | `{:ok, nil}` | `{:ok, integer}` | `{:error, :invalid_amount}` |
| Decimal/price | `Math.to_decimal/1` | `{:ok, nil}` | `{:ok, Decimal.t}` | `{:error, :invalid_decimal}` |
| Plain integer | `Math.to_integer/1` | `{:ok, nil}` | `{:ok, integer}` | `{:error, :invalid_integer}` |

```elixir
# good — with chain, no private helpers
def new(%{"amount" => amount, "rate" => rate} = a) do
  with {:ok, amount} <- Amount.new(amount),
       {:ok, rate} <- Math.to_decimal(rate) do
    {:ok, %__MODULE__{amount: amount, rate: rate}}
  end
end

# bad — private parse helpers per file
defp parse_amount(nil), do: nil
defp parse_amount(v), do: elem(Amount.new(v), 1)
```

### Amounts
All amounts are integers normalized to 8 decimal places (`1.0 = 100_000_000`). Use `Rujira.Amount.t()` in typespecs and `Amount.new/1` for construction.

## Project

- `mix compile --warnings-as-errors` must pass
- `mix test` must pass
- `mix credo` must pass with no issues
