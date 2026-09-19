defmodule Rujira.Fin.Range.Fixed do
  @moduledoc """
  State of a fixed-bounds concentrated liquidity range.

  The original FIN range: liquidity distributed between `low` and `high` with a
  fixed `skew`, `spread` and `fee`. Carried under `range:` on `Rujira.Fin.Range`.
  """

  alias Rujira.Amount
  alias Rujira.Math

  # --- Struct ---

  defstruct high: Decimal.new(0),
            low: Decimal.new(0),
            skew: Decimal.new(0),
            spread: Decimal.new(0),
            fee: Decimal.new(0),
            base: 0,
            quote: 0,
            price: Decimal.new(0),
            ask: Decimal.new(0),
            bid: Decimal.new(0),
            fees_base: 0,
            fees_quote: 0

  @type t :: %__MODULE__{
          high: Decimal.t(),
          low: Decimal.t(),
          skew: Decimal.t(),
          spread: Decimal.t(),
          fee: Decimal.t(),
          base: Amount.t(),
          quote: Amount.t(),
          price: Decimal.t(),
          ask: Decimal.t(),
          bid: Decimal.t(),
          fees_base: Amount.t(),
          fees_quote: Amount.t()
        }

  # --- Construction ---

  @doc "Parses the fixed arm of a range query response."
  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "high" => high,
        "low" => low,
        "skew" => skew,
        "spread" => spread,
        "fee" => fee,
        "base" => base,
        "quote" => quote,
        "price" => price,
        "ask" => ask,
        "bid" => bid,
        "fees" => [fees_base, fees_quote]
      }) do
    with {:ok, high} <- Math.to_decimal(high),
         {:ok, low} <- Math.to_decimal(low),
         {:ok, skew} <- Math.to_decimal(skew),
         {:ok, spread} <- Math.to_decimal(spread),
         {:ok, fee} <- Math.to_decimal(fee),
         {:ok, base} <- Amount.new(base),
         {:ok, quote_} <- Amount.new(quote),
         {:ok, price} <- Math.to_decimal(price),
         {:ok, ask} <- Math.to_decimal(ask),
         {:ok, bid} <- Math.to_decimal(bid),
         {:ok, fees_base} <- Amount.new(fees_base),
         {:ok, fees_quote} <- Amount.new(fees_quote) do
      {:ok,
       %__MODULE__{
         high: high,
         low: low,
         skew: skew,
         spread: spread,
         fee: fee,
         base: base,
         quote: quote_,
         price: price,
         ask: ask,
         bid: bid,
         fees_base: fees_base,
         fees_quote: fees_quote
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Calculations ---

  @doc "Total base and quote held by the range, including uncollected fees."
  @spec totals(t()) :: {Amount.t(), Amount.t()}
  def totals(%__MODULE__{} = range),
    do: {range.base + range.fees_base, range.quote + range.fees_quote}
end
