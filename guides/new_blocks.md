# New blocks

A consumer that follows the chain - an indexer, a bot, anything that calls
`Rujira.Node.advance/1` on every height - has to learn that a new block
exists. Polling the node for it costs half a poll interval on average, on
top of the block time. `Rujira.Node.subscribe/2` removes that wait: the
node's CometBFT websocket pushes every new block header, and the library
turns each one into a message to the subscribed processes.

```
CometBFT  ──NewBlockHeader──▶  Rujira.Node.Subscription  ──{:rujira_new_block, h}──▶  consumer
   ▲                                                                                     │
   └───────────────────────────── gRPC: block at height h ◀──────────────────────────────┘
```

The message carries the height and nothing else. The consumer fetches the
block the way it always has, through `Rujira.Node.query/3`, so there is one
source of truth for block data, and a dropped websocket costs latency, not
data.

## Configuring it

The subscription is optional and needs the optional dependency
`:mint_web_socket` (it brings `:mint`, which the gRPC client may already
use):

```elixir
# mix.exs
{:rujira_ex, "~> 0.7"},
{:mint_web_socket, "~> 1.0"}

# config/runtime.exs
config :rujira_ex,
  node: MyApp.Node,
  websocket: "ws://thornode:27147/websocket"
```

The endpoint is the node's CometBFT RPC listener - `[rpc] laddr` in its
`config.toml`, 27147 on a THORChain mainnet node and 26657 on a stock
CometBFT one - with the path `/websocket`. `wss://` works as well. A keyword
list sets the connection's knobs too:

```elixir
config :rujira_ex,
  websocket: [
    url: "ws://thornode:27147/websocket",
    ping_interval: 15_000,
    connect_timeout: 10_000,
    backoff_base: 500,
    backoff_max: 30_000
  ]
```

Without `:websocket`, nothing starts and `subscribe/2` returns
`{:error, :not_configured}`. With `:websocket` set but `:mint_web_socket`
missing, or set to a URL that is not `ws://` or `wss://`, the application
fails to start: a configuration that asked for a push and silently got
polling would be a silent default.

## Using it

Subscribe from the process that wants the message, and keep a poll as the
fallback:

```elixir
defmodule MyApp.Follower do
  use GenServer

  @poll 5_000

  def init(_) do
    # :ok, or {:error, :not_configured} - either way, poll as well, only slower
    _ = Rujira.Node.subscribe(:new_block)
    {:ok, schedule_poll(%{head: nil})}
  end

  def handle_info({:rujira_new_block, height}, state),
    do: {:noreply, catch_up(state, height)}

  def handle_info(:poll, state),
    do: {:noreply, state |> catch_up(latest_height()) |> schedule_poll()}

  defp schedule_poll(state) do
    Process.send_after(self(), :poll, @poll)
    state
  end

  # catch_up/2 fetches and handles every block above state.head up to height;
  # latest_height/0 asks the node for its tip over gRPC.
end
```

What the messages promise, and what they do not:

- **Ascending, at most once.** Heights arrive in ascending order, each at
  most once per connection. A height at or below the last one sent is
  dropped, which covers a reconnect replaying the current header.
- **Not every height.** A message can be missed - the socket was down, the
  node dropped a slow subscriber, a header came while reconnecting. A height
  that skips ahead means "everything up to here is committed", so fetch the
  range, as `Rujira.Node.advance/1` already does for a gap.
- **A hint about the node it came from.** The height is what *that* node has
  committed. Point the websocket at the same node the gRPC client reads, or
  the block may not be there yet.

The calling process is subscribed until it exits or calls
`Rujira.Node.unsubscribe/2`. Subscribers live in a `Registry` beside the
connection, so a connection that drops or crashes keeps them; neither call
ever blocks on the connection or raises.

## The connection

One process holds the socket, under `Rujira.Node.Subscription`'s supervisor.
It sends one JSON-RPC request per connection:

```json
{"jsonrpc":"2.0","method":"subscribe","id":1,"params":{"query":"tm.event='NewBlockHeader'"}}
```

and reads the acknowledgement (`{"jsonrpc":"2.0","id":1,"result":{}}`) and then
one event per block, of which it reads `result.data.value.header.height`.
`Rujira.Node.Subscription.Message` has the shapes, captured from a mainnet
node.

Every failure is handled the same way: the socket is closed and a new one
opened after a backoff (exponential from `backoff_base` to `backoff_max`,
with jitter - see `Rujira.Node.Subscription.Backoff`), which subscribes again.
That covers a refused connection or upgrade, a refused or cancelled
subscription (a JSON-RPC error), a close frame, a ping still unanswered at
the next one, and no acknowledgement within `connect_timeout`. A frame that
cannot be read is skipped and reported; the connection stays up. Pings from
the node are answered.

## Telemetry

| Event | Measurements | Metadata |
|---|---|---|
| `[:rujira, :node, :subscription, :connect]` | `duration`, `attempt` | `url` |
| `[:rujira, :node, :subscription, :disconnect]` | `attempt`, `delay` (ms) | `url`, `reason` |
| `[:rujira, :node, :subscription, :new_block]` | `height`, `subscribers` | `url` |
| `[:rujira, :node, :subscription, :invalid_frame]` | `count` | `url`, `reason` |

`connect` is a subscription the node acknowledged, `duration` measured from
opening the socket. `disconnect` is a lost connection or a failed attempt;
`attempt` is the reconnect it schedules, `delay` how long until it.
`Rujira.Node.Subscription.Telemetry.events/0` lists them all.

## A second node, or your own supervisor

Leave `:websocket` unset and start the child spec yourself, with a `:name`:

```elixir
children = [
  {Rujira.Node.Subscription, url: "ws://thornode:27147/websocket", name: MyApp.Blocks}
]

:ok = Rujira.Node.subscribe(:new_block, name: MyApp.Blocks)
```
