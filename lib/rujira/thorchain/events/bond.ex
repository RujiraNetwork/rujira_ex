defmodule Rujira.Thorchain.Events.Bond do
  @moduledoc "A THORChain bond event (`bond`)."

  alias Rujira.Amount
  alias Rujira.Coin

  defstruct amount: 0,
            bond_type: nil,
            node_address: nil,
            bond_address: nil,
            id: nil,
            chain: nil,
            from: nil,
            to: nil,
            memo: nil,
            coin: nil

  @type t :: %__MODULE__{
          amount: Amount.t(),
          bond_type: String.t(),
          node_address: String.t(),
          bond_address: String.t(),
          id: String.t(),
          chain: String.t(),
          from: String.t(),
          to: String.t(),
          memo: String.t(),
          coin: Coin.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "amount" => amount,
        "bond_type" => bond_type,
        "node_address" => node_address,
        "bond_address" => bond_address,
        "id" => id,
        "chain" => chain,
        "from" => from,
        "to" => to,
        "memo" => memo,
        "coin" => coin
      }) do
    with {:ok, amount} <- Amount.new(amount),
         {:ok, coins} <- Coin.from_asset_string(coin) do
      {:ok,
       %__MODULE__{
         amount: amount,
         bond_type: bond_type,
         node_address: node_address,
         bond_address: bond_address,
         id: id,
         chain: chain,
         from: from,
         to: to,
         memo: memo,
         coin: List.first(coins)
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
