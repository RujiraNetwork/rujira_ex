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

  @doc """
  Casts a raw `BlockEvent` protobuf struct into the standard
  `%{type: String.t(), attributes: map()}` format.
  """
  @spec cast(BlockEvent.t()) :: %{type: String.t(), attributes: map()}
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

  @doc """
  Parses a raw event into a typed struct from the matching protocol.

  Accepts:
  - `%{type: String.t(), attributes: map()}` — already cast
  - `%BlockEvent{}` — raw protobuf, cast first

  Returns `{:ok, struct}` for known events or `{:ok, %Event{}}` for
  unrecognized events so consumers never lose data.
  """
  alias Rujira.Fin.Events.Event, as: FinEvent
  alias Rujira.Thorchain.Events.Event, as: TcEvent

  @spec parse(map() | BlockEvent.t()) ::
          {:ok, FinEvent.t() | TcEvent.t() | Event.t()} | {:error, term()}

  def parse(%BlockEvent{} = event), do: event |> cast() |> parse()

  def parse(%{type: type, attributes: attrs}) do
    event = Event.new(type, attrs)
    route(event)
  end

  def parse(_), do: {:error, :invalid_event}

  defp route(%Event{type: "wasm-rujira-fin/" <> _} = event),
    do: Rujira.Fin.Events.parse(event)

  defp route(%Event{type: type} = event)
       when type in ~w(swap transfer add_liquidity withdraw pending_liquidity oracle_price bond rebond set_mimir),
       do: Rujira.Thorchain.Events.parse(event)

  # --- Not yet implemented ---
  # defp route(%Event{type: "wasm-rujira-bow/" <> _} = event), do: Rujira.Bow.Events.parse(event)
  # defp route(%Event{type: "wasm-rujira-ghost-vault/" <> _} = event), do: Rujira.Ghost.Events.parse(event)
  # defp route(%Event{type: "wasm-rujira-ghost-credit/" <> _} = event), do: Rujira.Ghost.Events.parse(event)
  # defp route(%Event{type: "wasm-rujira-staking/" <> _} = event), do: Rujira.Staking.Events.parse(event)
  # defp route(%Event{type: "wasm-rujira-merge/" <> _} = event), do: Rujira.Merge.Events.parse(event)
  # defp route(%Event{type: "wasm-rujira-brune/" <> _} = event), do: Rujira.Brune.Events.parse(event)
  # defp route(%Event{type: "wasm-rujira-thorchain-swap/" <> _} = event), do: Rujira.Thorchain.Swap.Events.parse(event)
  # defp route(%Event{type: "wasm-rujira-ventures-factory/" <> _} = event), do: Rujira.Keiko.Events.parse(event)
  # defp route(%Event{type: "wasm-calc-" <> _} = event), do: Rujira.Calc.Events.parse(event)

  defp route(%Event{} = event), do: {:ok, event}
end
