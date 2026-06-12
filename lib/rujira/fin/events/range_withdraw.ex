defmodule Rujira.Fin.Events.RangeWithdraw do
  @moduledoc "A range withdrawal event (`wasm-rujira-fin/range.withdraw`)."

  alias Rujira.Amount
  alias Rujira.Math

  defstruct idx: 0, owner: nil, amount: Decimal.new(0), base: 0, quote: 0

  @type t :: %__MODULE__{
          idx: non_neg_integer(),
          owner: String.t(),
          amount: Decimal.t(),
          base: Amount.t(),
          quote: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"idx" => idx, "owner" => owner, "amount" => amount, "base" => base, "quote" => quote}) do
    with {:ok, idx} <- Math.to_integer(idx),
         {:ok, amount} <- Math.to_decimal(amount),
         {:ok, base} <- Amount.new(base),
         {:ok, quote} <- Amount.new(quote) do
      {:ok, %__MODULE__{idx: idx, owner: owner, amount: amount, base: base, quote: quote}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
