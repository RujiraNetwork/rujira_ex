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

## Events

### Pipeline

Data flows in one direction — each layer transforms forward, never backward.

```
raw input → Events.cast/1 → Events.parse/1 → route/1 → Protocol.parse/1 → {:ok, envelope}
```

| Layer | Input | Output | Responsibility |
|-------|-------|--------|----------------|
| `Rujira.Events.cast/1` | `BlockEvent` proto | `%{type, attributes}` | Normalize raw input |
| `Rujira.Events.parse/1` | `%{type, attributes}` | `{:ok, envelope}` | Create `%Event{}`, route to protocol |
| `Rujira.Events.route/1` (private) | `%Event{}` | `{:ok, envelope}` | Dispatch to protocol parser by type prefix |
| `Protocol.Events.parse/1` | `%Event{}` | `{:ok, %ProtocolEvent{}}` | Extract common fields, match action, delegate to sub-event, wrap in envelope |
| `SubEvent.new/1` | `map()` (attrs) | `{:ok, struct()}` | **Pure data constructor** — no knowledge of `Event`, envelopes, or routing |

### Consumer API

Consumers match at three levels:

```elixir
case Rujira.Events.parse(raw) do
  # Protocol level — all FIN events
  {:ok, %Rujira.Fin.Events.Event{} = e} -> handle_fin(e)

  # Protocol + specific event
  {:ok, %Rujira.Fin.Events.Event{data: %Trade{side: :base}}} -> ...

  # Protocol level — all Thorchain events
  {:ok, %Rujira.Thorchain.Events.Event{} = e} -> handle_tc(e)

  # Unrecognized protocol
  {:ok, %Rujira.Events.Event{}} -> handle_unknown(e)
end
```

### Adding a new protocol

Follow this exact structure. Example: adding `Bow` protocol.

#### 1. Create the envelope struct

`lib/rujira/bow/events/event.ex`:

```elixir
defmodule Rujira.Bow.Events.Event do
  @moduledoc "Protocol-level envelope for Bow events."

  defstruct [:address, :data]

  @type t :: %__MODULE__{address: String.t() | nil, data: struct()}

  @spec new(String.t() | nil, struct()) :: t()
  def new(address, data), do: %__MODULE__{address: address, data: data}
end
```

- Wasm protocols include `address` (extracted from `_contract_address` in attrs)
- Native chain protocols (like Thorchain) use `defstruct [:data]` only

#### 2. Create sub-event structs

`lib/rujira/bow/events/swap.ex`:

```elixir
defmodule Rujira.Bow.Events.Swap do
  @moduledoc "A Bow swap event."

  defstruct [:pool, :offer, :return]

  @type t :: %__MODULE__{pool: String.t(), offer: Amount.t() | nil, return: Amount.t() | nil}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"pool" => pool} = attrs) do
    with {:ok, offer} <- Amount.new(Map.get(attrs, "offer")),
         {:ok, return_amt} <- Amount.new(Map.get(attrs, "return")) do
      {:ok, %__MODULE__{pool: pool, offer: offer, return: return_amt}}
    end
  end
end
```

Rules:
- `new/1` receives a **plain `map()`** of attributes — never `%Event{}`
- Returns `{:ok, struct()} | {:error, term()}`
- Use `Map.get/2` for optional fields, pattern match required fields in the function head
- Use `Amount.new/1` for amounts, `Math.to_decimal/1` for prices, `Math.to_integer/1` for plain integers
- No alias to `Rujira.Events.Event` — sub-events are decoupled from the pipeline

#### 3. Create the protocol parser

`lib/rujira/bow/events.ex`:

```elixir
defmodule Rujira.Bow.Events do
  @moduledoc "Parser for Bow protocol wasm events."

  alias Rujira.Events.Event
  alias Rujira.Bow.Events.Event, as: BowEvent
  alias Rujira.Bow.Events.Swap

  @spec parse(Event.t()) :: {:ok, BowEvent.t()} | {:error, term()}

  def parse(%Event{
        type: "wasm-rujira-bow/" <> action,
        attributes: %{"_contract_address" => address} = attrs
      } = event) do
    case new(action, attrs) do
      {:ok, data} -> {:ok, BowEvent.new(address, data)}
      {:error, _} = err -> err
      :pass -> {:ok, BowEvent.new(address, event)}
    end
  end

  def parse(%Event{} = event), do: {:ok, BowEvent.new(nil, event)}

  defp new("swap", attrs), do: Swap.new(attrs)
  defp new(_, _), do: :pass
end
```

Rules:
- Single public `parse/1` receives `%Event{}`, returns `{:ok, %ProtocolEvent{}}`
- Extract `address` from `_contract_address` in the function head (wasm protocols)
- Strip the type prefix and pass `action` + `attrs` to private `new/2`
- `new/2` pattern matches the action string, delegates `attrs` to the sub-event
- Unknown actions return `:pass` — the parser wraps the raw `%Event{}` in the envelope
- The catch-all `parse(%Event{})` handles events routed here by mistake (wraps with `nil` address)

#### 4. Register the route

In `lib/rujira/events.ex`, add a `route/1` clause:

```elixir
defp route(%Event{type: "wasm-rujira-bow/" <> _} = event),
  do: Rujira.Bow.Events.parse(event)
```

Place it **above** the catch-all `defp route(%Event{} = event), do: {:ok, event}`.

#### 5. Add tests

- `test/rujira/bow/events_test.exs` — test each sub-event via `Protocol.Events.parse/1`
- Add routing tests in `test/rujira/events_test.exs`
- Assert envelope shape: `{:ok, %BowEvent{address: "...", data: %Swap{...}}}`

### File structure

```
lib/rujira/
├── events.ex                    # Main router
├── events/
│   └── event.ex                 # Default %Event{type, attributes}
├── fin/
│   ├── events.ex                # FIN protocol parser
│   └── events/
│       ├── event.ex             # FIN envelope %Event{address, data}
│       ├── trade.ex             # Sub-event: new(map()) → {:ok, struct()}
│       ├── submit.ex
│       └── ...
└── thorchain/
    ├── events.ex                # Thorchain protocol parser
    └── events/
        ├── event.ex             # Thorchain envelope %Event{data}
        ├── swap.ex
        └── ...
```

## Project

- `mix compile --warnings-as-errors` must pass
- `mix test` must pass
- `mix credo` must pass with no issues
