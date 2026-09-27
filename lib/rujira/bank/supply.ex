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
  alias Rujira.Node

  # --- Queries ---

  @doc "Fetches the total supply of a single asset, at `opts[:height]` when one is given."
  @spec get(Asset.t(), Node.opts()) :: {:ok, Coin.t()} | {:error, term()}
  def get(%Asset{} = asset, opts \\ []) do
    with {:ok, denom} <- Assets.to_native(asset),
         {:ok, response} <-
           Node.query(&Stub.supply_of/3, %QuerySupplyOfRequest{denom: denom}, opts),
         {:ok, chain_amount} <- supply_amount(response),
         {:ok, amount} <- Amount.new(chain_amount) do
      {:ok, Coin.new(asset, amount)}
    end
  end

  @doc "Fetches the total supply of every denom, at `opts[:height]` when one is given."
  @spec list(Node.opts()) :: {:ok, [Coin.t()]} | {:error, term()}
  def list(opts \\ []), do: total_supply(nil, opts)

  # --- Private ---

  # The node always populates `amount` for a valid `denom` - a genuinely
  # unminted asset still comes back as a `Coin` with amount `"0"`. A `nil`
  # amount is a malformed response, not a real chain value.
  defp supply_amount(%{amount: %{amount: amount}}), do: {:ok, amount}
  defp supply_amount(_), do: {:error, :invalid_response}

  defp total_supply("", _opts), do: {:ok, []}

  defp total_supply(key, opts) do
    with {:ok, %{supply: supply, pagination: %{next_key: next_key}}} <-
           Node.query(&Stub.total_supply/3, total_supply_request(key), opts),
         {:ok, coins} <- coins_to_coins(supply),
         {:ok, next} <- total_supply(next_key, opts) do
      {:ok, coins ++ next}
    end
  end

  defp total_supply_request(nil), do: %QueryTotalSupplyRequest{}

  defp total_supply_request(key),
    do: %QueryTotalSupplyRequest{pagination: %PageRequest{key: key}}

  defp coins_to_coins(coins), do: Rujira.Enum.reduce_while_ok(coins, &Coin.new/1)
end
