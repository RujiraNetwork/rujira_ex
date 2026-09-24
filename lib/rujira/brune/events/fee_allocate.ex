defmodule Rujira.Brune.Events.FeeAllocate do
  @moduledoc "A revenue fee allocation event (`wasm-rujira-brune/fee.allocate`)."

  alias Rujira.Math

  defstruct amount: Decimal.new(0)

  @type t :: %__MODULE__{amount: Decimal.t()}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"amount" => amount}) do
    with {:ok, amount} <- Math.to_decimal(amount) do
      {:ok, %__MODULE__{amount: amount}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
