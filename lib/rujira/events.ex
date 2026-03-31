defmodule Rujira.Events do
  @moduledoc """
  Generic event parser for all Rujira protocol events.

  Takes a raw event and routes it to the correct protocol parser,
  returning a typed struct or `nil`.

  Accepts both already-cast events (`%{type: ..., attributes: ...}`)
  and raw protobuf `BlockEvent` structs.

  ## Usage

      case Rujira.Events.parse(raw_event) do
        %Rujira.Fin.Events.Trade{} = trade -> handle_trade(trade)
        %Rujira.Thorchain.Events.Swap{} = swap -> handle_swap(swap)
        nil -> :unhandled
      end
  """

  alias Thorchain.Types.BlockEvent

  # --- Casting raw protos ---

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

  # --- Parse ---

  @doc """
  Parses a raw event into a typed struct from the matching protocol.

  Accepts:
  - `%{type: String.t(), attributes: map()}` — already cast
  - `%BlockEvent{}` — raw protobuf, cast first

  Returns `nil` if no parser matches.
  """
  @spec parse(map() | BlockEvent.t()) :: struct() | nil

  # Raw proto — cast first
  def parse(%BlockEvent{} = event), do: event |> cast() |> parse()

  # FIN
  def parse(%{type: "wasm-rujira-fin/" <> _} = event), do: Rujira.Fin.Events.parse(event)

  # Thorchain native
  def parse(%{type: type} = event)
      when type in ~w(swap transfer add_liquidity withdraw pending_liquidity oracle_price bond rebond set_mimir),
      do: Rujira.Thorchain.Events.parse(event)

  # --- Not yet implemented ---
  # def parse(%{type: "wasm-rujira-bow/" <> _} = event), do: Rujira.Bow.Events.parse(event)
  # def parse(%{type: "wasm-rujira-ghost-vault/" <> _} = event), do: Rujira.Ghost.Events.parse(event)
  # def parse(%{type: "wasm-rujira-ghost-credit/" <> _} = event), do: Rujira.Ghost.Events.parse(event)
  # def parse(%{type: "wasm-rujira-staking/" <> _} = event), do: Rujira.Staking.Events.parse(event)
  # def parse(%{type: "wasm-rujira-merge/" <> _} = event), do: Rujira.Merge.Events.parse(event)
  # def parse(%{type: "wasm-rujira-brune/" <> _} = event), do: Rujira.Brune.Events.parse(event)
  # def parse(%{type: "wasm-rujira-thorchain-swap/" <> _} = event), do: Rujira.Thorchain.Swap.Events.parse(event)
  # def parse(%{type: "wasm-rujira-ventures-factory/" <> _} = event), do: Rujira.Keiko.Events.parse(event)
  # def parse(%{type: "wasm-calc-" <> _} = event), do: Rujira.Calc.Events.parse(event)

  # No match
  def parse(_), do: nil
end
