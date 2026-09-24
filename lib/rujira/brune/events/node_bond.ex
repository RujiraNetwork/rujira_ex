defmodule Rujira.Brune.Events.NodeBond do
  @moduledoc "A node bond event (`wasm-rujira-brune/node.bond`)."

  alias Rujira.Amount

  defstruct node: nil, amount: 0

  @type t :: %__MODULE__{node: String.t(), amount: Amount.t()}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"node" => node, "amount" => amount}) do
    with {:ok, amount} <- Amount.new(amount) do
      {:ok, %__MODULE__{node: node, amount: amount}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
