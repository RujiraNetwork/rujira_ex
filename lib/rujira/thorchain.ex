defmodule Rujira.Thorchain do
  @moduledoc """
  Public API for THORChain base-layer queries.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidate cache on the resource module, not here.

  Every query takes a trailing `opts`, forwarded to `Rujira.Node.query/3`, so a
  caller can read at a `height:`. A memoized query's opts arity reads the node
  uncached when given a `:height` - see the resource module.
  """

  alias Rujira.Thorchain.Address
  alias Rujira.Thorchain.InboundAddress
  alias Rujira.Thorchain.LiquidityProvider
  alias Rujira.Thorchain.Mimir
  alias Rujira.Thorchain.Network
  alias Rujira.Thorchain.OutboundFee
  alias Rujira.Thorchain.Pool

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
  defdelegate outbound_fees(opts \\ []), to: OutboundFee, as: :list

  # --- Address ---

  defdelegate module_address(name), to: Address
end
