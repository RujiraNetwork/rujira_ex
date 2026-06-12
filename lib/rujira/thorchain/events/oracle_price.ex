defmodule Rujira.Thorchain.Events.OraclePrice do
  @moduledoc "A THORChain oracle price update event."

  alias Rujira.Math

  defstruct symbol: nil, price: Decimal.new(0)

  @type t :: %__MODULE__{
          symbol: String.t(),
          price: Decimal.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"symbol" => symbol, "price" => price}) do
    with {:ok, price} <- Math.to_decimal(price) do
      {:ok, %__MODULE__{symbol: symbol, price: price}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
