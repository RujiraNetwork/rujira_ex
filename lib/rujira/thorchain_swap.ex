defmodule Rujira.ThorchainSwap do
  @moduledoc """
  Public API for the rujira-thorchain-swap streaming market-maker protocol.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidate cache on the resource module, not here.

  Every query takes a trailing `opts`, forwarded to `Rujira.Node.query/3`, so a
  caller can read a whole composite at one `height:` - `load_strategy/2` reads
  the strategy's markets and vaults at the same one.
  """

  alias Rujira.Fin.MarketMaker.Quote
  alias Rujira.ThorchainSwap.Strategy

  # --- Strategy ---

  defdelegate get_strategy(address, opts \\ []), to: Strategy, as: :get
  defdelegate list_strategies(opts \\ []), to: Strategy, as: :list
  defdelegate load_strategy(strategy, opts \\ []), to: Strategy, as: :load

  # --- Quote ---

  defdelegate quote(address, offer, ask, min_price \\ nil, opts \\ []), to: Quote, as: :query
end
