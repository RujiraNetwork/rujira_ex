defmodule Rujira.Fin.Events.RangeDeposit do
  @moduledoc "A range deposit event (`wasm-rujira-fin/range.deposit`)."

  alias Rujira.Math

  defstruct [:idx, :owner]

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
end
