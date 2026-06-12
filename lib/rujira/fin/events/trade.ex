defmodule Rujira.Fin.Events.Trade do
  @moduledoc "A FIN trade event (`wasm-rujira-fin/trade`)."

  alias Rujira.Amount
  alias Rujira.Fin.Events.Price
  alias Rujira.Fin.Events.TradeRange
  alias Rujira.Math

  defstruct side: :base, price: nil, rate: Decimal.new(0), offer: 0, bid: 0, ranges: nil

  @type t :: %__MODULE__{
          side: :base | :quote,
          price: Price.t(),
          rate: Decimal.t(),
          offer: Amount.t(),
          bid: Amount.t(),
          ranges: [TradeRange.t()] | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(
        %{"side" => side, "price" => price, "rate" => rate, "offer" => offer, "bid" => bid} =
          attrs
      ) do
    with {:ok, price} <- Price.parse(price),
         {:ok, rate} <- Math.to_decimal(rate),
         {:ok, offer} <- Amount.new(offer),
         {:ok, bid} <- Amount.new(bid),
         {:ok, ranges} <- TradeRange.parse_list(Map.get(attrs, "ranges")) do
      {:ok,
       %__MODULE__{
         side: side |> String.downcase() |> String.to_existing_atom(),
         price: price,
         rate: rate,
         offer: offer,
         bid: bid,
         ranges: ranges
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
