defmodule Rujira.Thorchain.Events do
  @moduledoc """
  Parser for THORChain native chain events.

  Routes event structs to typed struct modules.
  """

  alias Rujira.Events.Event
  alias Rujira.Thorchain.Events.AddLiquidity
  alias Rujira.Thorchain.Events.Bond
  alias Rujira.Thorchain.Events.OraclePrice
  alias Rujira.Thorchain.Events.PendingLiquidity
  alias Rujira.Thorchain.Events.SetMimir
  alias Rujira.Thorchain.Events.Swap
  alias Rujira.Thorchain.Events.Transfer
  alias Rujira.Thorchain.Events.Withdraw

  @spec parse(Event.t()) :: {:ok, struct()} | {:error, term()}
  def parse(%Event{type: "swap", attributes: attrs}), do: Swap.new(attrs)
  def parse(%Event{type: "transfer", attributes: attrs}), do: Transfer.new(attrs)
  def parse(%Event{type: "add_liquidity", attributes: attrs}), do: AddLiquidity.new(attrs)
  def parse(%Event{type: "withdraw", attributes: attrs}), do: Withdraw.new(attrs)
  def parse(%Event{type: "pending_liquidity", attributes: attrs}), do: PendingLiquidity.new(attrs)
  def parse(%Event{type: "oracle_price", attributes: attrs}), do: OraclePrice.new(attrs)
  def parse(%Event{type: "bond", attributes: attrs}), do: Bond.new(:bond, attrs)
  def parse(%Event{type: "rebond", attributes: attrs}), do: Bond.new(:rebond, attrs)
  def parse(%Event{type: "set_mimir", attributes: attrs}), do: SetMimir.new(attrs)
  def parse(%Event{} = event), do: {:ok, event}
end
