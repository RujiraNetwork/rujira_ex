defmodule Rujira.Staking.Events.AccountWithdraw do
  @moduledoc "A staking account withdraw event (`wasm-rujira-staking/account.withdraw`)."

  alias Rujira.Amount

  defstruct owner: nil, amount: 0, rewards: 0

  @type t :: %__MODULE__{
          owner: String.t(),
          amount: Amount.t(),
          rewards: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"owner" => owner, "amount" => amount, "rewards" => rewards}) do
    with {:ok, amount} <- Amount.new(amount),
         {:ok, rewards} <- Amount.new(rewards) do
      {:ok, %__MODULE__{owner: owner, amount: amount, rewards: rewards}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
