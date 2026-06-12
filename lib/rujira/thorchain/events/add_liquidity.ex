defmodule Rujira.Thorchain.Events.AddLiquidity do
  @moduledoc "A THORChain add liquidity event (`add_liquidity`)."

  alias Rujira.Amount

  defstruct pool: nil,
            rune_address: nil,
            asset_address: nil,
            liquidity_provider_units: 0,
            rune_amount: 0,
            asset_amount: 0

  @type t :: %__MODULE__{
          pool: String.t(),
          rune_address: String.t(),
          asset_address: String.t(),
          liquidity_provider_units: Amount.t(),
          rune_amount: Amount.t(),
          asset_amount: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "pool" => pool,
        "rune_address" => rune_address,
        "asset_address" => asset_address,
        "liquidity_provider_units" => units,
        "rune_amount" => rune_amount,
        "asset_amount" => asset_amount
      }) do
    with {:ok, units} <- Amount.new(units),
         {:ok, rune_amount} <- Amount.new(rune_amount),
         {:ok, asset_amount} <- Amount.new(asset_amount) do
      {:ok,
       %__MODULE__{
         pool: pool,
         rune_address: rune_address,
         asset_address: asset_address,
         liquidity_provider_units: units,
         rune_amount: rune_amount,
         asset_amount: asset_amount
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
