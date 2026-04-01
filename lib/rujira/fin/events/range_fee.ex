defmodule Rujira.Fin.Events.RangeFee do
  @moduledoc "A range fee accrual event (`wasm-rujira-fin/range.fee`)."

  alias Rujira.Math

  defstruct [:idx]

  @type t :: %__MODULE__{
          idx: non_neg_integer()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"idx" => idx}) do
    with {:ok, idx} <- Math.to_integer(idx) do
      {:ok, %__MODULE__{idx: idx}}
    end
  end
end
