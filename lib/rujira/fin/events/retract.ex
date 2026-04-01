defmodule Rujira.Fin.Events.Retract do
  @moduledoc "An order retraction event (`wasm-rujira-fin/retract`)."

  defstruct [:side, :price, :owner]

  @type t :: %__MODULE__{
          side: :base | :quote,
          price: String.t(),
          owner: String.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"side" => side, "price" => price, "owner" => owner}) do
    {:ok,
     %__MODULE__{
       side: side(side),
       price: price,
       owner: owner
     }}
  end

  defp side("Base"), do: :base
  defp side("Quote"), do: :quote
  defp side(s), do: s
end
