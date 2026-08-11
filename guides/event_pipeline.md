# Rujira Event Pipeline

How a raw chain event flows from the wire into a typed Elixir struct that
consumers can pattern-match on. Worked example: the FIN trade event emitted by
the Fin smart contract.

[`architecture.md`](architecture.md) summarises this pipeline in a table and
is the normative reference for module shape; this guide is the walkthrough of
one event end to end.

## The event on the wire

When the Fin smart contract executes a trade, it emits a CosmWasm `wasm`-class
event. On Thorchain it surfaces inside a `BlockEvent` protobuf with this shape:

```
type:       "wasm-rujira-fin/trade"
attributes: %{
  "_contract_address" => "thor1...",   # the Fin pair contract address
  "side"              => "base",       # or "quote"
  "price"             => "1.2345",
  "rate"              => "0.99",       # optional
  "offer"             => "1000x/uusd", # Amount-encoded
  "bid"               => "810rune",    # Amount-encoded
  "ranges"            => "..."         # optional
}
```

Two things to note:

- The `type` field is a single string with a slash-delimited convention:
  `wasm-<protocol>/<action>`. For Fin that is `wasm-rujira-fin/<action>` and
  `trade` is one of several actions (`submit`, `retract`, `range.create`, …).
- All attribute values are strings. Decimal parsing, `Amount` parsing, and
  atomization happen in Elixir, not on the chain.

The goal of the pipeline is to turn this stringly-typed map into:

```elixir
%Rujira.Fin.Events.Event{
  address: "thor1...",
  data: %Rujira.Fin.Events.Trade{
    side: :base,
    price: "1.2345",
    rate: #Decimal<0.99>,
    offer: %Rujira.Amount{...},
    bid:   %Rujira.Amount{...},
    ranges: nil
  }
}
```

## The pipeline

```
raw BlockEvent
   │
   ▼
Rujira.Events.cast/1     normalize to %{type, attributes}
   │
   ▼
Rujira.Events.parse/1    wrap as %Rujira.Events.Event{}
   │
   ▼
Rujira.Events.route/1    dispatch by type prefix
   │
   ▼
Rujira.Fin.Events.parse/1   strip prefix, look up action,
   │                        pull _contract_address
   ▼
Rujira.Fin.Events.Trade.new/1   pure data constructor
   │
   ▼
Rujira.Fin.Events.Event.new/2   wrap in protocol envelope
   │
   ▼
{:ok, %Rujira.Fin.Events.Event{address, data: %Trade{}}}
```

Each layer transforms forward; nothing in the chain reaches backwards.

### 1. Normalize — `Rujira.Events.cast/1`

`Rujira.Events.cast/1` — `lib/rujira/events.ex`

Takes a `BlockEvent` protobuf (generated into Thorchain.Types) and flattens its
`event_kv_pair` list into the standard `%{type: String.t(), attributes: map()}`
shape used by the rest of the pipeline. The first pair is always `{"type",
value}`; the remaining pairs are folded into the attributes map.

Callers that already have a cast map can skip this step and call `parse/1`
directly.

### 2. Wrap and route — `Rujira.Events.parse/1` and `route/1`

`Rujira.Events.parse/1` — `lib/rujira/events.ex`

`parse/1` constructs a generic `%Rujira.Events.Event{type, attributes}` and
hands it to the private `route/1`. `route/1` is a small pattern-match table
that decides which protocol parser owns the event:

```elixir
defp route(%Event{type: "wasm-rujira-fin/" <> _} = event),
  do: Rujira.Fin.Events.parse(event)

defp route(%Event{type: type} = event)
     when type in ~w(swap transfer add_liquidity ...),
     do: Rujira.Thorchain.Events.parse(event)

defp route(%Event{} = event), do: {:ok, event}   # catch-all
```

The catch-all is important: unrecognized events are returned wrapped in the
default `%Rujira.Events.Event{}` so consumers never silently lose data. Only
the *protocol* is routed here — actions inside a protocol are matched one
layer deeper.

### 3. Protocol parser — `Rujira.Fin.Events.parse/1`

`Rujira.Fin.Events.parse/1` — `lib/rujira/fin/events.ex`

This is the layer that turns a `wasm-rujira-fin/trade` event into a typed
`%Trade{}`. It does three things:

```elixir
def parse(
      %Event{
        type: "wasm-rujira-fin/" <> action,
        attributes: %{"_contract_address" => address} = attrs
      } = event
    ) do
  case new(action, attrs) do
    {:ok, data} -> {:ok, FinEvent.new(address, data)}
    {:error, _} = err -> err
    :pass -> {:ok, FinEvent.new(address, event)}
  end
end
```

1. **Strip the prefix.** `"wasm-rujira-fin/" <> action` destructures the type
   string so `"wasm-rujira-fin/trade"` yields `action = "trade"`. This is the
   only place the wasm event type string appears in code — the `Trade` module
   itself does not know its own wasm name.
2. **Pull the contract address.** `_contract_address` is required for every
   wasm event. Pattern-matching it in the function head means events missing
   the address fall through to the lenient clause below and end up in the
   default envelope.
3. **Dispatch by action.** A private `new/2` is a lookup table from action
   string to sub-event constructor:

   ```elixir
   defp new("trade", attrs), do: Trade.new(attrs)
   defp new("submit", attrs), do: Submit.new(attrs)
   defp new("retract", attrs), do: Retract.new(attrs)
   defp new("range.create", attrs), do: RangeCreate.new(attrs)
   # ...
   defp new(_, _), do: :pass
   ```

The three return values of the lookup table map to three behaviours:

| Result        | Meaning                                              | Envelope `data`            |
|---------------|------------------------------------------------------|----------------------------|
| `{:ok, data}` | Sub-event recognised and parsed.                     | Typed sub-event struct.    |
| `{:error, _}` | Sub-event recognised but attrs are malformed.        | Propagated to the caller.  |
| `:pass`       | Action unknown (e.g. new on-chain action, not yet implemented). | Raw `%Event{}` preserved. |

The second `parse/1` clause (`def parse(%Event{} = event)`) catches anything
that lacks `_contract_address` or doesn't match the prefix shape and wraps it
with `address: nil`, so even malformed FIN events still emerge as a
`%Fin.Events.Event{}`.

### 4. Sub-event constructor — `Rujira.Fin.Events.Trade.new/1`

`Rujira.Fin.Events.Trade.new/1` — `lib/rujira/fin/events/trade.ex`

The sub-event module is a **pure data constructor**: it takes a plain
`map()` of attrs and returns `{:ok, %Trade{}}` or `{:error, term()}`. It has
no knowledge of the wasm event type string, of `_contract_address`, of the
envelope, or of the routing layer. That decoupling is what makes the
sub-events easy to test in isolation.

```elixir
def new(%{"side" => side, "price" => price} = attrs) do
  with {:ok, rate}  <- Math.to_decimal(Map.get(attrs, "rate")),
       {:ok, offer} <- Amount.new(Map.get(attrs, "offer")),
       {:ok, bid}   <- Amount.new(Map.get(attrs, "bid")) do
    {:ok,
     %__MODULE__{
       side: side |> String.downcase() |> String.to_existing_atom(),
       price: price,
       rate: rate,
       offer: offer,
       bid: bid,
       ranges: Map.get(attrs, "ranges")
     }}
  end
end

def new(_), do: {:error, :invalid_attrs}
```

Notable details:

- **Required fields go in the head.** `side` and `price` are matched in the
  function head; if they're missing the second clause runs and returns
  `{:error, :invalid_attrs}`.
- **Optional fields use `Map.get/2`.** `rate`, `offer`, `bid`, `ranges` are
  optional and are passed through the appropriate parsers, which all accept
  `nil` and return `{:ok, nil}` if absent.
- **Strings are converted at the edge.** `Math.to_decimal/1` for `rate`,
  `Amount.new/1` for `offer`/`bid`. The string `side` is downcased and
  converted with `String.to_existing_atom/1` so unknown sides crash loudly
  rather than minting new atoms.
- **`with` short-circuits.** Any `{:error, _}` from the field parsers bubbles
  out unchanged, where the protocol parser propagates it to the caller.

### 5. The envelope — `Rujira.Fin.Events.Event`

`lib/rujira/fin/events/event.ex`

A thin two-field struct:

```elixir
defstruct address: nil, data: nil
```

Its job is to give consumers a single struct type they can match on when they
want *every FIN event regardless of action*:

```elixir
{:ok, %Rujira.Fin.Events.Event{} = e} -> handle_any_fin(e)
```

…while still allowing specific matches via the `data` field:

```elixir
{:ok, %Rujira.Fin.Events.Event{data: %Rujira.Fin.Events.Trade{side: :base}}} ->
  handle_base_trade(e)
```

The `address` field carries the `_contract_address` extracted in step 3, so
consumers don't have to dig into the inner struct to find which pair emitted
the event.

## What this gives consumers

The intended consumer pattern (documented at the top of `Rujira.Events`):

```elixir
case Rujira.Events.parse(raw_event) do
  # All FIN events
  {:ok, %Rujira.Fin.Events.Event{} = e} ->
    handle_fin(e)

  # Specific FIN action
  {:ok, %Rujira.Fin.Events.Event{data: %Rujira.Fin.Events.Trade{} = trade}} ->
    handle_trade(trade)

  # All Thorchain events
  {:ok, %Rujira.Thorchain.Events.Event{} = e} ->
    handle_tc(e)

  # Unknown / not-yet-implemented
  {:ok, %Rujira.Events.Event{} = event} ->
    handle_unknown(event)
end
```

Three levels of granularity (protocol, action, field) without ever having to
parse strings or pull values out of attribute maps in the consumer.

## Where the wiring actually lives

For `wasm-rujira-fin/trade` specifically, the binding is split across exactly
three lines in two files:

| Concern                          | Location                                          |
|----------------------------------|---------------------------------------------------|
| Route `wasm-rujira-fin/*` to FIN | `route/1` (private) in `lib/rujira/events.ex`     |
| Strip `wasm-rujira-fin/` prefix  | `Rujira.Fin.Events.parse/1`                       |
| Map `"trade"` → `Trade.new/1`    | `new/2` (private) in `lib/rujira/fin/events.ex`   |
| Build the `%Trade{}` struct      | `Rujira.Fin.Events.Trade.new/1`                   |

Notice what is *not* on that list: the `Trade` module never references the
string `"wasm-rujira-fin/trade"`. It has no idea what wasm event it
corresponds to. That coupling lives entirely in the dispatch table in
`Rujira.Fin.Events`, which is what lets sub-event modules be tested as pure
functions and lets the routing layer evolve independently of the data shapes.

## Adding a new FIN action

When the Fin contract starts emitting a new wasm event, say
`wasm-rujira-fin/cancel_all`, the change set is mechanical:

1. Create `lib/rujira/fin/events/cancel_all.ex` with a `new/1` pure
   constructor following the rules in step 4 above.
2. Add one line to the dispatch table in `lib/rujira/fin/events.ex`:
   ```elixir
   defp new("cancel_all", attrs), do: CancelAll.new(attrs)
   ```
3. Alias the new module at the top of the same file.
4. Add a test under `test/rujira/fin/events_test.exs` asserting the envelope
   shape.

No changes are needed in `Rujira.Events` — routing is already wired for the
whole `wasm-rujira-fin/*` prefix.

## Adding a new protocol

See [`architecture.md`](architecture.md), section *Adding a New Protocol*.
The high-level steps are the same as adding an action, plus:

- An envelope struct (`lib/rujira/<protocol>/events/event.ex`).
- A protocol parser (`lib/rujira/<protocol>/events.ex`) with the same
  prefix-strip + dispatch-table shape as `Rujira.Fin.Events`.
- One new `route/1` clause in `lib/rujira/events.ex` above the catch-all.

The commented-out clauses in `lib/rujira/events.ex` show the prefixes that
are reserved for protocols not yet implemented (`wasm-rujira-bow/`,
`wasm-rujira-ghost-vault/`, `wasm-rujira-staking/`, etc.).
