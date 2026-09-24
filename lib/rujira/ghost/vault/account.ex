defmodule Rujira.Ghost.Vault.Account do
  @moduledoc """
  A user's deposit position in a Ghost vault: receipt-token shares and their
  current redeemable value.

  Struct, construction, and queries. Use `Rujira.Ghost` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Bank
  alias Rujira.Ghost.Vault
  alias Rujira.Ghost.Vault.Status
  alias Rujira.Math

  # --- Struct ---

  defstruct id: nil, account: nil, vault: nil, shares: 0, value: 0

  @type t :: %__MODULE__{
          id: String.t() | nil,
          account: String.t() | nil,
          vault: Vault.t() | nil,
          shares: Amount.t(),
          value: Amount.t()
        }

  # --- Construction ---

  @spec new(Vault.t(), String.t(), Amount.t()) :: t()
  def new(%Vault{address: address} = vault, account, shares \\ 0) do
    %__MODULE__{
      id: "#{address}/#{account}",
      account: account,
      vault: vault,
      shares: shares,
      value: value(vault, shares)
    }
  end

  # --- Queries ---

  @spec load(Vault.t(), String.t()) :: {:ok, t()} | {:error, term()}
  def load(%Vault{} = vault, account) do
    with {:ok, vault} <- Status.load(vault),
         {:ok, asset} <- Assets.from_denom(vault.receipt_denom),
         {:ok, %{amount: shares}} <- Bank.balance(account, asset) do
      {:ok, new(vault, account, shares)}
    else
      _ -> {:ok, new(vault, account)}
    end
  end

  @spec from_id(String.t()) :: {:ok, t()} | {:error, term()}
  def from_id(id) do
    with [address, account] <- String.split(id, "/"),
         {:ok, vault} <- Vault.get(address) do
      load(vault, account)
    else
      {:error, _} = err -> err
      _ -> {:error, :invalid_id}
    end
  end

  # --- Private ---

  defp value(%Vault{status: %{deposit_pool: %{ratio: ratio}}}, shares) when shares > 0,
    do: Math.mul_floor(shares, ratio)

  defp value(_vault, _shares), do: 0
end
