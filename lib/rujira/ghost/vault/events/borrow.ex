defmodule Rujira.Ghost.Vault.Events.Borrow do
  @moduledoc "A Ghost vault borrow event (`wasm-rujira-ghost-vault/borrow`)."

  alias Rujira.Amount
  alias Rujira.Math

  defstruct borrower: nil, delegate: nil, amount: 0, shares: Decimal.new(0)

  @type t :: %__MODULE__{
          borrower: String.t(),
          delegate: String.t() | nil,
          amount: Amount.t(),
          shares: Decimal.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"borrower" => borrower, "amount" => amount, "shares" => shares} = attrs) do
    with {:ok, amount} <- Amount.new(amount),
         {:ok, shares} <- Math.to_decimal(shares) do
      {:ok,
       %__MODULE__{
         borrower: borrower,
         delegate: delegate(Map.get(attrs, "delegate")),
         amount: amount,
         shares: shares
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  defp delegate(nil), do: nil
  defp delegate(""), do: nil
  defp delegate(delegate), do: delegate
end
