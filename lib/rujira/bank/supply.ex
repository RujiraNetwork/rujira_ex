defmodule Rujira.Bank.Supply do
  @moduledoc "The total on-chain supply of an asset. Use `Rujira.Bank` as the public API."

  alias Cosmos.Bank.V1beta1.Query.Stub
  alias Cosmos.Bank.V1beta1.QuerySupplyOfRequest
  alias Cosmos.Bank.V1beta1.QueryTotalSupplyRequest
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Coin
  alias Rujira.Logger

  # --- Queries ---

  @doc "Fetches the total supply of a single asset."
  @spec get(Asset.t()) :: {:ok, Coin.t()} | {:error, term()}
  def get(%Asset{} = asset) do
    with {:ok, denom} <- Assets.to_native(asset),
         {:ok, %{amount: coin}} <-
           Rujira.Node.query(&Stub.supply_of/2, %QuerySupplyOfRequest{denom: denom}),
         {:ok, amount} <- Amount.new(coin_amount(coin)) do
      {:ok, Coin.new(asset, amount)}
    end
  end

  @doc "Fetches the total supply of every denom."
  @spec list() :: {:ok, [Coin.t()]} | {:error, term()}
  def list, do: total_supply()

  # --- Private ---

  defp coin_amount(%{amount: amount}), do: amount
  defp coin_amount(_), do: 0

  defp total_supply(key \\ nil)
  defp total_supply(""), do: {:ok, []}

  defp total_supply(key) do
    with {:ok, %{supply: supply, pagination: %{next_key: next_key}}} <-
           Rujira.Node.query(&Stub.total_supply/2, total_supply_request(key)),
         {:ok, coins} <- coins_to_coins(supply),
         {:ok, next} <- total_supply(next_key) do
      {:ok, coins ++ next}
    end
  end

  defp total_supply_request(nil), do: %QueryTotalSupplyRequest{}

  defp total_supply_request(key),
    do: %QueryTotalSupplyRequest{pagination: %PageRequest{key: key}}

  defp coins_to_coins(coins), do: Rujira.Enum.reduce_while_ok(coins, &to_coin/1)

  # One unrecognised denom must not fail the whole list: log and skip it.
  defp to_coin(coin), do: skip_invalid_denom(Coin.new(coin), coin)

  defp skip_invalid_denom({:error, :invalid_denom}, %{denom: denom}) do
    Logger.warning(__MODULE__, "skipping unrecognised denom #{inspect(denom)}")
    :skip
  end

  defp skip_invalid_denom(result, _coin), do: result
end
