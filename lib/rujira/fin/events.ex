defmodule Rujira.Fin.Events do
  @moduledoc """
  Parser for FIN protocol wasm events.

  Transforms `%Event{}` into a `%FinEvent{address, data}` envelope.
  Sub-events are pure data constructors that receive a plain attrs map.

  | Event type | Data |
  |---|---|
  | `wasm-rujira-fin/trade` | `Rujira.Fin.Events.Trade` |
  | `wasm-rujira-fin/arb` | `Rujira.Fin.Events.Arb` |
  | `wasm-rujira-fin/arb_lot` | `Rujira.Fin.Events.ArbLot` |
  | `wasm-rujira-fin/order.create` | `Rujira.Fin.Events.OrderCreate` |
  | `wasm-rujira-fin/order.withdraw` | `Rujira.Fin.Events.OrderWithdraw` |
  | `wasm-rujira-fin/order.increase` | `Rujira.Fin.Events.OrderIncrease` |
  | `wasm-rujira-fin/order.retract` | `Rujira.Fin.Events.OrderRetract` |
  | `wasm-rujira-fin/range.create` | `Rujira.Fin.Events.RangeCreate` |
  | `wasm-rujira-fin/range.deposit` | `Rujira.Fin.Events.RangeDeposit` |
  | `wasm-rujira-fin/range.withdraw` | `Rujira.Fin.Events.RangeWithdraw` |
  | `wasm-rujira-fin/range.close` | `Rujira.Fin.Events.RangeClose` |
  | `wasm-rujira-fin/range.claim` | `Rujira.Fin.Events.RangeClaim` |
  | `wasm-rujira-fin/range.transfer` | `Rujira.Fin.Events.RangeTransfer` |
  | `wasm-rujira-fin/range.fee` | `Rujira.Fin.Events.RangeFee` |

  Any other `wasm-rujira-fin/` action is wrapped unparsed, as the
  `Rujira.Events.Event` itself.
  """

  alias Rujira.Events.Event
  alias Rujira.Fin.Events.Arb
  alias Rujira.Fin.Events.ArbLot
  alias Rujira.Fin.Events.Event, as: FinEvent
  alias Rujira.Fin.Events.OrderCreate
  alias Rujira.Fin.Events.OrderIncrease
  alias Rujira.Fin.Events.OrderRetract
  alias Rujira.Fin.Events.OrderWithdraw
  alias Rujira.Fin.Events.RangeClaim
  alias Rujira.Fin.Events.RangeClose
  alias Rujira.Fin.Events.RangeCreate
  alias Rujira.Fin.Events.RangeDeposit
  alias Rujira.Fin.Events.RangeFee
  alias Rujira.Fin.Events.RangeTransfer
  alias Rujira.Fin.Events.RangeWithdraw
  alias Rujira.Fin.Events.Trade

  @spec parse(Event.t()) :: {:ok, FinEvent.t()} | {:error, term()}

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

  def parse(%Event{} = event), do: {:ok, FinEvent.new(nil, event)}

  defp new("trade", attrs), do: Trade.new(attrs)
  defp new("arb", attrs), do: Arb.new(attrs)
  defp new("arb_lot", attrs), do: ArbLot.new(attrs)
  defp new("order.create", attrs), do: OrderCreate.new(attrs)
  defp new("order.withdraw", attrs), do: OrderWithdraw.new(attrs)
  defp new("order.increase", attrs), do: OrderIncrease.new(attrs)
  defp new("order.retract", attrs), do: OrderRetract.new(attrs)
  defp new("range.create", attrs), do: RangeCreate.new(attrs)
  defp new("range.deposit", attrs), do: RangeDeposit.new(attrs)
  defp new("range.withdraw", attrs), do: RangeWithdraw.new(attrs)
  defp new("range.close", attrs), do: RangeClose.new(attrs)
  defp new("range.claim", attrs), do: RangeClaim.new(attrs)
  defp new("range.transfer", attrs), do: RangeTransfer.new(attrs)
  defp new("range.fee", attrs), do: RangeFee.new(attrs)
  defp new(_, _), do: :pass
end
