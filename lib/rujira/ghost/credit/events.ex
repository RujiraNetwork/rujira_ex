defmodule Rujira.Ghost.Credit.Events do
  @moduledoc """
  Parser for Ghost credit wasm events.

  Transforms `%Event{}` into a `%CreditEvent{address, data}` envelope.
  Sub-events are pure data constructors that receive a plain attrs map.

  Attributes are read exactly as the contract emits them, misspellings included -
  see `Rujira.Ghost.Credit.Events.AccountMsgTransfer`.

  The one attribute no sub-event carries is `funds`, on the `execute` and `send`
  events: it is a `NativeBalance` rendered with no delimiter between coins, so a
  multi-coin value cannot be split back apart. Rather than guess, those structs
  have no field for it. Upstream is fixing the rendering.
  """

  alias Rujira.Events.Event
  alias Rujira.Ghost.Credit.Events.AccountCreate
  alias Rujira.Ghost.Credit.Events.AccountLiquidate
  alias Rujira.Ghost.Credit.Events.AccountMsg
  alias Rujira.Ghost.Credit.Events.AccountMsgBorrow
  alias Rujira.Ghost.Credit.Events.AccountMsgExecute
  alias Rujira.Ghost.Credit.Events.AccountMsgRepay
  alias Rujira.Ghost.Credit.Events.AccountMsgSend
  alias Rujira.Ghost.Credit.Events.AccountMsgSetPreferenceMsgs
  alias Rujira.Ghost.Credit.Events.AccountMsgSetPreferenceOrder
  alias Rujira.Ghost.Credit.Events.AccountMsgTransfer
  alias Rujira.Ghost.Credit.Events.Event, as: CreditEvent
  alias Rujira.Ghost.Credit.Events.LiquidateMsgExecute
  alias Rujira.Ghost.Credit.Events.LiquidateMsgPreferenceError
  alias Rujira.Ghost.Credit.Events.LiquidateMsgRepay

  @spec parse(Event.t()) :: {:ok, CreditEvent.t()} | {:error, term()}

  def parse(
        %Event{
          type: "wasm-rujira-ghost-credit/" <> action,
          attributes: %{"_contract_address" => address} = attrs
        } = event
      ) do
    case new(action, attrs) do
      {:ok, data} -> {:ok, CreditEvent.new(address, data)}
      {:error, _} = err -> err
      :pass -> {:ok, CreditEvent.new(address, event)}
    end
  end

  def parse(%Event{} = event), do: {:ok, CreditEvent.new(nil, event)}

  defp new("account.create", attrs), do: AccountCreate.new(attrs)
  defp new("account.msg", attrs), do: AccountMsg.new(attrs)
  defp new("account.msg/borrow", attrs), do: AccountMsgBorrow.new(attrs)
  defp new("account.msg/repay", attrs), do: AccountMsgRepay.new(attrs)
  defp new("account.msg/execute", attrs), do: AccountMsgExecute.new(attrs)
  defp new("account.msg/send", attrs), do: AccountMsgSend.new(attrs)
  defp new("account.msg/transfer", attrs), do: AccountMsgTransfer.new(attrs)
  defp new("account.msg/set_preference_order", attrs), do: AccountMsgSetPreferenceOrder.new(attrs)
  defp new("account.msg/set_preference_msgs", attrs), do: AccountMsgSetPreferenceMsgs.new(attrs)
  defp new("account.liquidate", attrs), do: AccountLiquidate.new(attrs)
  defp new("liquidate.msg/preference.error", attrs), do: LiquidateMsgPreferenceError.new(attrs)
  defp new("liquidate.msg/repay", attrs), do: LiquidateMsgRepay.new(attrs)
  defp new("liquidate.msg/execute", attrs), do: LiquidateMsgExecute.new(attrs)
  defp new(_, _), do: :pass
end
