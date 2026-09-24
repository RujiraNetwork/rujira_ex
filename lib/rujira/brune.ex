defmodule Rujira.Brune do
  @moduledoc """
  Public API for the rujira-brune node/bond protocol.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidate cache on the resource module, not here.
  """

  alias Rujira.Brune.LoggedEvent
  alias Rujira.Brune.Pool
  alias Rujira.Brune.State
  alias Rujira.Fin.MarketMaker.Quote

  # --- Pool ---

  defdelegate get_pool(address), to: Pool, as: :get
  defdelegate list_pools(), to: Pool, as: :list
  defdelegate load_pool(pool), to: State, as: :load

  # --- Events ---

  defdelegate list_events(address, start_after \\ nil, limit \\ 100), to: LoggedEvent, as: :list

  # --- Quote ---

  defdelegate quote(address, offer, ask, min_price \\ nil), to: Quote, as: :query
end
