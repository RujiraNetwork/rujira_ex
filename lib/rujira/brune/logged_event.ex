defmodule Rujira.Brune.LoggedEvent do
  @moduledoc """
  A single page entry from a rujira-brune pool's on-chain event log.

  The contract stores its own event history so historical events can be
  replayed identically to how they were emitted live: each entry's `event` is
  normalised into the same `%Rujira.Events.Event{}` shape (`"wasm-" <> type`,
  `"_contract_address"` merged into the attributes) and routed through
  `Rujira.Brune.Events.parse/1`.

  There is no `from_id/2`: the contract's `events { start_after, limit }`
  ranges over ids `> start_after` and walks the log **descending from its
  current tip**, so no query can reach an arbitrary older `seq` - only
  `list/4`, paging back from the tip, can locate one.

  Struct, construction, and queries. Use `Rujira.Brune` as the public API.
  """

  alias Rujira.Brune.Events
  alias Rujira.Brune.Events.Event, as: BruneEvent
  alias Rujira.Cache
  alias Rujira.Contracts
  alias Rujira.Events.Event
  alias Rujira.Math
  alias Rujira.Node

  @max_limit 100

  # --- Struct ---

  defstruct id: nil, seq: 0, height: 0, time: nil, event: nil

  @type t :: %__MODULE__{
          id: String.t() | nil,
          seq: non_neg_integer(),
          height: non_neg_integer(),
          time: DateTime.t() | nil,
          event: BruneEvent.t()
        }

  # --- Construction ---

  @spec new(map(), String.t()) :: {:ok, t()} | {:error, term()}
  def new(
        %{
          "id" => seq,
          "height" => height,
          "time" => time,
          "event" => %{"type" => type, "attributes" => attributes}
        },
        address
      ) do
    with {:ok, seq} <- Math.to_integer(seq),
         {:ok, height} <- Math.to_integer(height),
         {:ok, time} <- Math.to_integer(time),
         {:ok, time} <- DateTime.from_unix(time, :nanosecond),
         {:ok, event} <- Events.parse(Event.new("wasm-" <> type, attributes(attributes, address))) do
      {:ok,
       %__MODULE__{id: "#{address}/#{seq}", seq: seq, height: height, time: time, event: event}}
    end
  end

  def new(_, _), do: {:error, :invalid_attrs}

  # --- Queries ---

  @doc """
  Fetches one page of a pool's event log, newest first, cached per
  `Rujira.Cache` against `{:contract, address}`; resolved at `opts[:height]` or
  the head.
  """
  @spec list(String.t(), integer() | nil, integer() | nil, Node.opts()) ::
          {:ok, [t()]} | {:error, term()}
  def list(address, start_after \\ nil, limit \\ @max_limit, opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, events} <-
           Cache.fetch(
             {__MODULE__, :list, [address, start_after, limit]},
             [{:contract, address}],
             opts,
             fn _height -> fetch_events(address, start_after, limit, opts) end
           ) do
      Rujira.Enum.reduce_while_ok(events, &new(&1, address))
    end
  end

  # --- Private ---

  defp fetch_events(address, start_after, limit, opts) do
    case Contracts.query_state_smart(
           address,
           %{events: %{start_after: start_after, limit: limit}},
           opts
         ) do
      {:ok, %{"events" => events}} -> {:ok, events}
      {:ok, _} -> {:error, :invalid_response}
      {:error, _} = err -> err
    end
  end

  defp attributes(attributes, address) do
    attributes
    |> Enum.reduce(%{}, fn %{"key" => key, "value" => value}, acc -> Map.put(acc, key, value) end)
    |> Map.put("_contract_address", address)
  end
end
