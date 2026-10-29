defmodule Rujira.Node.Subscription do
  @moduledoc """
  A push-based wake-up for new blocks: a CometBFT websocket subscription to
  `tm.event='NewBlockHeader'` that sends every subscriber

      {:rujira_new_block, height}

  as soon as the node has committed `height`.

  It is a hint, not a feed. The message carries only the height; the block
  itself is still fetched the usual way (`Rujira.Thorchain.block/2`, or the
  block query through `Rujira.Node.query/3`), so gRPC stays the one source of truth. A missed message costs latency, never
  data: keep a slow poll as the fallback, and treat a height that skips ahead
  as "fetch everything up to here".

  ## Configuration

  Optional, beside the node, and it needs the optional dependency
  `:mint_web_socket`:

      # mix.exs
      {:mint_web_socket, "~> 1.0"}

      # config/runtime.exs
      config :rujira_ex,
        node: MyApp.Node,
        websocket: "ws://thornode:27147/websocket"

  The endpoint is the node's CometBFT RPC listener (`[rpc] laddr` in
  `config.toml`; 27147 on a THORChain mainnet node, 26657 on a stock CometBFT
  one) with the path `/websocket`. `wss://` works as well.

  With `:websocket` set, `Rujira.Application` starts this supervisor under
  the name `Rujira.Node.Subscription`. Without it nothing is started and
  `subscribe/2` returns `{:error, :not_configured}`: the consumer keeps
  polling. Setting `:websocket` without `:mint_web_socket` in the dependency
  tree, or to a URL that is not `ws://` or `wss://`, fails the application's
  start rather than leaving the consumer polling without knowing it.

  `:websocket` is either the URL or a keyword list with `:url` and any of:

    * `:ping_interval` - milliseconds between websocket pings; a ping still
      unanswered at the next one drops the connection. Default `15_000`.
    * `:connect_timeout` - milliseconds from opening the socket to the node
      acknowledging the subscription. Default `10_000`.
    * `:backoff_base` and `:backoff_max` - the reconnect delay, see
      `Rujira.Node.Subscription.Backoff`. Defaults `500` and `30_000`.

  To run it under your own supervisor instead (or a second one, for another
  node), leave `:websocket` unset and add the child spec with a `:name`:

      children = [
        {Rujira.Node.Subscription, url: "ws://thornode:27147/websocket", name: MyApp.Blocks}
      ]

      Rujira.Node.Subscription.subscribe(:new_block, name: MyApp.Blocks)

  ## Subscribing

      :ok = Rujira.Node.subscribe(:new_block)

      def handle_info({:rujira_new_block, height}, state), do: ...

  The **calling process** is subscribed, until it exits or calls
  `unsubscribe/2`. Subscribing twice is the same as subscribing once.
  Subscribers live in a `Registry` beside the connection, so a connection
  that drops, or crashes and is restarted, keeps them.

  Heights are sent in ascending order, each at most once per connection: an
  event at or below the last height sent is dropped (a reconnect can replay
  the current header). Neither call ever sends a message to the node, and
  neither ever raises or blocks on the connection.

  ## Connection

  The connection is one process that never takes a subscriber down with it.
  A refused subscription, a closed socket, a missed pong or a connection
  that takes longer than `:connect_timeout` all lead to the same thing: the
  socket is closed, and a new one is opened after a backoff delay, which
  subscribes again. A frame it cannot read is reported and skipped; the
  connection stays up. Pings from the node are answered.

  ## Telemetry

    * `[:rujira, :node, :subscription, :connect]` - the node acknowledged a
      subscription. Measurements `%{duration: native_time, attempt:
      failed_attempts_before}`, metadata `%{url: url}`.
    * `[:rujira, :node, :subscription, :disconnect]` - a connection was lost
      or an attempt failed. Measurements `%{attempt: n, delay: ms}` (the
      reconnect it schedules), metadata `%{url: url, reason: reason}`.
    * `[:rujira, :node, :subscription, :new_block]` - a height was sent.
      Measurements `%{height: height, subscribers: count}`, metadata
      `%{url: url}`.
    * `[:rujira, :node, :subscription, :invalid_frame]` - a frame was
      skipped. Measurements `%{count: 1}`, metadata `%{url: url, reason:
      reason}`.

  `url` is the configured URL as given; keep credentials out of it, or out
  of your handlers.
  """

  use Supervisor

  alias Rujira.Node.Subscription.Connection
  alias Rujira.Node.Subscription.Endpoint

  @default_name __MODULE__

  @typedoc "What can be subscribed to."
  @type event :: :new_block

  @typedoc "The message a subscriber receives."
  @type message :: {:rujira_new_block, pos_integer()}

  @typedoc "`:name` - the subscription to address, `Rujira.Node.Subscription` by default."
  @type opts :: [name: atom()]

  # --- Construction ---

  @doc """
  Starts the subscription: a `Registry` of subscribers and the connection.

  Takes `:url`, an optional `:name` (default `Rujira.Node.Subscription`) and
  the connection options listed in the moduledoc. Returns `{:error,
  {:invalid_url, url}}` for a URL that is not `ws://` or `wss://`, and
  `{:error, :mint_web_socket_not_loaded}` without the optional dependency.
  """
  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts) do
    name = Keyword.get(opts, :name, @default_name)

    with :ok <- ensure_client(),
         {:ok, _uri} <- Endpoint.new(Keyword.get(opts, :url)) do
      Supervisor.start_link(__MODULE__, Keyword.put(opts, :name, name), name: name)
    end
  end

  @doc """
  The child spec `Rujira.Application` starts from `config :rujira_ex,
  websocket: ...`, or `nil` when it is not set.
  """
  @spec from_config() :: Supervisor.child_spec() | nil
  def from_config do
    case Application.get_env(:rujira_ex, :websocket) do
      nil -> nil
      url when is_binary(url) -> child_spec(url: url)
      opts when is_list(opts) -> child_spec(opts)
    end
  end

  # --- Queries ---

  @doc """
  Subscribes the calling process to `event`.

  `:ok`, or `{:error, :not_configured}` when no subscription runs under
  `opts[:name]`, or `{:error, :invalid_subscription}` for an event other
  than `:new_block`.
  """
  @spec subscribe(event(), opts()) :: :ok | {:error, :not_configured | :invalid_subscription}
  def subscribe(event, opts \\ [])

  def subscribe(:new_block, opts) do
    registry = opts |> name() |> registry()

    cond do
      Process.whereis(registry) == nil -> {:error, :not_configured}
      :new_block in Registry.keys(registry, self()) -> :ok
      true -> register(registry)
    end
  rescue
    ArgumentError -> {:error, :not_configured}
  end

  def subscribe(_event, _opts), do: {:error, :invalid_subscription}

  @doc """
  Unsubscribes the calling process from `event`. `:ok` even when it was not
  subscribed, or nothing runs under `opts[:name]`.
  """
  @spec unsubscribe(event(), opts()) :: :ok | {:error, :invalid_subscription}
  def unsubscribe(event, opts \\ [])

  def unsubscribe(:new_block, opts) do
    registry = opts |> name() |> registry()
    if Process.whereis(registry), do: Registry.unregister(registry, :new_block)
    :ok
  rescue
    ArgumentError -> :ok
  end

  def unsubscribe(_event, _opts), do: {:error, :invalid_subscription}

  @doc "The `Registry` holding the subscribers of the subscription named `name`."
  @spec registry(atom()) :: atom()
  def registry(name), do: Module.concat(name, Registry)

  # --- Supervisor ---

  @impl true
  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    registry = registry(name)

    children = [
      {Registry, keys: :duplicate, name: registry},
      {Connection, opts |> Keyword.delete(:name) |> Keyword.put(:registry, registry)}
    ]

    # The registry outlives every connection restart: subscribers survive.
    Supervisor.init(children, strategy: :rest_for_one)
  end

  # --- Private ---

  defp register(registry) do
    case Registry.register(registry, :new_block, nil) do
      {:ok, _owner} -> :ok
      {:error, _} -> :ok
    end
  end

  defp name(opts), do: Keyword.get(opts, :name, @default_name)

  defp ensure_client do
    if Code.ensure_loaded?(Mint.WebSocket),
      do: :ok,
      else: {:error, :mint_web_socket_not_loaded}
  end
end
