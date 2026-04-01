defmodule Rujira.Fin.Events.Trade do
  @moduledoc "A FIN trade event (`wasm-rujira-fin/trade`)."

  alias Rujira.Amount
  alias Rujira.Math

  defstruct side: nil, price: nil, rate: nil, offer: nil, bid: nil, ranges: nil

  @type t :: %__MODULE__{
          side: :base | :quote,
          price: String.t(),
          rate: Decimal.t() | nil,
          offer: Amount.t() | nil,
          bid: Amount.t() | nil,
          ranges: String.t() | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"side" => side, "price" => price} = attrs) do
    with {:ok, rate} <- Math.to_decimal(Map.get(attrs, "rate")),
         {:ok, offer} <- Amount.new(Map.get(attrs, "offer")),
         {:ok, bid} <- Amount.new(Map.get(attrs, "bid")) do
      {:ok,
       %__MODULE__{
         side: side |> String.downcase() |> String.to_existing_atom(),
         price: price,
         rate: rate,
         offer: offer,
         bid: bid,
         ranges: Map.get(attrs, "ranges")
       }}
    end
  end
end
