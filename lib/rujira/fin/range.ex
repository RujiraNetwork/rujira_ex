defmodule Rujira.Fin.Range do
  @moduledoc """
  Represents and manages concentrated liquidity positions (ranges) in the FIN protocol.
  """

  alias Rujira.Assets
  alias Rujira.Math
  alias Rujira.Prices

  defstruct id: nil,
            idx: nil,
            pair: nil,
            owner: nil,
            high: 0,
            low: 0,
            skew: 0,
            spread: 0,
            fee: 0,
            base: 0,
            quote: 0,
            price: 0,
            ask: 0,
            bid: 0,
            fees_base: 0,
            fees_quote: 0,
            value_usd: 0

  @type t :: %__MODULE__{
          id: String.t(),
          idx: integer(),
          pair: String.t(),
          owner: String.t(),
          high: integer(),
          low: integer(),
          skew: integer(),
          spread: integer(),
          fee: integer(),
          base: integer(),
          quote: integer(),
          price: integer(),
          ask: integer(),
          bid: integer(),
          fees_base: integer(),
          fees_quote: integer(),
          value_usd: integer()
        }

  @doc """
  Parses a range from a contract query response.
  """
  def from_query(
        %{
          address: address,
          token_quote: token_quote,
          token_base: token_base
        },
        %{
          "idx" => idx,
          "owner" => owner,
          "high" => high,
          "low" => low,
          "skew" => skew,
          "spread" => spread,
          "fee" => fee,
          "base" => base_amount,
          "quote" => quote_amount,
          "price" => price,
          "ask" => ask,
          "bid" => bid,
          "fees" => [fees_base, fees_quote]
        }
      ) do
    with {:ok, asset_quote} <- Assets.from_denom(token_quote),
         {:ok, asset_base} <- Assets.from_denom(token_base),
         {ask, ""} <- Decimal.parse(ask),
         {bid, ""} <- Decimal.parse(bid),
         {base_amount, ""} <- Decimal.parse(base_amount),
         {quote_amount, ""} <- Decimal.parse(quote_amount),
         {fees_base, ""} <- Decimal.parse(fees_base),
         {fees_quote, ""} <- Decimal.parse(fees_quote),
         {price, ""} <- Decimal.parse(price),
         {high, ""} <- Decimal.parse(high),
         {low, ""} <- Decimal.parse(low),
         {skew, ""} <- Decimal.parse(skew),
         {spread, ""} <- Decimal.parse(spread),
         {fee, ""} <- Decimal.parse(fee),
         {idx, ""} <- Integer.parse(idx) do
      base_int = Math.floor(base_amount)
      quote_int = Math.floor(quote_amount)
      base_fees_int = Math.floor(fees_base)
      quote_fees_int = Math.floor(fees_quote)

      %__MODULE__{
        id: "#{address}/#{idx}",
        idx: idx,
        pair: address,
        owner: owner,
        high: high,
        low: low,
        skew: skew,
        spread: spread,
        fee: fee,
        base: base_int,
        quote: quote_int,
        price: price,
        ask: ask,
        bid: bid,
        fees_base: base_fees_int,
        fees_quote: quote_fees_int,
        value_usd:
          Prices.value_usd(asset_base.symbol, base_int + base_fees_int) +
            Prices.value_usd(asset_quote.symbol, quote_int + quote_fees_int)
      }
    end
  end

  @doc """
  Creates a minimal range struct for subscription edge responses.
  """
  def new(address, idx) do
    %__MODULE__{id: "#{address}/#{idx}", idx: idx, pair: address}
  end
end
