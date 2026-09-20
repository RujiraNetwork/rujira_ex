defmodule Rujira.Thorchain do
  @moduledoc """
  Public API for THORChain base-layer queries.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidate cache on the resource module, not here.
  """

  alias Rujira.Thorchain.Address
  alias Rujira.Thorchain.InboundAddress
  alias Rujira.Thorchain.LiquidityProvider
  alias Rujira.Thorchain.Mimir
  alias Rujira.Thorchain.Network
  alias Rujira.Thorchain.OutboundFee
  alias Rujira.Thorchain.Pool

  # --- Network ---

  defdelegate network(), to: Network, as: :get

  # --- Pool ---

  defdelegate pools(), to: Pool, as: :list
  defdelegate pool_from_id(id), to: Pool, as: :from_id

  # --- Liquidity provider ---

  defdelegate liquidity_provider(asset, address), to: LiquidityProvider, as: :get
  defdelegate liquidity_provider_from_id(id), to: LiquidityProvider, as: :from_id

  # --- Mimir ---

  defdelegate mimirs(), to: Mimir, as: :list
  defdelegate mimir_from_id(key), to: Mimir, as: :from_id
  defdelegate halted_pools(), to: Mimir

  # --- Inbound / outbound ---

  defdelegate inbound_addresses(), to: InboundAddress, as: :list
  defdelegate outbound_fees(), to: OutboundFee, as: :list

  # --- Address ---

  defdelegate module_address(name), to: Address
end
