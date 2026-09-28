defmodule Rujira.Bank.Supply do
  @moduledoc "The total on-chain supply of an asset. Use `Rujira.Bank` as the public API."

  alias Cosmos.Bank.V1beta1.Query.Stub
  alias Cosmos.Bank.V1beta1.QuerySupplyOfRequest
  alias Cosmos.Bank.V1beta1.QueryTotalSupplyRequest
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Cache
  alias Rujira.Coin
  alias Rujira.Node

  # --- Queries ---

  @doc """
  Fetches the total supply of a single asset. Cached per `Rujira.Cache`,
  resolved at `opts[:height]` or, without one, at the head.
  """
  @spec get(Asset.t(), Node.opts()) :: {:ok, Coin.t()} | {:error, term()}
  def get(%Asset{} = asset, opts \\ []) do
    with {:ok, denom} <- Assets.to_native(asset),
         {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch(
        {__MODULE__, :get, [denom]},
        [{:denom_transfers, denom}],
        opts,
        fn _height -> fetch_get(denom, asset, opts) end
      )
    end
  end

  @doc """
  Fetches the total supply of every denom. Cached per `Rujira.Cache` against
  `:per_block`, resolved at `opts[:height]` or, without one, at the head - no
  single tag covers every denom's supply changing, so this reads fresh every
  block rather than carrying over.
  """
  @spec list(Node.opts()) :: {:ok, [Coin.t()]} | {:error, term()}
  def list(opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch({__MODULE__, :list, []}, [:per_block], opts, fn _height ->
        total_supply(nil, opts)
      end)
    end
  end

  # --- Private ---

  defp fetch_get(denom, asset, opts) do
    with {:ok, response} <-
           Node.query(&Stub.supply_of/3, %QuerySupplyOfRequest{denom: denom}, opts),
         {:ok, chain_amount} <- supply_amount(response),
         {:ok, amount} <- Amount.new(chain_amount) do
      {:ok, Coin.new(asset, amount)}
    end
  end

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
