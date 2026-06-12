defmodule Rujira.Thorchain.Events.Swap do
  @moduledoc "A THORChain pool swap event (`swap`)."

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
            emit_asset: nil,
            swap_target: 0,
            swap_slip: 0,
            liquidity_fee: 0,
            liquidity_fee_in_rune: 0,
            pool_slip: 0,
            streaming_swap_quantity: 0,
            streaming_swap_count: 0,
            synth_units: nil

  @type t :: %__MODULE__{
          pool: String.t(),
          id: String.t(),
          chain: String.t(),
          from: String.t(),
          to: String.t(),
          memo: String.t(),
          coin: Coin.t(),
          emit_asset: Coin.t(),
          swap_target: Amount.t(),
          swap_slip: integer(),
          liquidity_fee: Amount.t(),
          liquidity_fee_in_rune: Amount.t(),
          pool_slip: integer(),
          streaming_swap_quantity: integer(),
          streaming_swap_count: integer(),
          synth_units: Amount.t() | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(
        %{
          "pool" => pool,
          "id" => id,
          "chain" => chain,
          "from" => from,
          "to" => to,
          "memo" => memo,
          "coin" => coin,
          "emit_asset" => emit_asset,
          "swap_target" => swap_target,
          "swap_slip" => swap_slip,
          "liquidity_fee" => liquidity_fee,
          "liquidity_fee_in_rune" => liquidity_fee_in_rune,
          "pool_slip" => pool_slip,
          "streaming_swap_quantity" => streaming_swap_quantity,
          "streaming_swap_count" => streaming_swap_count
        } = attrs
      ) do
    with {:ok, coins} <- Coin.parse(coin),
         {:ok, emit} <- Coin.parse(emit_asset),
         {:ok, swap_target} <- Amount.new(swap_target),
         {:ok, swap_slip} <- Math.to_integer(swap_slip),
         {:ok, liquidity_fee} <- Amount.new(liquidity_fee),
         {:ok, liquidity_fee_in_rune} <- Amount.new(liquidity_fee_in_rune),
         {:ok, pool_slip} <- Math.to_integer(pool_slip),
         {:ok, streaming_swap_quantity} <- Math.to_integer(streaming_swap_quantity),
         {:ok, streaming_swap_count} <- Math.to_integer(streaming_swap_count),
         {:ok, synth_units} <- Amount.new(Map.get(attrs, "synth_units")) do
      {:ok,
       %__MODULE__{
         pool: pool,
         id: id,
         chain: chain,
         from: from,
         to: to,
         memo: memo,
         coin: List.first(coins),
         emit_asset: List.first(emit),
         swap_target: swap_target,
         swap_slip: swap_slip,
         liquidity_fee: liquidity_fee,
         liquidity_fee_in_rune: liquidity_fee_in_rune,
         pool_slip: pool_slip,
         streaming_swap_quantity: streaming_swap_quantity,
         streaming_swap_count: streaming_swap_count,
         synth_units: synth_units
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
