defmodule Rujira.Fin.Events.Submit do
  @moduledoc "An order submission event (`wasm-rujira-fin/submit`)."

  defstruct side: nil, price: nil, owner: nil

  @type t :: %__MODULE__{
          side: :base | :quote,
          price: String.t(),
          owner: String.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"side" => side, "price" => price, "owner" => owner}) do
    {:ok,
     %__MODULE__{
       side: side |> String.downcase() |> String.to_existing_atom(),
       price: price,
       owner: owner
     }}
  end
end
