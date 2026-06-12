defmodule Rujira.Fin.Events.OrderWithdraw do
  @moduledoc "An order claim/withdraw event (`wasm-rujira-fin/order.withdraw`)."

  alias Rujira.Amount
  alias Rujira.Fin.Events.Price

  defstruct owner: nil, side: :base, price: nil, amount: 0

  @type t :: %__MODULE__{
          owner: String.t(),
          side: :base | :quote,
          price: Price.t(),
          amount: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"owner" => owner, "side" => side, "price" => price, "amount" => amount}) do
    with {:ok, price} <- Price.parse(price),
         {:ok, amount} <- Amount.new(amount) do
      {:ok,
       %__MODULE__{
         owner: owner,
         side: side |> String.downcase() |> String.to_existing_atom(),
         price: price,
         amount: amount
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
