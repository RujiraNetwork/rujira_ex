defmodule Rujira.Brune do
  @moduledoc """
  Public API for the rujira-brune node/bond protocol.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidate cache on the resource module, not here.

  Every query takes a trailing `opts`, forwarded to `Rujira.Node.query/3`, so a
  caller can read a whole composite at one `height:`. A memoized query's opts
  arity reads the node uncached when given a `:height` - see the resource
  module.
  """

  alias Rujira.Brune.LoggedEvent
  alias Rujira.Brune.Pool
  alias Rujira.Brune.State
  alias Rujira.Fin.MarketMaker.Quote

  # --- Pool ---

  defdelegate get_pool(address, opts \\ []), to: Pool, as: :get
  defdelegate list_pools(opts \\ []), to: Pool, as: :list
  defdelegate load_pool(pool, opts \\ []), to: State, as: :load
  defdelegate pool_from_id(id, opts \\ []), to: Pool, as: :from_id

  # --- Events ---

  defdelegate list_events(address, start_after \\ nil, limit \\ 100, opts \\ []),
    to: LoggedEvent,
    as: :list

  # --- Quote ---

  defdelegate quote(address, offer, ask, min_price \\ nil, opts \\ []), to: Quote, as: :query
end
