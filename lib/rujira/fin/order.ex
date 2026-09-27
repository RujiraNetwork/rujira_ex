defmodule Rujira.Fin.Order do
  @moduledoc """
  Trading order for the FIN protocol.

  Struct, construction, and queries. Use `Rujira.Fin` as the public API.

  The query boundary is typed: `side` is `:base | :quote` and `price` is a
  `Rujira.Fin.Price.order/0`. Wire serialisation happens only at the gRPC edge,
  so the same typed values used to query are used to invalidate:

      Memoize.invalidate(Rujira.Fin.Order, :query, [pair, owner, side, price])
  """

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Contracts
  alias Rujira.Fin.Pair
  alias Rujira.Fin.Price
  alias Rujira.Math
  alias Rujira.Node
  alias Rujira.Prices

  use Memoize

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
            filled_fee: 0,
            value_usd: 0,
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
          filled_fee: Amount.t(),
          value_usd: Amount.t(),
          type: type_order | nil,
          deviation: deviation
        }

  # --- Construction ---

  @spec new(Pair.t(), map(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def new(pair, attrs, opts \\ [])

  def new(
        %{
          address: address,
          fee_maker: fee_maker,
          token_quote: token_quote,
          token_base: token_base
        },
        %{
          "owner" => owner,
          "side" => side,
          "price" => price,
          "rate" => rate,
          "updated_at" => updated_at,
          "offer" => offer,
          "remaining" => remaining,
          "filled" => filled
        },
        opts
      ) do
    with {:ok, price} <- Price.from_query(price),
         {:ok, rate} <- Math.to_decimal(rate),
         {:ok, updated_at} <- Math.to_integer(updated_at),
         {:ok, updated_at} <- DateTime.from_unix(updated_at, :nanosecond),
         {:ok, offer} <- Amount.new(offer),
         {:ok, remaining} <- Amount.new(remaining),
         {:ok, filled} <- Amount.new(filled),
         {:ok, fee_maker} <- Math.to_decimal(fee_maker),
         {:ok, asset_quote} <- Assets.from_denom(token_quote),
         {:ok, asset_base} <- Assets.from_denom(token_base) do
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
         filled_value: value(filled, Decimal.div(Decimal.new(1), rate), side),
         filled_fee: Math.mul_ceil(filled, fee_maker),
         type: type(price),
         deviation: deviation(price),
         value_usd: value_usd(side, asset_base, asset_quote, remaining, filled, opts)
       }}
    end
  end

  defp placeholder(address, side, price, owner) do
    %__MODULE__{
      id: "#{address}/#{side}/#{Price.to_id(price)}/#{owner}",
      pair: address,
      owner: owner,
      side: side,
      price: price,
      rate: Decimal.new(0),
      updated_at: DateTime.utc_now(),
      offer: 0,
      remaining: 0,
      filled: 0,
      type: type(price),
      deviation: deviation(price)
    }
  end

  # --- Queries ---

  @spec list(Pair.t(), String.t() | nil, integer() | nil, Node.opts()) ::
          {:ok, [t()]} | {:error, term()}
  def list(pair, owner \\ nil, limit \\ nil, opts \\ []) do
    with {:ok, orders} <- query_orders(pair.address, owner, opts) do
      orders
      |> take(limit)
      |> Rujira.Enum.reduce_while_ok(&new(pair, &1, opts))
    end
  end

  @spec load(Pair.t(), side(), Price.order(), String.t(), Node.opts()) ::
          {:ok, t()} | {:error, term()}
  def load(%{address: address} = pair, side, price, owner, opts \\ []) do
    case query(address, owner, side, price, opts) do
      {:ok, order} ->
        new(pair, order, opts)

      {:error, %GRPC.RPCError{status: 2, message: "NotFound: query wasm contract failed"}} ->
        {:ok, placeholder(address, side, price, owner)}

      err ->
        err
    end
  end

  @spec list_all_pairs(String.t(), Node.opts()) :: {:ok, [t()]} | {:error, term()}
  def list_all_pairs(address, opts \\ []) do
    with {:ok, pairs} <- Pair.list(opts),
         {:ok, orders} <-
           Rujira.Enum.reduce_async_while_ok(pairs, &list(&1, address, nil, opts),
             timeout: 15_000
           ) do
      {:ok, List.flatten(orders)}
    end
  end

  @spec from_id(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def from_id(id, opts \\ []) do
    with [pair_address, side, price, owner] <- String.split(id, "/"),
         {:ok, price} <- Price.parse_order(price),
         {:ok, pair} <- Pair.get(pair_address, opts) do
      load(pair, String.to_existing_atom(side), price, owner, opts)
    else
      {:error, _} = err -> err
      _ -> {:error, :invalid_id}
    end
  end

  # --- Private ---

  defp type(%Price.Fixed{}), do: :fixed
  defp type(%Price.Oracle{}), do: :oracle

  defp deviation(%Price.Oracle{deviation: deviation}), do: deviation
  defp deviation(%Price.Fixed{}), do: nil

  @doc """
  Memoized fetch of a single order by `(owner, side, price)` on a contract.

  Invalidate with `Memoize.invalidate(Rujira.Fin.Order, :query, [address, owner, side, price])`.
  """
  @spec query(String.t(), String.t(), side(), Price.order()) ::
          {:ok, map()} | {:error, term()}
  defmemo query(address, owner, side, price) do
    fetch_order(address, owner, side, price, [])
  end

  @doc """
  As `query/4`, read at `opts[:height]` when one is given - a height read is
  never cached. Without a `:height` this is `query/4`, so the other opts are not
  applied.
  """
  @spec query(String.t(), String.t(), side(), Price.order(), Node.opts()) ::
          {:ok, map()} | {:error, term()}
  def query(address, owner, side, price, opts) do
    Node.at_height(
      opts,
      fn -> fetch_order(address, owner, side, price, opts) end,
      fn -> query(address, owner, side, price) end
    )
  end

  @doc """
  Memoized full fetch of orders on a contract, optionally filtered by `owner`.

  Returns the flat list of raw order maps from the chain, paginated internally.
  Invalidate with `Memoize.invalidate(Rujira.Fin.Order, :query_orders, [contract, owner])`.
  """
  @spec query_orders(String.t(), String.t() | nil) :: {:ok, [map()]} | {:error, term()}
  defmemo query_orders(contract, owner) do
    query_orders_page(contract, owner, nil, [])
  end

  @doc """
  As `query_orders/2`, read at `opts[:height]` when one is given - a height read
  is never cached. Without a `:height` this is `query_orders/2`, so the other
  opts are not applied.
  """
  @spec query_orders(String.t(), String.t() | nil, Node.opts()) ::
          {:ok, [map()]} | {:error, term()}
  def query_orders(contract, owner, opts) do
    Node.at_height(
      opts,
      fn -> query_orders_page(contract, owner, nil, opts) end,
      fn -> query_orders(contract, owner) end
    )
  end

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

  # A USD value is a bare number, so it has no error channel of its own: a height
  # that could not be served surfaces as an error on the order state query made
  # at that same height, before this is ever reached.
  defp value_usd(:quote, base, quote_, remaining, filled, opts),
    do:
      Prices.value_usd(quote_.ticker, remaining, 8, opts) +
        Prices.value_usd(base.ticker, filled, 8, opts)

  defp value_usd(:base, base, quote_, remaining, filled, opts),
    do:
      Prices.value_usd(base.ticker, remaining, 8, opts) +
        Prices.value_usd(quote_.ticker, filled, 8, opts)
end
