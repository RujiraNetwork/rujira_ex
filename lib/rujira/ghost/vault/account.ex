defmodule Rujira.Ghost.Vault.Account do
  @moduledoc """
  A user's deposit position in a Ghost vault: the receipt-token shares the
  account holds.

  The shares are the whole position - what they redeem for is `value/2`, pure
  over a vault whose `status` is loaded.

  Struct, construction, and queries. Use `Rujira.Ghost` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Bank
  alias Rujira.Ghost.Vault
  alias Rujira.Ghost.Vault.Status
  alias Rujira.Ghost.Vault.Status.DepositPool
  alias Rujira.Math
  alias Rujira.Node

  # --- Struct ---

  defstruct id: nil, account: nil, vault: nil, shares: 0

  @type t :: %__MODULE__{
          id: String.t() | nil,
          account: String.t() | nil,
          vault: Vault.t() | nil,
          shares: Amount.t()
        }

  # --- Construction ---

  @spec new(Vault.t(), String.t(), Amount.t()) :: t()
  def new(%Vault{address: address} = vault, account, shares) do
    %__MODULE__{
      id: "#{address}/#{account}",
      account: account,
      vault: vault,
      shares: shares
    }
  end

  # --- Queries ---

  @doc """
  Reads the account's receipt-token balance, at `opts[:height]` when one is
  given.
  """
  @spec load(Vault.t(), String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def load(%Vault{receipt_asset: receipt_asset} = vault, account, opts \\ []) do
    with {:ok, %{amount: shares}} <- Bank.balance(account, receipt_asset, opts) do
      {:ok, new(vault, account, shares)}
    end
  end

  @spec from_id(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def from_id(id, opts \\ []) do
    with [address, account] <- String.split(id, "/"),
         {:ok, vault} <- Vault.get(address, opts) do
      load(vault, account, opts)
    else
      {:error, _} = err -> err
      _ -> {:error, :invalid_id}
    end
  end

  # --- Calculations ---

  @doc """
  What the account's shares redeem for, at the vault's deposit-pool ratio.

  Pure over a vault whose `status` is loaded - `{:error, :not_loaded}` otherwise.
  """
  @spec value(t(), Vault.t()) :: {:ok, Amount.t()} | {:error, :not_loaded}
  def value(%__MODULE__{}, %Vault{status: :not_loaded}), do: {:error, :not_loaded}

  def value(%__MODULE__{shares: 0}, %Vault{}), do: {:ok, 0}

  def value(%__MODULE__{shares: shares}, %Vault{
        status: %Status{deposit_pool: %DepositPool{ratio: ratio}}
      }),
      do: {:ok, Math.mul_floor(shares, ratio)}
end
