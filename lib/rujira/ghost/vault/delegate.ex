defmodule Rujira.Ghost.Vault.Delegate do
  @moduledoc "A delegated debt obligation on a Ghost vault."

  alias Rujira.Amount
  alias Rujira.Ghost.Vault.Borrower
  alias Rujira.Math

  defstruct borrower: nil, address: nil, current: 0, shares: Decimal.new(0)

  @type t :: %__MODULE__{
          borrower: Borrower.t() | nil,
          address: String.t() | nil,
          current: Amount.t(),
          shares: Decimal.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"borrower" => borrower, "addr" => addr, "current" => current, "shares" => shares}) do
    with {:ok, borrower} <- Borrower.new(borrower),
         {:ok, current} <- Amount.new(current),
         {:ok, shares} <- Math.to_decimal(shares) do
      {:ok, %__MODULE__{borrower: borrower, address: addr, current: current, shares: shares}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
