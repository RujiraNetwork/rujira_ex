defmodule Rujira.Thorchain.Events.Bond do
  @moduledoc "A THORChain bond/rebond event."

  alias Rujira.Amount

  defstruct type: nil, amount: 0, bond_type: nil

  @type t :: %__MODULE__{
          type: :bond | :rebond,
          amount: Amount.t() | nil,
          bond_type: String.t() | nil
        }

  @spec new(atom(), map()) :: {:ok, t()} | {:error, term()}
  def new(type, attrs) when type in [:bond, :rebond] do
    with {:ok, amount} <- Amount.new(Map.get(attrs, "amount")) do
      {:ok,
       %__MODULE__{
         type: type,
         amount: amount,
         bond_type: Map.get(attrs, "bond_type")
       }}
    end
  end

  def new(_, _), do: {:error, :invalid_attrs}
end
