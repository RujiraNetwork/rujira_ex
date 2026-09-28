defmodule Rujira.Thorchain do
  @moduledoc """
  Public API for THORChain base-layer queries.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidation is `Rujira.Cache`'s: it follows from a read's
  sources, not from a call here.

  Every query takes a trailing `opts`, forwarded to `Rujira.Node.query/3`, so a
  caller can read at a `height:`. Every lookup here is cached per
  `Rujira.Cache`, resolved at `opts[:height]` or, without one, at the head -
  see the resource module.
  """

  alias Rujira.Thorchain.Address
  alias Rujira.Thorchain.Block
  alias Rujira.Thorchain.InboundAddress
  alias Rujira.Thorchain.LiquidityProvider
  alias Rujira.Thorchain.Mimir
  alias Rujira.Thorchain.Network
  alias Rujira.Thorchain.OutboundFee
  alias Rujira.Thorchain.Pool

  # --- Block ---

  defdelegate block(height \\ :latest, opts \\ []), to: Block, as: :get

  # --- Network ---

  defdelegate network(opts \\ []), to: Network, as: :get

  # --- Pool ---

  defdelegate pools(opts \\ []), to: Pool, as: :list
  defdelegate pool_from_id(id, opts \\ []), to: Pool, as: :from_id

  # --- Liquidity provider ---

  defdelegate liquidity_provider(asset, address, opts \\ []), to: LiquidityProvider, as: :get
  defdelegate liquidity_provider_from_id(id, opts \\ []), to: LiquidityProvider, as: :from_id

  # --- Mimir ---

  defdelegate mimirs(opts \\ []), to: Mimir, as: :list
  defdelegate mimir_from_id(key, opts \\ []), to: Mimir, as: :from_id
  defdelegate halted_pools(opts \\ []), to: Mimir

  # --- Inbound / outbound ---

  defdelegate inbound_addresses(opts \\ []), to: InboundAddress, as: :list
  defdelegate inbound_address_from_id(id, opts \\ []), to: InboundAddress, as: :from_id
  defdelegate outbound_fees(opts \\ []), to: OutboundFee, as: :list
  defdelegate outbound_fee_from_id(id, opts \\ []), to: OutboundFee, as: :from_id

  # --- Address ---

  defdelegate module_address(name), to: Address
end
