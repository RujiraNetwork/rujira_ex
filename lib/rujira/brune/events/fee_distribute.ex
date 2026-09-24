defmodule Rujira.Brune.Events.FeeDistribute do
  @moduledoc "A revenue fee distribution event (`wasm-rujira-brune/fee.distribute`)."

  alias Rujira.Amount

  defstruct amount: 0

  @type t :: %__MODULE__{amount: Amount.t()}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"amount" => amount}) do
    with {:ok, amount} <- Amount.new(amount) do
      {:ok, %__MODULE__{amount: amount}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
