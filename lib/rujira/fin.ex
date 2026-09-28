defmodule Rujira.Fin do
  @moduledoc """
  Public API for the FIN DEX protocol.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidate cache on the resource module, not here.

  Every query takes a trailing `opts`, forwarded to `Rujira.Node.query/3`, so a
  caller can read a whole composite at one `height:`. A memoized query's opts
  arity reads the node uncached when given a `:height` - see the resource
  module. Pure functions (`ticker_id!/1`, `book_depth/3`, `order_filled_fee/2`)
  take no `opts`.
  """

  alias Rujira.Fin.Book
  alias Rujira.Fin.Order
  alias Rujira.Fin.Pair
  alias Rujira.Fin.Range
  alias Rujira.Fin.Simulation

  # --- Pair ---

  defdelegate get_pair(address, opts \\ []), to: Pair, as: :get
  defdelegate list_pairs(opts \\ []), to: Pair, as: :list
  defdelegate get_stable_pair(denom, opts \\ []), to: Pair, as: :find_stable
  defdelegate get_default_pair(denom, opts \\ []), to: Pair, as: :find_default
  defdelegate denom_for_ticker(ticker), to: Pair
  defdelegate denom_for_ticker(ticker, opts), to: Pair
  defdelegate get_pair_from_denoms(base, quote_denom), to: Pair, as: :find_by_denoms
  defdelegate get_pair_from_denoms(base, quote_denom, opts), to: Pair, as: :find_by_denoms
  defdelegate pair_from_id(id, opts \\ []), to: Pair, as: :from_id
  defdelegate ticker_id!(pair), to: Pair

  # --- Book ---

  defdelegate load_pair(pair, limit \\ nil, opts \\ []), to: Book, as: :load
  defdelegate book_from_id(id, opts \\ []), to: Book, as: :from_id
  defdelegate book_depth(book, side, deviation), to: Book, as: :depth

  # --- Order ---

  defdelegate list_orders(pair, address, limit \\ nil, opts \\ []), to: Order, as: :list
  defdelegate list_pair_orders(pair, opts \\ []), to: Order, as: :list_pair
  defdelegate load_order(pair, side, price, owner, opts \\ []), to: Order, as: :load
  defdelegate list_all_orders(address, opts \\ []), to: Order, as: :list_all_pairs
  defdelegate order_from_id(id, opts \\ []), to: Order, as: :from_id
  defdelegate order_filled_fee(order, pair), to: Order, as: :filled_fee

  # --- Range ---

  defdelegate list_ranges(pair, address \\ nil, opts \\ []), to: Range, as: :list_pair
  defdelegate load_range(pair, idx, opts \\ []), to: Range, as: :load

  defdelegate list_all_ranges(address \\ nil, contracts \\ nil, opts \\ []),
    to: Range,
    as: :list_all

  defdelegate range_from_id(id, opts \\ []), to: Range, as: :from_id

  # --- Simulation ---

  defdelegate simulate(pair, offer, opts \\ []), to: Simulation
  defdelegate simulation_from_id(id, opts \\ []), to: Simulation, as: :from_id
end
