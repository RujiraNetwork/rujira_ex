defmodule Rujira.Events do
  @moduledoc """
  Generic event parser for all Rujira events.

  Takes a raw event, creates a default `Event` struct, then routes it
  to the correct protocol parser. Each protocol returns an envelope
  struct so consumers can match at protocol, type, or field level.

  ## Usage

      case Rujira.Events.parse(raw_event) do
        # Match all FIN events
        {:ok, %Rujira.Fin.Events.Event{} = e} -> handle_fin(e)

        # Match a specific FIN event by inner struct
        {:ok, %Rujira.Fin.Events.Event{data: %Rujira.Fin.Events.Trade{} = trade}} -> ...

        # Match all Thorchain events
        {:ok, %Rujira.Thorchain.Events.Event{} = e} -> handle_tc(e)

        # Unrecognized protocol
        {:ok, %Rujira.Events.Event{} = event} -> handle_unknown(event)
      end
  """

  alias Rujira.Events.Event
  alias Thorchain.Types.BlockEvent

  @typedoc "A raw THORChain `BlockEvent` protobuf struct, as the node returns it."
  @type block_event :: %BlockEvent{}

  @doc """
  Casts a raw `BlockEvent` protobuf struct into the standard
  `%{type: String.t(), attributes: map()}` format.

  A `BlockEvent` whose pairs don't start with `%{key: "type"}` casts to
  `%{type: nil, attributes: <all pairs as a map>}` instead of raising.
  """
  @spec cast(block_event()) :: %{type: String.t() | nil, attributes: map()}
  def cast(%BlockEvent{
        event_kv_pair: [
          %{key: "type", value: type}
          | attributes
        ]
      }) do
    attrs =
      Enum.reduce(attributes, %{}, fn %{key: key, value: value}, acc ->
        Map.put(acc, key, value)
      end)

    %{type: type, attributes: attrs}
  end

  def cast(%BlockEvent{event_kv_pair: pairs}) do
    attrs =
      Enum.reduce(pairs, %{}, fn %{key: key, value: value}, acc ->
        Map.put(acc, key, value)
      end)

    %{type: nil, attributes: attrs}
  end

  @doc """
  Parses a raw event into a typed struct from the matching protocol.

  Accepts:
  - `%{type: String.t(), attributes: map()}` — already cast
  - `%BlockEvent{}` — raw protobuf, cast first

  Returns `{:ok, struct}` for known events or `{:ok, %Event{}}` for
  unrecognized events so consumers never lose data.
  """
  alias Rujira.Brune.Events.Event, as: BruneEvent
  alias Rujira.Fin.Events.Event, as: FinEvent
  alias Rujira.Ghost.Credit.Events.Event, as: GhostCreditEvent
  alias Rujira.Ghost.Vault.Events.Event, as: GhostVaultEvent
  alias Rujira.Revenue.Events.Event, as: RevenueEvent
  alias Rujira.Staking.Events.Event, as: StakingEvent
  alias Rujira.Thorchain.Events.Event, as: TcEvent
  alias Rujira.ThorchainSwap.Events.Event, as: ThorchainSwapEvent

  @spec parse(map() | block_event()) ::
          {:ok,
           FinEvent.t()
           | TcEvent.t()
           | ThorchainSwapEvent.t()
           | GhostVaultEvent.t()
           | GhostCreditEvent.t()
           | RevenueEvent.t()
           | StakingEvent.t()
           | BruneEvent.t()
           | Event.t()}
          | {:error, term()}

  def parse(%BlockEvent{} = event), do: event |> cast() |> parse()

  def parse(%{type: type, attributes: attrs}) do
    event = Event.new(type, attrs)
    route(event)
  end

  def parse(_), do: {:error, :invalid_event}

  @doc """
  Whether a parse failure's `reason` is the data's fault.

  True for an `:invalid_*` atom and an `{:invalid_*, detail}` tuple - the
  reasons a parser gives for input it cannot read. Anything else is not:
  a node, transport or timeout failure, `{:height_unavailable, height}`, and
  any reason nobody anticipated.

  A block parse uses this to choose between degrading a slot and failing the
  block: data the parser cannot read degrades to the generic struct, but a
  failure that is not the data's fault may succeed on a retry, so it is
  returned rather than hidden. See `Rujira.Thorchain.Block`.

      iex> Rujira.Events.data_error?(:invalid_attrs)
      true
      iex> Rujira.Events.data_error?({:invalid_message, 42})
      true
      iex> Rujira.Events.data_error?(:timeout)
      false
      iex> Rujira.Events.data_error?({:height_unavailable, 100})
      false
  """
  @spec data_error?(term()) :: boolean()
  def data_error?(reason) when is_atom(reason), do: invalid?(reason)
  def data_error?({reason, _detail}) when is_atom(reason), do: invalid?(reason)
  def data_error?(_reason), do: false

  defp invalid?(reason), do: match?("invalid_" <> _, Atom.to_string(reason))

  defp route(%Event{type: "wasm-rujira-fin/" <> _} = event),
    do: Rujira.Fin.Events.parse(event)

  defp route(%Event{type: "wasm-rujira-thorchain-swap/" <> _} = event),
    do: Rujira.ThorchainSwap.Events.parse(event)

  defp route(%Event{type: "wasm-rujira-ghost-vault/" <> _} = event),
    do: Rujira.Ghost.Vault.Events.parse(event)

  defp route(%Event{type: "wasm-rujira-ghost-credit/" <> _} = event),
    do: Rujira.Ghost.Credit.Events.parse(event)

  defp route(%Event{type: "wasm-rujira-revenue/" <> _} = event),
    do: Rujira.Revenue.Events.parse(event)

  defp route(%Event{type: "wasm-rujira-staking/" <> _} = event),
    do: Rujira.Staking.Events.parse(event)

  defp route(%Event{type: "wasm-rujira-brune/" <> _} = event),
    do: Rujira.Brune.Events.parse(event)

  defp route(%Event{type: type} = event)
       when type in ~w(swap transfer add_liquidity withdraw pending_liquidity oracle_price bond rebond rewards affiliate_fee set_mimir),
       do: Rujira.Thorchain.Events.parse(event)

  # --- Not yet implemented ---
  # defp route(%Event{type: "wasm-rujira-merge/" <> _} = event), do: Rujira.Merge.Events.parse(event)
  # defp route(%Event{type: "wasm-rujira-ventures-factory/" <> _} = event), do: Rujira.Keiko.Events.parse(event)
  # defp route(%Event{type: "wasm-calc-" <> _} = event), do: Rujira.Calc.Events.parse(event)

  defp route(%Event{} = event), do: {:ok, event}
end
