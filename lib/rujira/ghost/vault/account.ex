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
  alias Rujira.Node

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

  @spec load(Vault.t(), String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def load(%Vault{} = vault, account, opts \\ []) do
    with {:ok, vault} <- Status.load(vault, opts),
         {:ok, asset} <- Assets.from_denom(vault.receipt_denom, opts),
         {:ok, %{amount: shares}} <- Bank.balance(account, asset, opts) do
      {:ok, new(vault, account, shares)}
    else
      {:error, err} -> unless_height_error(err, fn -> {:ok, new(vault, account)} end)
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

  # --- Private ---

  defp value(%Vault{status: %{deposit_pool: %{ratio: ratio}}}, shares) when shares > 0,
    do: Math.mul_floor(shares, ratio)

  defp value(_vault, _shares), do: 0

  # A height read that could not be served is an error, never a default: the
  # caller asked for the state at one height and must be told that height was
  # not read. Every other error keeps today's behaviour.
  defp unless_height_error({:height_unavailable, _} = err, _fallback), do: {:error, err}
  defp unless_height_error({:height_mismatch, _, _} = err, _fallback), do: {:error, err}
  defp unless_height_error(:invalid_height, _fallback), do: {:error, :invalid_height}
  defp unless_height_error(:height_not_supported, _fallback), do: {:error, :height_not_supported}
  defp unless_height_error(_err, fallback), do: fallback.()
end
