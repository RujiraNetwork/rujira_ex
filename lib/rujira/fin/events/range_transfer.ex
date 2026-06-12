defmodule Rujira.Fin.Events.RangeTransfer do
  @moduledoc "A range ownership transfer event (`wasm-rujira-fin/range.transfer`)."

  alias Rujira.Math

  defstruct idx: 0, from: nil, to: nil

  @type t :: %__MODULE__{
          idx: non_neg_integer(),
          from: String.t(),
          to: String.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"idx" => idx, "from" => from, "to" => to}) do
    with {:ok, idx} <- Math.to_integer(idx) do
      {:ok, %__MODULE__{idx: idx, from: from, to: to}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
