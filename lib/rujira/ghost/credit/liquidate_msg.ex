defmodule Rujira.Ghost.Credit.LiquidateMsg do
  @moduledoc """
  One step of a liquidation route (`LiquidateMsg`).

  The contract's enum has two variants, each its own struct:
  `Rujira.Ghost.Credit.LiquidateMsg.Repay` and
  `Rujira.Ghost.Credit.LiquidateMsg.Execute`. A variant this library does not
  know is `{:error, :invalid_attrs}` - never a dropped or placeholder step.
  """

  alias Rujira.Ghost.Credit.LiquidateMsg.Execute
  alias Rujira.Ghost.Credit.LiquidateMsg.Repay

  @type t :: Repay.t() | Execute.t()

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"repay" => denom}), do: Repay.new(denom)
  def new(%{"execute" => attrs}), do: Execute.new(attrs)
  def new(_), do: {:error, :invalid_attrs}
end
