defmodule Rujira.Fin.Order do
  @moduledoc """
  Represents and manages trading orders in the FIN protocol.
  """

  alias Rujira.Assets
  alias Rujira.Math
  alias Rujira.Prices

  defstruct id: nil,
            pair: nil,
            owner: nil,
            side: nil,
            rate: 0,
            updated_at: nil,
            offer: 0,
            offer_value: 0,
            remaining: 0,
            remaining_value: 0,
            filled: 0,
            filled_value: 0,
            filled_fee: 0,
            value_usd: 0,
            type: nil,
            deviation: nil

  @type side :: :base | :quote
  @type deviation :: nil | integer()
  @type type_order :: :fixed | :oracle
  @type t :: %__MODULE__{
          pair: String.t(),
          owner: String.t(),
          side: side,
          rate: Decimal.t(),
          updated_at: DateTime.t(),
          offer: integer(),
          offer_value: integer(),
          remaining: integer(),
          remaining_value: integer(),
          filled: integer(),
          filled_value: integer(),
          filled_fee: integer(),
          value_usd: integer(),
          type: type_order,
          deviation: deviation
        }

  def from_query(
        %{
          address: address,
          fee_taker: fee_taker,
          token_quote: token_quote,
          token_base: token_base
        },
        %{
          "owner" => owner,
          "side" => side,
          "price" => price,
          "rate" => rate,
          "updated_at" => updated_at,
          "offer" => offer,
          "remaining" => remaining,
          "filled" => filled
        }
      ) do
    with {type, deviation, price_id} <- parse_price(price),
         {rate, ""} <- Decimal.parse(rate),
         {updated_at, ""} <- Integer.parse(updated_at),
         {:ok, updated_at} <- DateTime.from_unix(updated_at, :nanosecond),
         {offer, ""} <- Integer.parse(offer),
         {remaining, ""} <- Integer.parse(remaining),
         {filled, ""} <- Integer.parse(filled),
         {:ok, asset_quote} <- Assets.from_denom(token_quote),
         {:ok, asset_base} <- Assets.from_denom(token_base) do
      side = String.to_existing_atom(side)

      filled_fee = Math.mul_floor(filled, fee_taker)

      remaining_value = value(remaining, rate, side)
      filled_value = value(filled, Decimal.div(Decimal.new(1), rate), side)

      %__MODULE__{
        id: "#{address}/#{side}/#{price_id}/#{owner}",
        pair: address,
        owner: owner,
        side: side,
        rate: rate,
        updated_at: updated_at,
        offer: offer,
        offer_value: value(offer, rate, side),
        remaining: remaining,
        remaining_value: remaining_value,
        filled: filled,
        filled_value: filled_value,
        filled_fee: filled_fee,
        type: type,
        deviation: deviation,
        value_usd:
          case side do
            :quote ->
              Prices.value_usd(asset_quote.symbol, remaining) +
                Prices.value_usd(asset_base.symbol, filled)

            :base ->
              Prices.value_usd(asset_base.symbol, remaining) +
                Prices.value_usd(asset_quote.symbol, filled)
          end
      }
    end
  end

  def parse_price(%{"fixed" => v}), do: {:fixed, nil, "fixed:#{v}"}
  def parse_price(%{"oracle" => v}), do: {:oracle, v, "oracle:#{v}"}
  def decode_price("fixed:" <> v), do: %{fixed: v}
  def decode_price("oracle:" <> v), do: %{oracle: String.to_integer(v)}
  def encode_price(%{fixed: v}), do: "fixed:#{v}"
  def encode_price(%{oracle: v}), do: "oracle:#{v}"

  def new(address, side, price, owner) do
    [type | _] = String.split(price, ":")

    %__MODULE__{
      id: "#{address}/#{side}/#{price}/#{owner}",
      pair: address,
      owner: owner,
      side: String.to_existing_atom(side),
      rate: 0,
      updated_at: DateTime.utc_now(),
      offer: 0,
      remaining: 0,
      filled: 0,
      type: type,
      deviation: nil
    }
  end

  defp value(amount, rate, :base) do
    Math.mul_floor(amount, rate)
  end

  defp value(amount, rate, :quote) do
    Math.div_floor(amount, rate)
  end
end
