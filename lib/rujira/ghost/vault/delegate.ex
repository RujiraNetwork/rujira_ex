defmodule Rujira.Ghost.Vault.Delegate do
  @moduledoc """
  A delegated debt obligation on a Ghost vault.

  Struct, construction, and queries. Use `Rujira.Ghost` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Contracts
  alias Rujira.Ghost.Vault.Borrower
  alias Rujira.Math

  use Memoize

  # --- Struct ---

  defstruct borrower: nil, address: nil, current: 0, shares: Decimal.new(0)

  @type t :: %__MODULE__{
          borrower: Borrower.t() | nil,
          address: String.t() | nil,
          current: Amount.t(),
          shares: Decimal.t()
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"borrower" => borrower, "addr" => addr, "current" => current, "shares" => shares}) do
    with {:ok, borrower} <- Borrower.new(borrower),
         {:ok, current} <- Amount.new(current),
         {:ok, shares} <- Math.to_decimal(shares) do
      {:ok, %__MODULE__{borrower: borrower, address: addr, current: current, shares: shares}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Queries ---

  @spec get(String.t(), String.t(), String.t()) :: {:ok, t()} | {:error, term()}
  def get(vault, borrower, address) do
    with {:ok, res} <- query(vault, borrower, address) do
      new(res)
    end
  end

  @doc """
  Memoized fetch of a delegate's raw position on a vault.

  Invalidate with `Memoize.invalidate(Rujira.Ghost.Vault.Delegate, :query, [vault, borrower, address])`.
  """
  @spec query(String.t(), String.t(), String.t()) :: {:ok, map()} | {:error, term()}
  defmemo query(vault, borrower, address) do
    Contracts.query_state_smart(vault, %{delegate: %{borrower: borrower, addr: address}})
  end
end
