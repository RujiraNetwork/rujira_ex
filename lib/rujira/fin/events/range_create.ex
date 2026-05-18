defmodule Rujira.Fin.Events.RangeCreate do
  @moduledoc "A range creation event (`wasm-rujira-fin/range.create`)."

  alias Rujira.Math

  defstruct idx: 0, owner: nil

  @type t :: %__MODULE__{
          idx: non_neg_integer(),
          owner: String.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"idx" => idx, "owner" => owner}) do
    with {:ok, idx} <- Math.to_integer(idx) do
      {:ok, %__MODULE__{idx: idx, owner: owner}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
