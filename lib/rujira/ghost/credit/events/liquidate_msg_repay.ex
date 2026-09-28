defmodule Rujira.Ghost.Credit.Events.LiquidateMsgRepay do
  @moduledoc """
  A debt repayment made in the course of a liquidation
  (`wasm-rujira-ghost-credit/liquidate.msg/repay`).

  `amount` is what the liquidation spent; `repay_amount` is what reached the
  vault, after the two fees the contract took out of it.
  """

  alias Rujira.Amount
  alias Rujira.Coin

  defstruct amount: nil, repay_amount: 0, fee_liquidation: 0, fee_liquidator: 0

  @type t :: %__MODULE__{
          amount: Coin.t(),
          repay_amount: Amount.t(),
          fee_liquidation: Amount.t(),
          fee_liquidator: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "amount" => amount,
        "repay_amount" => repay_amount,
        "fee_liquidation" => fee_liquidation,
        "fee_liquidator" => fee_liquidator
      })
      when is_binary(amount) do
    with {:ok, amount} <- coin(amount),
         {:ok, repay_amount} <- Amount.new(repay_amount),
         {:ok, fee_liquidation} <- Amount.new(fee_liquidation),
         {:ok, fee_liquidator} <- Amount.new(fee_liquidator) do
      {:ok,
       %__MODULE__{
         amount: amount,
         repay_amount: repay_amount,
         fee_liquidation: fee_liquidation,
         fee_liquidator: fee_liquidator
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  defp coin(value) do
    case Coin.parse(value) do
      {:ok, [coin]} -> {:ok, coin}
      {:ok, _} -> {:error, :invalid_coin_format}
      {:error, _} = err -> err
    end
  end
end
