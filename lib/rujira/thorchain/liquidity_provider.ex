defmodule Rujira.Thorchain.LiquidityProvider do
  @moduledoc """
  A liquidity provider's position in a THORChain pool.

  Struct, construction, and queries. Use `Rujira.Thorchain` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Math
  alias Rujira.Prices
  alias Rujira.String
  alias Thorchain.Types.Query.Stub
  alias Thorchain.Types.QueryLiquidityProviderRequest
  alias Thorchain.Types.QueryLiquidityProviderResponse

  use Memoize

  # --- Struct ---

  defstruct id: nil,
            asset: nil,
            rune_address: nil,
            asset_address: nil,
            last_add_height: nil,
            last_withdraw_height: nil,
            units: 0,
            pending_rune: 0,
            pending_asset: 0,
            rune_deposit_value: 0,
            asset_deposit_value: 0,
            rune_redeem_value: 0,
            asset_redeem_value: 0,
            luvi_deposit_value: 0,
            luvi_redeem_value: 0,
            luvi_growth_pct: Decimal.new(0),
            value_usd: 0

  @type t :: %__MODULE__{
          id: String.t() | nil,
          asset: Asset.t() | nil,
          rune_address: String.t() | nil,
          asset_address: String.t() | nil,
          last_add_height: integer() | nil,
          last_withdraw_height: integer() | nil,
          units: Amount.t(),
          pending_rune: Amount.t(),
          pending_asset: Amount.t(),
          rune_deposit_value: Amount.t(),
          asset_deposit_value: Amount.t(),
          rune_redeem_value: Amount.t(),
          asset_redeem_value: Amount.t(),
          luvi_deposit_value: Amount.t(),
          luvi_redeem_value: Amount.t(),
          luvi_growth_pct: Decimal.t(),
          value_usd: Amount.t()
        }

  # --- Construction ---

  @spec new(QueryLiquidityProviderResponse.t()) :: {:ok, t()} | {:error, term()}
  def new(%QueryLiquidityProviderResponse{} = lp) do
    asset = Assets.from_string(lp.asset)

    with {:ok, units} <- Amount.new(lp.units),
         {:ok, pending_rune} <- Amount.new(lp.pending_rune),
         {:ok, pending_asset} <- Amount.new(lp.pending_asset),
         {:ok, rune_deposit_value} <- Amount.new(lp.rune_deposit_value),
         {:ok, asset_deposit_value} <- Amount.new(lp.asset_deposit_value),
         {:ok, rune_redeem_value} <- Amount.new(lp.rune_redeem_value),
         {:ok, asset_redeem_value} <- Amount.new(lp.asset_redeem_value),
         {:ok, luvi_deposit_value} <- Amount.new(lp.luvi_deposit_value),
         {:ok, luvi_redeem_value} <- Amount.new(lp.luvi_redeem_value),
         {:ok, luvi_growth_pct} <- Math.to_decimal(lp.luvi_growth_pct) do
      {:ok,
       %__MODULE__{
         id: "#{lp.asset}/#{lp.rune_address}",
         asset: asset,
         rune_address: String.nil_if_empty(lp.rune_address),
         asset_address: String.nil_if_empty(lp.asset_address),
         last_add_height: lp.last_add_height,
         last_withdraw_height: zero_nil(lp.last_withdraw_height),
         units: units,
         pending_rune: pending_rune,
         pending_asset: pending_asset,
         rune_deposit_value: rune_deposit_value,
         asset_deposit_value: asset_deposit_value,
         rune_redeem_value: rune_redeem_value,
         asset_redeem_value: asset_redeem_value,
         luvi_deposit_value: luvi_deposit_value,
         luvi_redeem_value: luvi_redeem_value,
         luvi_growth_pct: luvi_growth_pct,
         value_usd:
           Prices.value_usd(asset.ticker, asset_redeem_value) +
             Prices.value_usd("RUNE", rune_redeem_value)
       }}
    end
  end

  # --- Queries ---

  @spec get(String.t(), String.t()) :: {:ok, t()} | {:error, term()}
  def get(asset, address) do
    with {:ok, res} <- query(asset, address) do
      new(res)
    end
  end

  @spec from_id(String.t()) :: {:ok, t()} | {:error, term()}
  def from_id(id) do
    case String.split(id, "/") do
      [asset, address] -> get(asset, address)
      _ -> {:error, :invalid_id}
    end
  end

  @doc """
  Memoized fetch of a liquidity provider's raw position.

  Invalidate with `Memoize.invalidate(Rujira.Thorchain.LiquidityProvider, :query, [asset, address])`.
  """
  @spec query(String.t(), String.t()) ::
          {:ok, QueryLiquidityProviderResponse.t()} | {:error, term()}
  defmemo query(asset, address) do
    Rujira.Node.query(
      &Stub.liquidity_provider/2,
      %QueryLiquidityProviderRequest{asset: asset, address: address}
    )
  end

  # --- Private ---

  defp zero_nil(0), do: nil
  defp zero_nil(value), do: value
end
