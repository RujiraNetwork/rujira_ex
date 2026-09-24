defmodule Rujira.Staking.Events.AccountBond do
  @moduledoc "A staking account bond event (`wasm-rujira-staking/account.bond`)."

  alias Rujira.Amount

  defstruct owner: nil, amount: 0

  @type t :: %__MODULE__{
          owner: String.t(),
          amount: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"owner" => owner, "amount" => amount}) do
    with {:ok, amount} <- Amount.new(amount) do
      {:ok, %__MODULE__{owner: owner, amount: amount}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
