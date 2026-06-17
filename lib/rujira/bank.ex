defmodule Rujira.Bank do
  @moduledoc """
  Cosmos bank-module queries against the connected node.
  """

  alias Cosmos.Bank.V1beta1.Query.Stub
  alias Cosmos.Bank.V1beta1.QueryBalanceRequest
  alias Rujira.Amount

  @doc "Fetches an account's balance of a single denom, as a bare integer amount."
  @spec balance(String.t(), String.t()) :: {:ok, Amount.t()} | {:error, term()}
  def balance(address, denom) do
    with {:ok, %{balance: balance}} <-
           Rujira.Node.query(&Stub.balance/2, %QueryBalanceRequest{address: address, denom: denom}) do
      Amount.new(amount(balance))
    end
  end

  defp amount(%{amount: amount}), do: amount
  defp amount(_), do: 0
end
