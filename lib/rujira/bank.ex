defmodule Rujira.Bank do
  @moduledoc """
  Cosmos bank-module queries against the connected node.
  """

  alias Cosmos.Bank.V1beta1.Query.Stub
  alias Cosmos.Bank.V1beta1.QueryBalanceRequest
  alias Cosmos.Bank.V1beta1.QueryDenomOwnersRequest
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Rujira.Amount
  alias Rujira.Bank.Holder

  use Memoize

  @holders_limit 100

  @doc "Fetches an account's balance of a single denom, as a bare integer amount."
  @spec balance(String.t(), String.t()) :: {:ok, Amount.t()} | {:error, term()}
  def balance(address, denom) do
    with {:ok, %{balance: balance}} <-
           Rujira.Node.query(&Stub.balance/2, %QueryBalanceRequest{address: address, denom: denom}) do
      Amount.new(amount(balance))
    end
  end

  @doc """
  Memoized list of the top holders of a denom, sorted by balance descending.

  Invalidate with `Memoize.invalidate(Rujira.Bank, :holders, [denom, limit])`.
  """
  @spec holders(String.t(), pos_integer()) :: {:ok, [Holder.t()]} | {:error, term()}
  defmemo holders(denom, limit \\ @holders_limit), expires_in: :timer.hours(1) do
    with {:ok, owners} <- denom_owners(denom),
         {:ok, holders} <- Rujira.Enum.reduce_while_ok(owners, &Holder.new/1) do
      {:ok, holders |> Enum.sort_by(& &1.amount, :desc) |> Enum.take(limit)}
    end
  end

  # --- Private ---

  defp amount(%{amount: amount}), do: amount
  defp amount(_), do: 0

  defp denom_owners(denom, key \\ nil)
  defp denom_owners(_denom, ""), do: {:ok, []}

  defp denom_owners(denom, key) do
    with {:ok, %{denom_owners: owners, pagination: %{next_key: next_key}}} <-
           Rujira.Node.query(&Stub.denom_owners/2, request(denom, key)),
         {:ok, next} <- denom_owners(denom, next_key) do
      {:ok, owners ++ next}
    end
  end

  defp request(denom, nil), do: %QueryDenomOwnersRequest{denom: denom}

  defp request(denom, key),
    do: %QueryDenomOwnersRequest{denom: denom, pagination: %PageRequest{key: key}}
end
