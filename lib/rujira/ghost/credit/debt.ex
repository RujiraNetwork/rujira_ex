defmodule Rujira.Ghost.Credit.Debt do
  @moduledoc """
  One debt of a credit account: the credit contract's delegated borrow position
  on a Ghost vault, and the value the contract reports for it.

  The delegate is a `Rujira.Ghost.Vault.Delegate` - the same shape the vault
  serves. Use `Rujira.Ghost` as the public API.
  """

  alias Rujira.Ghost.Vault.Delegate
  alias Rujira.Math

  # --- Struct ---

  defstruct delegate: nil, value: Decimal.new(0)

  @type t :: %__MODULE__{delegate: Delegate.t() | nil, value: Decimal.t()}

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"debt" => debt, "value" => value}) do
    with {:ok, delegate} <- Delegate.new(debt),
         {:ok, value} <- Math.to_decimal(value) do
      {:ok, %__MODULE__{delegate: delegate, value: value}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
