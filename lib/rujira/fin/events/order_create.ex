defmodule Rujira.Fin.Events.OrderCreate do
  @moduledoc "An order creation event (`wasm-rujira-fin/order.create`)."

  alias Rujira.Amount
  alias Rujira.Fin.Events.Price

  defstruct owner: nil, side: :base, price: nil, offer: 0

  @type t :: %__MODULE__{
          owner: String.t(),
          side: :base | :quote,
          price: Price.t(),
          offer: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"owner" => owner, "side" => side, "price" => price, "offer" => offer}) do
    with {:ok, price} <- Price.parse(price),
         {:ok, offer} <- Amount.new(offer) do
      {:ok,
       %__MODULE__{
         owner: owner,
         side: side |> String.downcase() |> String.to_existing_atom(),
         price: price,
         offer: offer
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
