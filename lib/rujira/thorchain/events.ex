defmodule Rujira.Thorchain.Events do
  @moduledoc """
  Parser for THORChain native chain events.

  Transforms `%Event{}` into a `%TcEvent{data}` envelope.
  Sub-events are pure data constructors that receive a plain attrs map.
  """

  alias Rujira.Events.Event
  alias Rujira.Thorchain.Events.AddLiquidity
  alias Rujira.Thorchain.Events.Bond
  alias Rujira.Thorchain.Events.Event, as: TcEvent
  alias Rujira.Thorchain.Events.OraclePrice
  alias Rujira.Thorchain.Events.PendingLiquidity
  alias Rujira.Thorchain.Events.SetMimir
  alias Rujira.Thorchain.Events.Swap
  alias Rujira.Thorchain.Events.Transfer
  alias Rujira.Thorchain.Events.Withdraw

  @spec parse(Event.t()) :: {:ok, TcEvent.t()} | {:error, term()}

  def parse(%Event{type: type, attributes: attrs} = event) do
    case new(type, attrs) do
      {:ok, data} -> {:ok, TcEvent.new(data)}
      {:error, _} = err -> err
      :pass -> {:ok, TcEvent.new(event)}
    end
  end

  defp new("swap", attrs), do: Swap.new(attrs)
  defp new("transfer", attrs), do: Transfer.new(attrs)
  defp new("add_liquidity", attrs), do: AddLiquidity.new(attrs)
  defp new("withdraw", attrs), do: Withdraw.new(attrs)
  defp new("pending_liquidity", attrs), do: PendingLiquidity.new(attrs)
  defp new("oracle_price", attrs), do: OraclePrice.new(attrs)
  defp new("bond", attrs), do: Bond.new(:bond, attrs)
  defp new("rebond", attrs), do: Bond.new(:rebond, attrs)
  defp new("set_mimir", attrs), do: SetMimir.new(attrs)
  defp new(_, _), do: :pass
end
