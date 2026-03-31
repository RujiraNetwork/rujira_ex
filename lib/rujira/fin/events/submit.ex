defmodule Rujira.Fin.Events.Submit do
  @moduledoc "An order submission event (`wasm-rujira-fin/submit`)."

  defstruct [:contract, :side, :price, :owner]

  @type t :: %__MODULE__{
          contract: String.t(),
          side: :base | :quote,
          price: String.t(),
          owner: String.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"_contract_address" => contract, "side" => side, "price" => price, "owner" => owner}) do
    {:ok,
     %__MODULE__{
       contract: contract,
       side: side(side),
       price: price,
       owner: owner
     }}
  end

  defp side("Base"), do: :base
  defp side("Quote"), do: :quote
  defp side(s), do: s
end
