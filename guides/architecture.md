# Architecture

## Overview

Rujira Core is a domain library for querying and parsing blockchain protocol data. It provides:

- **Protocol modules** — query APIs for each DeFi protocol (FIN, Bow, etc.)
- **Event parsing** — transforms raw chain events into typed structs
- **Asset resolution** — maps chain denominations to canonical asset types
- **Contract queries** — CosmWasm smart contract interaction via gRPC

## Protocol Module Structure

Each protocol follows the same shape. Resource modules are **self-contained**: struct + construction + queries. The protocol module is a **pure `defdelegate` facade** with zero logic.

### Module responsibilities

| Module | Owns |
|--------|------|
| `Protocol.Resource` | Struct, `new`, `get`, `list`, `load`, all queries (including cross-resource), `use Memoize` |
| `Protocol` | Public API: **only `defdelegate`** — no function bodies, no logic |
| `Protocol.Events` | Event parsing pipeline |

A function belongs on the module that owns the **return type**. `list_all_orders/1` returns `[Order.t()]` → lives on `Order`, even if it calls `Pair.list()` internally.

### Resource module template

```elixir
defmodule Rujira.Protocol.Resource do
  @moduledoc "Resource for Protocol. Use `Rujira.Protocol` as the public API."

  use Memoize

  # --- Struct ---
  defstruct [...]
  @type t :: %__MODULE__{...}

  # --- Construction ---
  @spec new(map() | Target.t()) :: {:ok, t()} | {:error, term()}
  def new(...), do: ...

  # --- Queries ---
  @spec get(String.t()) :: {:ok, t()} | {:error, term()}
  def get(address), do: Contracts.get({__MODULE__, address})

  @spec list() :: {:ok, [t()]} | {:error, term()}
  defmemo list, do: ...

  # --- Private queries ---
  defmemo query(...), do: Contracts.query_state_smart(...)
end
```

### Facade module template

```elixir
defmodule Rujira.Protocol do
  @moduledoc "Public API for Protocol. Pure delegation — no function bodies."

  defdelegate get_resource(address), to: Resource, as: :get
  defdelegate list_resources(), to: Resource, as: :list
  defdelegate list_all_resources(address), to: Resource, as: :list_all
end
```

### Cache invalidation

Cache lives on the resource module that defines `defmemo`. Invalidate the module that owns the data — never the facade.

```elixir
Memoize.invalidate(Rujira.Fin.Pair, :list, [])
Memoize.invalidate(Rujira.Fin.Pair, :find_by_denoms, ["rune", "tcy"])
Memoize.invalidate(Rujira.Fin.Book, :query, ["thor1pair", 100])
Memoize.invalidate(Rujira.Fin.Order, :query_list, ["thor1pair", "thor1user", 30])
```

The facade uses `defdelegate` — it does not cache.

### File structure per protocol

```
lib/rujira/protocol/
├── resource.ex          # Struct + construction + queries
├── events.ex            # Event parser
└── events/
    ├── event.ex         # Envelope
    └── action.ex        # Sub-event: new(map()) → {:ok, t()}

lib/rujira/protocol.ex   # Public API: defdelegate only
```

## Data Construction

Struct modules are **pure data constructors**. Always pass maps or structs for pattern matching — never positional fields.

| Constructor | Input | Returns | Use |
|-------------|-------|---------|-----|
| `new/1` | `map()` (string keys) | `{:ok, t()} \| {:error, term()}` | Top-level struct from chain config |
| `new/1` | `Target.t()` | `{:ok, t()} \| {:error, term()}` | Normalize deployment target → delegate to map clause |
| `new/2` | `(parent_struct, map())` | `{:ok, t()} \| {:error, term()}` | Child struct from parent context + chain query |
| `new/N` | explicit typed args | bare struct | Infallible placeholder |

### Rules

- `new/1` for top-level structs: receives `map()` or `%Target{}`
- `new/2` for child structs: receives parent struct + raw query map
- Required fields: pattern match in function head
- Optional fields: `Map.get/2`
- Use `Amount.new/1` for amounts, `Math.to_decimal/1` for prices, `Math.to_integer/1` for ints

### Contracts dispatch

```elixir
# Live contract — config from chain
config |> Map.put("address", address) |> module.new()

# Missing contract — fallback to deployment target
module.new(target)
```

## Event Pipeline

Data flows in one direction — each layer transforms forward, never backward.

```
raw input → Events.cast/1 → Events.parse/1 → route/1 → Protocol.parse/1 → {:ok, envelope}
```

| Layer | Input | Output | Responsibility |
|-------|-------|--------|----------------|
| `Events.cast/1` | `BlockEvent` proto | `%{type, attributes}` | Normalize raw input |
| `Events.parse/1` | `%{type, attributes}` | `{:ok, envelope}` | Create `%Event{}`, route to protocol |
| `Events.route/1` (private) | `%Event{}` | `{:ok, envelope}` | Dispatch by type prefix |
| `Protocol.Events.parse/1` | `%Event{}` | `{:ok, %ProtocolEvent{}}` | Extract fields, match action, delegate to sub-event, wrap |
| `SubEvent.new/1` | `map()` (attrs) | `{:ok, struct()}` | **Pure data constructor** — decoupled from pipeline |

### Consumer API

```elixir
case Rujira.Events.parse(raw) do
  {:ok, %Rujira.Fin.Events.Event{} = e} -> handle_fin(e)
  {:ok, %Rujira.Fin.Events.Event{data: %Trade{side: :base}}} -> ...
  {:ok, %Rujira.Thorchain.Events.Event{} = e} -> handle_tc(e)
  {:ok, %Rujira.Events.Event{}} -> handle_unknown(e)
end
```

## Adding a New Protocol

Follow this exact structure. Example: adding `Bow` protocol.

### 1. Create the envelope struct

`lib/rujira/bow/events/event.ex`:

```elixir
defmodule Rujira.Bow.Events.Event do
  defstruct [:address, :data]

  @type t :: %__MODULE__{address: String.t() | nil, data: struct()}

  @spec new(String.t() | nil, struct()) :: t()
  def new(address, data), do: %__MODULE__{address: address, data: data}
end
```

- Wasm protocols include `address` (from `_contract_address` in attrs)
- Native chain protocols use `defstruct [:data]` only

### 2. Create sub-event structs

`lib/rujira/bow/events/swap.ex`:

```elixir
defmodule Rujira.Bow.Events.Swap do
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
- `new/1` receives a **plain `map()`** — never `%Event{}`
- Returns `{:ok, struct()} | {:error, term()}`
- Use `Map.get/2` for optional, pattern match required in function head
- No alias to `Rujira.Events.Event` — sub-events are decoupled

### 3. Create the protocol parser

`lib/rujira/bow/events.ex`:

```elixir
defmodule Rujira.Bow.Events do
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

### 4. Register the route

In `lib/rujira/events.ex`, add above the catch-all:

```elixir
defp route(%Event{type: "wasm-rujira-bow/" <> _} = event),
  do: Rujira.Bow.Events.parse(event)
```

### 5. Create the resource module

`lib/rujira/bow/pool.ex` — struct + `new/1` + `get/list/load` queries (see Resource module template above).

### 6. Create the facade

`lib/rujira/bow.ex` — pure `defdelegate` to Pool (see Facade module template above).

### 7. Add tests

- `test/rujira/bow/events_test.exs` — test each sub-event via `Protocol.Events.parse/1`
- `test/rujira/events_test.exs` — add routing tests
- Assert envelope shape: `{:ok, %BowEvent{address: "...", data: %Swap{...}}}`
