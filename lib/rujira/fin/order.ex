defmodule Rujira.Fin.Order do
  @moduledoc """
  Trading order for the FIN protocol.

  Struct, construction, and queries. Use `Rujira.Fin` as the public API.

  The query boundary is typed: `side` is `:base | :quote` and `price` is a
  `Rujira.Fin.Price.order/0`; the price reaches the cache and the wire in the
  one form `Rujira.Fin.Price.to_query/1` builds.

  Every read here is cached per `Rujira.Cache`, resolved at `opts[:height]` or -
  without one - at the head. A fixed-price order is the pair contract's own
  state; an oracle-priced one moves with the oracle, which announces itself with
  no event, so it is read per block. A page of orders may hold either, so it is
  read per block too.
  """

  alias Rujira.Amount
  alias Rujira.Cache
  alias Rujira.Contracts
  alias Rujira.Fin.Pair
  alias Rujira.Fin.Price
  alias Rujira.Math
  alias Rujira.Node

  @max_limit 100

  # --- Struct ---

  defstruct id: nil,
            pair: nil,
            owner: nil,
            side: nil,
            price: nil,
            rate: Decimal.new(0),
            updated_at: nil,
            offer: 0,
            offer_value: 0,
            remaining: 0,
            remaining_value: 0,
            filled: 0,
            filled_value: 0,
            type: nil,
            deviation: nil

  @type side :: :base | :quote
  @type deviation :: nil | integer()
  @type type_order :: :fixed | :oracle
  @type t :: %__MODULE__{
          id: String.t() | nil,
          pair: String.t() | nil,
          owner: String.t() | nil,
          side: side | nil,
          price: Price.order() | nil,
          rate: Decimal.t(),
          updated_at: DateTime.t() | nil,
          offer: Amount.t(),
          offer_value: Amount.t(),
          remaining: Amount.t(),
          remaining_value: Amount.t(),
          filled: Amount.t(),
          filled_value: Amount.t(),
          type: type_order | nil,
          deviation: deviation
        }

  # --- Construction ---

  @spec new(Pair.t(), map()) :: {:ok, t()} | {:error, term()}
  def new(%{address: address}, attrs), do: build(address, attrs)
  def new(_, _), do: {:error, :invalid_attrs}

  # --- Calculations ---

  @doc """
  The maker fee the pair charges on an order's filled amount, rounded up.

  A fee rate lives on the pair, not on the order, so this is a pure function over
  the two structs the caller already holds rather than a field of either.
  """
  @spec filled_fee(t(), Pair.t()) :: Amount.t()
  def filled_fee(%__MODULE__{filled: filled}, %{fee_maker: fee_maker}),
    do: Math.mul_ceil(filled, fee_maker)

  # --- Queries ---

  @spec list(Pair.t(), String.t() | nil, integer() | nil, Node.opts()) ::
          {:ok, [t()]} | {:error, term()}
  def list(pair, owner \\ nil, limit \\ nil, opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, orders} <- query_orders(pair.address, owner, opts) do
      orders
      |> take(limit)
      |> Rujira.Enum.reduce_while_ok(&new(pair, &1))
    end
  end

  @doc """
  As `list/4`, every order on the pair regardless of owner, with no limit.
  """
  @spec list_pair(Pair.t(), Node.opts()) :: {:ok, [t()]} | {:error, term()}
  def list_pair(pair, opts \\ []), do: list(pair, nil, nil, opts)

  @doc """
  Loads a single order by its `(side, price, owner)` key on a pair.

  An order the pair does not hold is `{:error, :not_found}`.
  """
  @spec load(Pair.t(), side(), Price.order(), String.t(), Node.opts()) ::
          {:ok, t()} | {:error, term()}
  def load(%{address: address}, side, price, owner, opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts), do: load_at(address, side, price, owner, opts)
  end

  @doc """
  Lists every order an `address` holds, across every pair.

  Each pair is read concurrently; `opts[:fan_out]` sets the per-pair timeout
  and how many run at once - see `Rujira.Enum`.
  """
  @spec list_all_pairs(String.t(), Node.opts()) :: {:ok, [t()]} | {:error, term()}
  def list_all_pairs(address, opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, pairs} <- Pair.list(opts),
         {:ok, orders} <-
           Rujira.Enum.reduce_async_while_ok(
             pairs,
             &list(&1, address, nil, opts),
             opts,
             __MODULE__
           ) do
      {:ok, List.flatten(orders)}
    end
  end

  @doc """
  Loads the order an `id` names, reading only the contract the id carries.

  The id is `<pair>/<side>/<price>/<owner>` — the pair's own config is not read,
  since an order is built from the order query alone.
  """
  @spec from_id(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def from_id(id, opts \\ []) do
    with [pair_address, side, price, owner] <- String.split(id, "/"),
         {:ok, price} <- Price.parse_order(price),
         {:ok, opts} <- Cache.pin(opts) do
      load_at(pair_address, String.to_existing_atom(side), price, owner, opts)
    else
      {:error, _} = err -> err
      _ -> {:error, :invalid_id}
    end
  end

  # --- Private ---

  defp build(address, %{
         "owner" => owner,
         "side" => side,
         "price" => price,
         "rate" => rate,
         "updated_at" => updated_at,
         "offer" => offer,
         "remaining" => remaining,
         "filled" => filled
       }) do
    with {:ok, price} <- Price.from_query(price),
         {:ok, rate} <- Math.to_decimal(rate),
         {:ok, updated_at} <- Math.to_integer(updated_at),
         {:ok, updated_at} <- DateTime.from_unix(updated_at, :nanosecond),
         {:ok, offer} <- Amount.new(offer),
         {:ok, remaining} <- Amount.new(remaining),
         {:ok, filled} <- Amount.new(filled) do
      side = String.to_existing_atom(side)

      {:ok,
       %__MODULE__{
         id: "#{address}/#{side}/#{Price.to_id(price)}/#{owner}",
         pair: address,
         owner: owner,
         side: side,
         price: price,
         rate: rate,
         updated_at: updated_at,
         offer: offer,
         offer_value: value(offer, rate, side),
         remaining: remaining,
         remaining_value: value(remaining, rate, side),
         filled: filled,
         filled_value: value(filled, rate, opposite(side)),
         type: type(price),
         deviation: deviation(price)
       }}
    end
  end

  defp build(_, _), do: {:error, :invalid_attrs}

  defp load_at(address, side, price, owner, opts),
    do: loaded(address, query(address, owner, side, price, opts))

  # An order the pair does not hold is `:not_found`. Every other error is the
  # contract's or the node's, and is handed back unchanged.
  defp loaded(address, {:ok, order}), do: build(address, order)
  defp loaded(_address, {:error, err}), do: missing(Contracts.not_found?(err), err)

  defp missing(true, _err), do: {:error, :not_found}
  defp missing(false, err), do: {:error, err}

  defp type(%Price.Fixed{}), do: :fixed
  defp type(%Price.Oracle{}), do: :oracle

  defp deviation(%Price.Oracle{deviation: deviation}), do: deviation
  defp deviation(%Price.Fixed{}), do: nil

  @doc "A single order by `(owner, side, price)` on a contract."
  @spec query(String.t(), String.t(), side(), Price.order()) ::
          {:ok, map()} | {:error, term()}
  def query(address, owner, side, price), do: query(address, owner, side, price, [])

  @doc """
  As `query/4`, read at `opts[:height]` when given.

  A fixed price is the contract's own state; an oracle price moves with the
  oracle, so it is read per block - see `order_sources/2`.
  """
  @spec query(String.t(), String.t(), side(), Price.order(), Node.opts()) ::
          {:ok, map()} | {:error, term()}
  def query(address, owner, side, price, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch(
        {__MODULE__, :query, [address, owner, side, Price.to_query(price)]},
        order_sources(address, price),
        opts,
        fn _height -> fetch_order(address, owner, side, price, opts) end
      )
    end
  end

  @doc """
  Every order on a contract, optionally filtered by `owner`.

  Returns the flat list of raw order maps from the chain, paginated internally.
  """
  @spec query_orders(String.t(), String.t() | nil) :: {:ok, [map()]} | {:error, term()}
  def query_orders(contract, owner), do: query_orders(contract, owner, [])

  @doc """
  As `query_orders/2`, read at `opts[:height]` when given.

  A page carries whatever orders the contract holds, so one oracle-priced order
  on it moves the whole page: it is read per block rather than against the
  contract alone.
  """
  @spec query_orders(String.t(), String.t() | nil, Node.opts()) ::
          {:ok, [map()]} | {:error, term()}
  def query_orders(contract, owner, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch(
        {__MODULE__, :query_orders, [contract, owner]},
        [:per_block],
        opts,
        fn _height ->
          query_orders_page(contract, owner, nil, opts)
        end
      )
    end
  end

  # An oracle price is wiped and rewritten each block with no event of its own,
  # so such an order is only ever valid at the height it was read at.
  defp order_sources(_address, %Price.Oracle{}), do: [:per_block]
  defp order_sources(address, %Price.Fixed{}), do: [{:contract, address}]

  defp fetch_order(address, owner, side, price, opts) do
    Contracts.query_state_smart(
      address,
      %{order: [owner, Atom.to_string(side), Price.to_query(price)]},
      opts
    )
  end

  defp query_orders_page(contract, owner, cursor, opts) do
    contract
    |> Contracts.query_state_smart_with_retry(
      %{orders: %{owner: owner, start_after: to_cursor(cursor), limit: @max_limit}},
      opts
    )
    |> Contracts.paginate("orders", @max_limit, fn orders ->
      query_orders_page(contract, owner, List.last(orders), opts)
    end)
  end

  defp to_cursor(nil), do: nil
  defp to_cursor(%{"owner" => o, "side" => s, "price" => p}), do: [o, s, p]

  defp take(orders, nil), do: orders
  defp take(orders, n), do: Enum.take(orders, n)

  defp value(amount, rate, :base), do: Math.mul_floor(amount, rate)
  defp value(amount, rate, :quote), do: Math.div_floor(amount, rate)

  defp opposite(:base), do: :quote
  defp opposite(:quote), do: :base
end
