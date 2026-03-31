defmodule Rujira.Fin.Events.Trade do
  @moduledoc "A FIN trade event (`wasm-rujira-fin/trade`)."

  alias Rujira.Amount
  alias Rujira.Math

  defstruct [:contract, :side, :price, :rate, :offer, :bid, :ranges]

  @type t :: %__MODULE__{
          contract: String.t(),
          side: :base | :quote,
          price: String.t(),
          rate: Decimal.t() | nil,
          offer: Amount.t() | nil,
          bid: Amount.t() | nil,
          ranges: String.t() | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"_contract_address" => contract, "side" => side, "price" => price} = attrs) do
    with {:ok, rate} <- Math.to_decimal(Map.get(attrs, "rate")),
         {:ok, offer} <- Amount.new(Map.get(attrs, "offer")),
         {:ok, bid} <- Amount.new(Map.get(attrs, "bid")) do
      {:ok,
       %__MODULE__{
         contract: contract,
         side: side(side),
         price: price,
         rate: rate,
         offer: offer,
         bid: bid,
         ranges: Map.get(attrs, "ranges")
       }}
    end
  end

  defp side("Base"), do: :base
  defp side("Quote"), do: :quote
  defp side(s), do: s
end
