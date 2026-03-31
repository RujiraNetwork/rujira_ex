defmodule Rujira.Fin.Events.RangeFee do
  @moduledoc "A range fee accrual event (`wasm-rujira-fin/range.fee`)."

  alias Rujira.Math

  defstruct [:contract, :idx]

  @type t :: %__MODULE__{
          contract: String.t(),
          idx: non_neg_integer()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"_contract_address" => contract, "idx" => idx}) do
    with {:ok, idx} <- Math.to_integer(idx) do
      {:ok, %__MODULE__{contract: contract, idx: idx}}
    end
  end
end
