defmodule Rujira.Ghost.Vault.Events.Deposit do
  @moduledoc "A Ghost vault deposit event (`wasm-rujira-ghost-vault/deposit`)."

  alias Rujira.Amount

  defstruct owner: nil, amount: 0, shares: 0

  @type t :: %__MODULE__{
          owner: String.t(),
          amount: Amount.t(),
          shares: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"owner" => owner, "amount" => amount, "shares" => shares}) do
    with {:ok, amount} <- Amount.new(amount),
         {:ok, shares} <- Amount.new(shares) do
      {:ok, %__MODULE__{owner: owner, amount: amount, shares: shares}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
