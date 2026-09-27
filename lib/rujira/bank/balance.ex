defmodule Rujira.Bank.Balance do
  @moduledoc "Coin balances of a Cosmos account. Use `Rujira.Bank` as the public API."

  alias Cosmos.Bank.V1beta1.Query.Stub
  alias Cosmos.Bank.V1beta1.QueryAllBalancesRequest
  alias Cosmos.Bank.V1beta1.QueryBalanceRequest
  alias Cosmos.Bank.V1beta1.QuerySpendableBalancesRequest
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Coin
  alias Rujira.Logger
  alias Rujira.Node

  # --- Queries ---

  @doc """
  Fetches an account's balance of a single asset. Amount is 0 when the account
  holds none. Read at `opts[:height]` when one is given.
  """
  @spec get(String.t(), Asset.t(), Node.opts()) :: {:ok, Coin.t()} | {:error, term()}
  def get(address, %Asset{} = asset, opts \\ []) do
    with {:ok, denom} <- Assets.to_native(asset),
         {:ok, %{balance: balance}} <-
           Node.query(
             &Stub.balance/3,
             %QueryBalanceRequest{address: address, denom: denom},
             opts
           ),
         {:ok, amount} <- Amount.new(coin_amount(balance)) do
      {:ok, Coin.new(asset, amount)}
    end
  end

  @doc "Fetches all of an account's balances, at `opts[:height]` when one is given."
  @spec list(String.t(), Node.opts()) :: {:ok, [Coin.t()]} | {:error, term()}
  def list(address, opts \\ []), do: all_balances(address, nil, opts)

  @doc """
  Fetches an account's spendable balances (excluding locked/vesting amounts), at
  `opts[:height]` when one is given.
  """
  @spec list_spendable(String.t(), Node.opts()) :: {:ok, [Coin.t()]} | {:error, term()}
  def list_spendable(address, opts \\ []), do: spendable_balances(address, nil, opts)

  # --- Private ---

  defp coin_amount(%{amount: amount}), do: amount
  defp coin_amount(_), do: 0

  defp all_balances(_address, "", _opts), do: {:ok, []}

  defp all_balances(address, key, opts) do
    with {:ok, %{balances: balances, pagination: %{next_key: next_key}}} <-
           Node.query(&Stub.all_balances/3, all_balances_request(address, key), opts),
         {:ok, coins} <- coins_to_coins(balances),
         {:ok, next} <- all_balances(address, next_key, opts) do
      {:ok, coins ++ next}
    end
  end

  defp all_balances_request(address, nil), do: %QueryAllBalancesRequest{address: address}

  defp all_balances_request(address, key),
    do: %QueryAllBalancesRequest{address: address, pagination: %PageRequest{key: key}}

  defp spendable_balances(_address, "", _opts), do: {:ok, []}

  defp spendable_balances(address, key, opts) do
    with {:ok, %{balances: balances, pagination: %{next_key: next_key}}} <-
           Node.query(
             &Stub.spendable_balances/3,
             spendable_balances_request(address, key),
             opts
           ),
         {:ok, coins} <- coins_to_coins(balances),
         {:ok, next} <- spendable_balances(address, next_key, opts) do
      {:ok, coins ++ next}
    end
  end

  defp spendable_balances_request(address, nil),
    do: %QuerySpendableBalancesRequest{address: address}

  defp spendable_balances_request(address, key),
    do: %QuerySpendableBalancesRequest{address: address, pagination: %PageRequest{key: key}}

  defp coins_to_coins(coins), do: Rujira.Enum.reduce_while_ok(coins, &to_coin/1)

  # One unrecognised denom must not fail the whole list: log and skip it.
  defp to_coin(coin), do: skip_invalid_denom(Coin.new(coin), coin)

  defp skip_invalid_denom({:error, :invalid_denom}, %{denom: denom}) do
    Logger.warning(__MODULE__, "skipping unrecognised denom #{inspect(denom)}")
    :skip
  end

  defp skip_invalid_denom(result, _coin), do: result
end
