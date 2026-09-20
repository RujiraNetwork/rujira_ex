defmodule Rujira.Ghost.Vault.Events.Repay do
  @moduledoc "A Ghost vault repay event (`wasm-rujira-ghost-vault/repay`)."

  alias Rujira.Amount
  alias Rujira.Math
  alias Rujira.String

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
         delegate: String.nil_if_empty(Map.get(attrs, "delegate")),
         amount: amount,
         shares: shares
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
