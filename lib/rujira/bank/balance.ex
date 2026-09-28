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
  alias Rujira.Cache
  alias Rujira.Coin
  alias Rujira.Node

  # --- Queries ---

  @doc """
  Fetches an account's balance of a single asset. Amount is 0 when the chain
  reports a real zero balance (a `Coin` with amount `"0"`). Cached per
  `Rujira.Cache`, resolved at `opts[:height]` or, without one, at the head.
  """
  @spec get(String.t(), Asset.t(), Node.opts()) :: {:ok, Coin.t()} | {:error, term()}
  def get(address, %Asset{} = asset, opts \\ []) do
    with {:ok, denom} <- Assets.to_native(asset),
         {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch(
        {__MODULE__, :get, [address, denom]},
        [{:balance, address}],
        opts,
        fn _height -> fetch_get(address, denom, asset, opts) end
      )
    end
  end

  @doc """
  Fetches all of an account's balances. Cached per `Rujira.Cache`, resolved at
  `opts[:height]` or, without one, at the head.
  """
  @spec list(String.t(), Node.opts()) :: {:ok, [Coin.t()]} | {:error, term()}
  def list(address, opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch(
        {__MODULE__, :list, [address]},
        [{:balance, address}],
        opts,
        fn _height -> all_balances(address, nil, opts) end
      )
    end
  end

  @doc """
  Fetches an account's spendable balances (excluding locked/vesting amounts).
  Cached per `Rujira.Cache`, resolved at `opts[:height]` or, without one, at
  the head.
  """
  @spec list_spendable(String.t(), Node.opts()) :: {:ok, [Coin.t()]} | {:error, term()}
  def list_spendable(address, opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch(
        {__MODULE__, :list_spendable, [address]},
        [{:balance, address}, :per_block],
        opts,
        fn _height -> spendable_balances(address, nil, opts) end
      )
    end
  end

  # --- Private ---

  defp fetch_get(address, denom, asset, opts) do
    with {:ok, response} <-
           Node.query(
             &Stub.balance/3,
             %QueryBalanceRequest{address: address, denom: denom},
             opts
           ),
         {:ok, chain_amount} <- balance_amount(response),
         {:ok, amount} <- Amount.new(chain_amount) do
      {:ok, Coin.new(asset, amount)}
    end
  end

  # The node always populates `balance` for a valid `denom` - a real zero
  # balance still comes back as a `Coin` with amount `"0"`. A `nil` balance is
  # a malformed response, not a real chain value.
  defp balance_amount(%{balance: %{amount: amount}}), do: {:ok, amount}
  defp balance_amount(_), do: {:error, :invalid_response}

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

  defp coins_to_coins(coins), do: Rujira.Enum.reduce_while_ok(coins, &Coin.new/1)
end
