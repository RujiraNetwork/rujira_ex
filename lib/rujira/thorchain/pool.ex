defmodule Rujira.Thorchain.Pool do
  @moduledoc """
  A THORChain liquidity pool.

  Struct, construction, and queries. Use `Rujira.Thorchain` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Cache
  alias Rujira.Math
  alias Rujira.Node
  alias Thorchain.Types.Query.Stub
  alias Thorchain.Types.QueryPoolResponse
  alias Thorchain.Types.QueryPoolsRequest
  alias Thorchain.Types.QueryPoolsResponse

  # --- Struct ---

  defstruct id: nil,
            asset: nil,
            status: nil,
            balance_asset: 0,
            balance_rune: 0,
            asset_tor_price: nil,
            pool_units: 0,
            lp_units: 0,
            pending_inbound_asset: 0,
            pending_inbound_rune: 0,
            derived_depth_bps: 0,
            savers_fill_bps: 0,
            savers_depth: 0,
            savers_units: 0,
            savers_capacity_remaining: 0,
            synth_supply: 0,
            synth_supply_remaining: 0,
            synth_units: 0

  @type t :: %__MODULE__{
          id: String.t() | nil,
          asset: Asset.t() | nil,
          status: String.t() | nil,
          balance_asset: Amount.t(),
          balance_rune: Amount.t(),
          asset_tor_price: Decimal.t() | nil,
          pool_units: Amount.t(),
          lp_units: Amount.t(),
          pending_inbound_asset: Amount.t(),
          pending_inbound_rune: Amount.t(),
          derived_depth_bps: Amount.t(),
          savers_fill_bps: Amount.t(),
          savers_depth: Amount.t(),
          savers_units: Amount.t(),
          savers_capacity_remaining: Amount.t(),
          synth_supply: Amount.t(),
          synth_supply_remaining: Amount.t(),
          synth_units: Amount.t()
        }

  # --- Construction ---

  @spec new(QueryPoolResponse.t()) :: {:ok, t()} | {:error, term()}
  def new(%QueryPoolResponse{} = pool) do
    with {:ok, balance_asset} <- Amount.new(pool.balance_asset),
         {:ok, balance_rune} <- Amount.new(pool.balance_rune),
         {:ok, pool_units} <- Amount.new(pool.pool_units),
         {:ok, lp_units} <- Amount.new(Map.get(pool, :LP_units)),
         {:ok, pending_inbound_asset} <- Amount.new(pool.pending_inbound_asset),
         {:ok, pending_inbound_rune} <- Amount.new(pool.pending_inbound_rune),
         {:ok, derived_depth_bps} <- Amount.new(pool.derived_depth_bps),
         {:ok, savers_fill_bps} <- Amount.new(pool.savers_fill_bps),
         {:ok, savers_depth} <- Amount.new(pool.savers_depth),
         {:ok, savers_units} <- Amount.new(pool.savers_units),
         {:ok, savers_capacity_remaining} <- Amount.new(pool.savers_capacity_remaining),
         {:ok, synth_supply} <- Amount.new(pool.synth_supply),
         {:ok, synth_supply_remaining} <- Amount.new(pool.synth_supply_remaining),
         {:ok, synth_units} <- Amount.new(pool.synth_units),
         {:ok, asset_tor_price} <- Math.to_decimal(pool.asset_tor_price) do
      {:ok,
       %__MODULE__{
         id: pool.asset,
         asset: Assets.from_string(pool.asset),
         status: pool.status,
         balance_asset: balance_asset,
         balance_rune: balance_rune,
         asset_tor_price: asset_tor_price && Math.normalize(asset_tor_price, 8, 0),
         pool_units: pool_units,
         lp_units: lp_units,
         pending_inbound_asset: pending_inbound_asset,
         pending_inbound_rune: pending_inbound_rune,
         derived_depth_bps: derived_depth_bps,
         savers_fill_bps: savers_fill_bps,
         savers_depth: savers_depth,
         savers_units: savers_units,
         savers_capacity_remaining: savers_capacity_remaining,
         synth_supply: synth_supply,
         synth_supply_remaining: synth_supply_remaining,
         synth_units: synth_units
       }}
    end
  end

  # --- Queries ---

  @doc "All pools, cached per `Rujira.Cache`."
  @spec list() :: {:ok, [t()]} | {:error, term()}
  def list, do: list([])

  @doc "As `list/0`, read at `opts[:height]` or, without one, at the head."
  @spec list(Node.opts()) :: {:ok, [t()]} | {:error, term()}
  def list(opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch({__MODULE__, :list, []}, [:per_block], opts, fn _height -> fetch(opts) end)
    end
  end

  @spec get(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def get(asset, opts \\ []) do
    with {:ok, pools} <- list(opts) do
      case Enum.find(pools, &(&1.id == asset)) do
        nil -> {:error, :not_found}
        pool -> {:ok, pool}
      end
    end
  end

  # TODO: resolve non-layer1 asset ids (secured/synth) to their pool asset once
  # `Assets.to_layer1/1` lands. For now the id is used as-is.
  @spec from_id(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def from_id(id, opts \\ []), do: get(id, opts)

  # --- Private ---

  defp fetch(opts) do
    with {:ok, %QueryPoolsResponse{pools: pools}} <-
           Node.query(&Stub.pools/3, %QueryPoolsRequest{}, opts) do
      Rujira.Enum.reduce_while_ok(pools, &new/1)
    end
  end
end
