defmodule Rujira.Ghost.Credit.Collateral do
  @moduledoc """
  One collateral holding of a credit account, with the two values the contract
  reports for it: its full value and its value after the collateral ratio.

  Both values are the contract's own, in the unit it priced them in - nothing is
  re-derived here. Use `Rujira.Ghost` as the public API.
  """

  alias Rujira.Coin
  alias Rujira.Math

  # --- Struct ---

  defstruct coin: nil, value_full: Decimal.new(0), value_adjusted: Decimal.new(0)

  @type t :: %__MODULE__{
          coin: Coin.t() | nil,
          value_full: Decimal.t(),
          value_adjusted: Decimal.t()
        }

  # --- Construction ---

  @doc """
  Builds a collateral from a `CollateralResponse`.

  The contract's `Collateral` is an enum; `coin` is its only variant, so any
  other is `{:error, :invalid_attrs}` rather than an empty holding.
  """
  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "collateral" => %{"coin" => %{"denom" => denom, "amount" => amount}},
        "value_full" => value_full,
        "value_adjusted" => value_adjusted
      })
      when is_binary(denom) and is_binary(amount) do
    with {:ok, coin} <- Coin.new(denom, amount),
         {:ok, value_full} <- Math.to_decimal(value_full),
         {:ok, value_adjusted} <- Math.to_decimal(value_adjusted) do
      {:ok, %__MODULE__{coin: coin, value_full: value_full, value_adjusted: value_adjusted}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
