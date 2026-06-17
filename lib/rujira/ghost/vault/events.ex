defmodule Rujira.Ghost.Vault.Events do
  @moduledoc """
  Parser for Ghost vault wasm events.

  Transforms `%Event{}` into a `%VaultEvent{address, data}` envelope.
  Sub-events are pure data constructors that receive a plain attrs map.
  """

  alias Rujira.Events.Event
  alias Rujira.Ghost.Vault.Events.Borrow
  alias Rujira.Ghost.Vault.Events.Deposit
  alias Rujira.Ghost.Vault.Events.Event, as: VaultEvent
  alias Rujira.Ghost.Vault.Events.Repay
  alias Rujira.Ghost.Vault.Events.Withdraw

  @spec parse(Event.t()) :: {:ok, VaultEvent.t()} | {:error, term()}

  def parse(
        %Event{
          type: "wasm-rujira-ghost-vault/" <> action,
          attributes: %{"_contract_address" => address} = attrs
        } = event
      ) do
    case new(action, attrs) do
      {:ok, data} -> {:ok, VaultEvent.new(address, data)}
      {:error, _} = err -> err
      :pass -> {:ok, VaultEvent.new(address, event)}
    end
  end

  def parse(%Event{} = event), do: {:ok, VaultEvent.new(nil, event)}

  defp new("deposit", attrs), do: Deposit.new(attrs)
  defp new("withdraw", attrs), do: Withdraw.new(attrs)
  defp new("borrow", attrs), do: Borrow.new(attrs)
  defp new("repay", attrs), do: Repay.new(attrs)
  defp new(_, _), do: :pass
end
