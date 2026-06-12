defmodule Rujira.Thorchain.Events.Rebond do
  @moduledoc "A THORChain rebond event (`rebond`)."

  alias Rujira.Amount
  alias Rujira.Coin

  defstruct amount: 0,
            node_address: nil,
            old_bond_address: nil,
            new_bond_address: nil,
            id: nil,
            chain: nil,
            from: nil,
            to: nil,
            memo: nil,
            coin: nil

  @type t :: %__MODULE__{
          amount: Amount.t(),
          node_address: String.t(),
          old_bond_address: String.t(),
          new_bond_address: String.t(),
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
        "node_address" => node_address,
        "old_bond_address" => old_bond_address,
        "new_bond_address" => new_bond_address,
        "id" => id,
        "chain" => chain,
        "from" => from,
        "to" => to,
        "memo" => memo,
        "coin" => coin
      }) do
    with {:ok, amount} <- Amount.new(amount),
         {:ok, coins} <- Coin.parse(coin) do
      {:ok,
       %__MODULE__{
         amount: amount,
         node_address: node_address,
         old_bond_address: old_bond_address,
         new_bond_address: new_bond_address,
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
