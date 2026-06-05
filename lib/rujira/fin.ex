defmodule Rujira.Fin do
  @moduledoc """
  Public API for the FIN DEX protocol.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidate cache on the resource module, not here.
  """

  alias Rujira.Fin.Book
  alias Rujira.Fin.Order
  alias Rujira.Fin.Pair
  alias Rujira.Fin.Range

  # --- Pair ---

  defdelegate get_pair(address), to: Pair, as: :get
  defdelegate list_pairs(), to: Pair, as: :list
  defdelegate get_stable_pair(denom), to: Pair, as: :find_stable
  defdelegate denom_for_symbol(symbol), to: Pair
  defdelegate get_pair_from_denoms(base, quote_denom), to: Pair, as: :find_by_denoms
  defdelegate pair_from_id(id), to: Pair, as: :from_id
  defdelegate ticker_id!(pair), to: Pair
  defdelegate get_pair_tvl(address), to: Pair, as: :tvl

  # --- Book ---

  defdelegate load_pair(pair, limit \\ 75), to: Book, as: :load
  defdelegate book_from_id(id), to: Book, as: :from_id
  defdelegate book_price(id), to: Book, as: :price
  defdelegate book_depth(book, side, deviation), to: Book, as: :depth

  # --- Order ---

  defdelegate list_orders(pair, address, limit \\ 30), to: Order, as: :list
  def list_pair_orders(pair, _opts \\ []), do: Order.list(pair)
  defdelegate load_order(pair, side, price, owner), to: Order, as: :load
  defdelegate list_all_orders(address), to: Order, as: :list_all_pairs
  defdelegate order_from_id(id), to: Order, as: :from_id

  # --- Range ---

  defdelegate list_ranges(pair, address \\ nil, opts \\ []), to: Range, as: :list
  defdelegate load_range(pair, idx), to: Range, as: :load
  defdelegate list_all_ranges(address \\ nil, contracts \\ nil), to: Range, as: :list_all
  defdelegate range_from_id(id), to: Range, as: :from_id
  defdelegate range_tvl(pair), to: Range, as: :tvl
  defdelegate total_range_tvl(), to: Range, as: :total_tvl
end
