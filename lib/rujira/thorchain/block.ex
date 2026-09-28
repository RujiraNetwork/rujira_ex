defmodule Rujira.Thorchain.Block do
  @moduledoc """
  A THORChain block, with every event it emitted placed in execution order.

  Struct, construction, and queries. Use `Rujira.Thorchain` as the public API.

  ## Height

  Unlike every other query here, a block's height is the query itself, not an
  option: it travels in the request's `height` field, so a `:height` in `opts`
  is meaningless and is dropped before the node is called. Ask for a height by
  passing it as the first argument, or `:latest` for the current block.

  thornode answers a height it cannot parse with the latest block rather than
  with an error, so an integer request verifies the returned header against the
  height asked for and returns `{:error, {:height_mismatch, height, returned}}`
  rather than passing a different block off as the one requested.

  ## Event order

  A block's events reach us in four separate lists. Each event is tagged with
  the stage it came from and a `{tx_idx, event_idx}` position that replays the
  block in the order the node executed it:

  | Stage | `tx_idx` | Source |
  |-------|----------|--------|
  | `:pre_block` | `-2` | `finalize_block_events` |
  | `:begin` | `-1` | `begin_block_events` |
  | `:tx` | `0..n` | `txs[i].result.events` |
  | `:end` | `2_147_483_647` | `end_block_events` |

  `finalize_block_events` reads as the pre-block stage because thornode routes
  every event without a `mode` attribute - the events the Cosmos SDK emits in
  its PreBlock phase - into that list, and those run before the begin-block
  phase.

  The end-block sentinel cannot collide with a transaction index: CometBFT caps
  a block at 104_857_600 bytes, so a block cannot hold 2_147_483_647
  transactions.

  ## Caching

  A block at a height never changes, so unlike the live queries here an integer
  height *is* cached - it is the one read of the past that cannot go stale. It
  is held in `Rujira.Cache`'s exact store at the height it is: a block is large,
  so it is never carried over to another height and never kept as an identity
  fact, and how many are held at once is the cache's `retention`.

  `:latest` is the clock a consumer reads new heights from, so it is never
  cached, and a failed read is never cached either - the next call retries.
  """

  alias Rujira.Cache
  alias Rujira.Events
  alias Rujira.Logger
  alias Rujira.Node
  alias Rujira.String
  alias Rujira.Thorchain.Block.Event
  alias Thorchain.Types.BlockResponseHeader
  alias Thorchain.Types.BlockTxResult
  alias Thorchain.Types.Query.Stub
  alias Thorchain.Types.QueryBlockRequest
  alias Thorchain.Types.QueryBlockResponse
  alias Thorchain.Types.QueryBlockTx

  # --- Struct ---

  defstruct height: 0, time: nil, chain_id: nil, events: []

  @type t :: %__MODULE__{
          height: non_neg_integer(),
          time: DateTime.t() | nil,
          chain_id: String.t() | nil,
          events: [Event.t()]
        }

  @min_height 1
  @max_height 9_223_372_036_854_775_807

  @pre_block_tx_idx -2
  @begin_block_tx_idx -1
  @end_block_tx_idx 2_147_483_647

  # --- Stages ---

  @doc "The `tx_idx` of every `:pre_block` event, before any transaction."
  @spec pre_block_tx_idx() :: integer()
  def pre_block_tx_idx, do: @pre_block_tx_idx

  @doc "The `tx_idx` of every `:begin` event."
  @spec begin_block_tx_idx() :: integer()
  def begin_block_tx_idx, do: @begin_block_tx_idx

  @doc "The `tx_idx` of every `:end` event, after every transaction."
  @spec end_block_tx_idx() :: integer()
  def end_block_tx_idx, do: @end_block_tx_idx

  # --- Construction ---

  @doc """
  Builds a block from a node response.

  `time` is the header's RFC3339 timestamp, kept at microsecond precision - the
  node renders nanoseconds, which `DateTime` truncates. An absent timestamp is
  `nil`; an unparsable one is `{:error, :invalid_time}`.
  """
  @spec new(QueryBlockResponse.t()) :: {:ok, t()} | {:error, term()}
  def new(%QueryBlockResponse{header: %BlockResponseHeader{} = header} = res) do
    with {:ok, time} <- time(header.time) do
      {:ok,
       %__MODULE__{
         height: header.height,
         time: time,
         chain_id: String.nil_if_empty(header.chain_id),
         events: events(res, header.height)
       }}
    end
  end

  def new(_res), do: {:error, :invalid_attrs}

  # --- Queries ---

  @doc """
  The block at `height`, or the latest block.

  An integer height is cached (see the moduledoc on caching); `:latest` reads
  the node every time. A height outside `1..9_223_372_036_854_775_807` is
  `{:error, :invalid_height}` without reaching the node, and a height the node
  cannot serve is `{:error, {:height_unavailable, height}}`.
  """
  @spec get(:latest | integer(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def get(height \\ :latest, opts \\ [])

  def get(:latest, opts), do: fetch(:latest, opts)

  def get(height, opts)
      when is_integer(height) and height >= @min_height and height <= @max_height do
    # The height asked for *is* this read's height, so it needs no head: a
    # block can be read before the first `Rujira.Node.advance/1`, which is what
    # advancing the head is built on.
    opts = Keyword.put(opts, :height, height)

    Cache.fetch({__MODULE__, :get, [height]}, [:per_block], opts, fn h -> fetch(h, opts) end)
  end

  def get(_height, _opts), do: {:error, :invalid_height}

  # --- Private ---

  defp fetch(height, opts) do
    request = %QueryBlockRequest{height: request_height(height)}

    case Node.query(&Stub.block/3, request, Keyword.delete(opts, :height)) do
      {:ok, res} -> res |> new() |> verify_height(height)
      {:error, error} -> {:error, height_error(error, height)}
    end
  end

  defp request_height(:latest), do: ""
  defp request_height(height), do: Integer.to_string(height)

  defp verify_height({:ok, %__MODULE__{height: height} = block}, height), do: {:ok, block}
  defp verify_height({:ok, %__MODULE__{} = block}, :latest), do: {:ok, block}

  defp verify_height({:ok, %__MODULE__{height: returned}}, height),
    do: {:error, {:height_mismatch, height, returned}}

  defp verify_height({:error, _} = err, _height), do: err

  defp height_error(error, :latest), do: error

  defp height_error(error, height),
    do: unavailable(Node.height_unavailable?(error), error, height)

  defp unavailable(true, _error, height), do: {:height_unavailable, height}
  defp unavailable(false, error, _height), do: error

  defp time(nil), do: {:ok, nil}
  defp time(""), do: {:ok, nil}

  defp time(value) do
    case DateTime.from_iso8601(value) do
      {:ok, time, _offset} -> {:ok, time}
      {:error, _} -> {:error, :invalid_time}
    end
  end

  defp events(%QueryBlockResponse{} = res, height) do
    [
      stage_events(:pre_block, @pre_block_tx_idx, nil, res.finalize_block_events, height),
      stage_events(:begin, @begin_block_tx_idx, nil, res.begin_block_events, height),
      tx_events(res.txs, height),
      stage_events(:end, @end_block_tx_idx, nil, res.end_block_events, height)
    ]
    |> List.flatten()
    |> Enum.sort_by(&{&1.tx_idx, &1.event_idx})
  end

  defp tx_events(txs, height) do
    txs
    |> Enum.with_index()
    |> Enum.map(fn {%QueryBlockTx{hash: hash, result: result}, tx_idx} ->
      stage_events(:tx, tx_idx, hash, result_events(result), height)
    end)
  end

  defp result_events(%BlockTxResult{events: events}), do: events
  defp result_events(_result), do: []

  defp stage_events(stage, tx_idx, txhash, events, height) do
    events
    |> Enum.with_index()
    |> Enum.map(fn {raw, event_idx} ->
      cast = Events.cast(raw)
      Event.new(stage, tx_idx, event_idx, txhash, parse(cast, stage, tx_idx, event_idx, height))
    end)
  end

  defp parse(%{type: type, attributes: attrs} = cast, stage, tx_idx, event_idx, height) do
    case Events.parse(cast) do
      {:ok, event} ->
        event

      {:error, reason} ->
        Logger.warning(
          __MODULE__,
          "unparsed event height=#{height} stage=#{stage} tx_idx=#{tx_idx} " <>
            "event_idx=#{event_idx} type=#{type} #{inspect(reason)}"
        )

        Events.Event.new(type, attrs)
    end
  end
end
