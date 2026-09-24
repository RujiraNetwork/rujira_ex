defmodule Rujira.ThorchainSwap do
  @moduledoc """
  Public API for the rujira-thorchain-swap streaming market-maker protocol.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidate cache on the resource module, not here.
  """

  alias Rujira.Fin.MarketMaker.Quote
  alias Rujira.ThorchainSwap.Strategy

  # --- Strategy ---

  defdelegate get_strategy(address), to: Strategy, as: :get
  defdelegate list_strategies(), to: Strategy, as: :list
  defdelegate load_strategy(strategy), to: Strategy, as: :load

  # --- Quote ---

  defdelegate quote(address, offer, ask, min_price \\ nil), to: Quote, as: :query
end
