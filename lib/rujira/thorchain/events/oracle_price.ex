defmodule Rujira.Thorchain.Events.OraclePrice do
  @moduledoc "A THORChain oracle price update event."

  alias Rujira.Math

  defstruct symbol: nil, price: nil

  @type t :: %__MODULE__{
          symbol: String.t(),
          price: Decimal.t() | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"symbol" => symbol} = attrs) do
    with {:ok, price} <- Math.to_decimal(Map.get(attrs, "price")) do
      {:ok, %__MODULE__{symbol: symbol, price: price}}
    end
  end
end
