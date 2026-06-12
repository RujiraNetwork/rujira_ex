defmodule Rujira.Fin.Events.RangeCreate do
  @moduledoc "A range creation event (`wasm-rujira-fin/range.create`)."

  alias Rujira.Amount
  alias Rujira.Math

  defstruct idx: 0,
            owner: nil,
            high: Decimal.new(0),
            low: Decimal.new(0),
            skew: Decimal.new(0),
            spread: Decimal.new(0),
            fee: Decimal.new(0),
            base: 0,
            quote: 0

  @type t :: %__MODULE__{
          idx: non_neg_integer(),
          owner: String.t(),
          high: Decimal.t(),
          low: Decimal.t(),
          skew: Decimal.t(),
          spread: Decimal.t(),
          fee: Decimal.t(),
          base: Amount.t(),
          quote: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "idx" => idx,
        "owner" => owner,
        "high" => high,
        "low" => low,
        "skew" => skew,
        "spread" => spread,
        "fee" => fee,
        "base" => base,
        "quote" => quote
      }) do
    with {:ok, idx} <- Math.to_integer(idx),
         {:ok, high} <- Math.to_decimal(high),
         {:ok, low} <- Math.to_decimal(low),
         {:ok, skew} <- Math.to_decimal(skew),
         {:ok, spread} <- Math.to_decimal(spread),
         {:ok, fee} <- Math.to_decimal(fee),
         {:ok, base} <- Amount.new(base),
         {:ok, quote} <- Amount.new(quote) do
      {:ok,
       %__MODULE__{
         idx: idx,
         owner: owner,
         high: high,
         low: low,
         skew: skew,
         spread: spread,
         fee: fee,
         base: base,
         quote: quote
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
