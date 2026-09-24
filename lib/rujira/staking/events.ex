defmodule Rujira.Staking.Events do
  @moduledoc """
  Parser for rujira-staking wasm events.

  Transforms `%Event{}` into a `%StakingEvent{address, data}` envelope.
  Sub-events are pure data constructors that receive a plain attrs map.
  """

  alias Rujira.Events.Event
  alias Rujira.Staking.Events.AccountBond
  alias Rujira.Staking.Events.AccountClaim
  alias Rujira.Staking.Events.AccountWithdraw
  alias Rujira.Staking.Events.Event, as: StakingEvent
  alias Rujira.Staking.Events.LiquidBond
  alias Rujira.Staking.Events.LiquidUnbond
  alias Rujira.Staking.Events.Settle

  @spec parse(Event.t()) :: {:ok, StakingEvent.t()} | {:error, term()}

  def parse(
        %Event{
          type: "wasm-rujira-staking/" <> action,
          attributes: %{"_contract_address" => address} = attrs
        } = event
      ) do
    case new(action, attrs) do
      {:ok, data} -> {:ok, StakingEvent.new(address, data)}
      {:error, _} = err -> err
      :pass -> {:ok, StakingEvent.new(address, event)}
    end
  end

  def parse(%Event{} = event), do: {:ok, StakingEvent.new(nil, event)}

  defp new("account.bond", attrs), do: AccountBond.new(attrs)
  defp new("account.claim", attrs), do: AccountClaim.new(attrs)
  defp new("account.withdraw", attrs), do: AccountWithdraw.new(attrs)
  defp new("liquid.bond", attrs), do: LiquidBond.new(attrs)
  defp new("liquid.unbond", attrs), do: LiquidUnbond.new(attrs)
  defp new("settle", attrs), do: Settle.new(attrs)
  defp new(_, _), do: :pass
end
