defmodule Rujira.Thorchain.Events.Withdraw do
  @moduledoc "A THORChain withdraw event (`withdraw`)."

  alias Rujira.Amount
  alias Rujira.Coin
  alias Rujira.Math

  defstruct pool: nil,
            id: nil,
            chain: nil,
            from: nil,
            to: nil,
            memo: nil,
            coin: nil,
            liquidity_provider_units: 0,
            basis_points: 0,
            asymmetry: Decimal.new(0),
            emit_asset: 0,
            emit_rune: 0

  @type t :: %__MODULE__{
          pool: String.t(),
          id: String.t(),
          chain: String.t(),
          from: String.t(),
          to: String.t(),
          memo: String.t(),
          coin: Coin.t(),
          liquidity_provider_units: Amount.t(),
          basis_points: integer(),
          asymmetry: Decimal.t(),
          emit_asset: Amount.t(),
          emit_rune: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "pool" => pool,
        "id" => id,
        "chain" => chain,
        "from" => from,
        "to" => to,
        "memo" => memo,
        "coin" => coin,
        "liquidity_provider_units" => units,
        "basis_points" => basis_points,
        "asymmetry" => asymmetry,
        "emit_asset" => emit_asset,
        "emit_rune" => emit_rune
      }) do
    with {:ok, coins} <- Coin.parse(coin),
         {:ok, units} <- Amount.new(units),
         {:ok, basis_points} <- Math.to_integer(basis_points),
         {:ok, asymmetry} <- Math.to_decimal(asymmetry),
         {:ok, emit_asset} <- Amount.new(emit_asset),
         {:ok, emit_rune} <- Amount.new(emit_rune) do
      {:ok,
       %__MODULE__{
         pool: pool,
         id: id,
         chain: chain,
         from: from,
         to: to,
         memo: memo,
         coin: List.first(coins),
         liquidity_provider_units: units,
         basis_points: basis_points,
         asymmetry: asymmetry,
         emit_asset: emit_asset,
         emit_rune: emit_rune
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
