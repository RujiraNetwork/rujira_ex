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

  @spec new(Pair.t(), map()) :: {:ok, t()} | {:error, term()}
  def new(
        %{
          address: address,
          fee_taker: fee_taker,
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
        }
      ) do
    with {:ok, price} <- Price.from_query(price),
         {:ok, rate} <- Math.to_decimal(rate),
         {:ok, updated_at} <- Math.to_integer(updated_at),
         {:ok, updated_at} <- DateTime.from_unix(updated_at, :nanosecond),
         {:ok, offer} <- Amount.new(offer),
         {:ok, remaining} <- Amount.new(remaining),
         {:ok, filled} <- Amount.new(filled),
         {:ok, fee_taker} <- Math.to_decimal(fee_taker),
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
         filled_fee: Math.mul_floor(filled, fee_taker),
         type: type(price),
         deviation: deviation(price),
         value_usd: value_usd(side, asset_base, asset_quote, remaining, filled)
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

  @spec list(Pair.t(), String.t() | nil, integer() | nil) ::
          {:ok, [t()]} | {:error, term()}
  def list(pair, owner \\ nil, limit \\ nil) do
    with {:ok, orders} <- query_orders(pair.address, owner) do
      orders
      |> take(limit)
      |> Rujira.Enum.reduce_while_ok(&new(pair, &1))
    end
  end

  @spec load(Pair.t(), side(), Price.order(), String.t()) ::
          {:ok, t()} | {:error, term()}
  def load(%{address: address} = pair, side, price, owner) do
    case query(address, owner, side, price) do
      {:ok, order} ->
        new(pair, order)

      {:error, %GRPC.RPCError{status: 2, message: "NotFound: query wasm contract failed"}} ->
        {:ok, placeholder(address, side, price, owner)}

      err ->
        err
    end
  end

  @spec list_all_pairs(String.t()) :: {:ok, [t()]} | {:error, term()}
  def list_all_pairs(address) do
    with {:ok, pairs} <- Pair.list(),
         {:ok, orders} <-
           Rujira.Enum.reduce_async_while_ok(pairs, &list(&1, address), timeout: 15_000) do
      {:ok, List.flatten(orders)}
    end
  end

  @spec from_id(String.t()) :: {:ok, t()} | {:error, term()}
  def from_id(id) do
    with [pair_address, side, price, owner] <- String.split(id, "/"),
         {:ok, price} <- Price.parse_order(price),
         {:ok, pair} <- Pair.get(pair_address) do
      load(pair, String.to_existing_atom(side), price, owner)
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
    Contracts.query_state_smart(
      address,
      %{order: [owner, Atom.to_string(side), Price.to_query(price)]}
    )
  end

  @doc """
  Memoized full fetch of orders on a contract, optionally filtered by `owner`.

  Returns the flat list of raw order maps from the chain, paginated internally.
  Invalidate with `Memoize.invalidate(Rujira.Fin.Order, :query_orders, [contract, owner])`.
  """
  @spec query_orders(String.t(), String.t() | nil) :: {:ok, [map()]} | {:error, term()}
  defmemo query_orders(contract, owner) do
    query_orders_page(contract, owner, nil)
  end

  defp query_orders_page(contract, owner, cursor) do
    contract
    |> Contracts.query_state_smart_with_retry(%{
      orders: %{owner: owner, start_after: to_cursor(cursor), limit: @max_limit}
    })
    |> Contracts.paginate("orders", @max_limit, fn orders ->
      query_orders_page(contract, owner, List.last(orders))
    end)
  end

  defp to_cursor(nil), do: nil
  defp to_cursor(%{"owner" => o, "side" => s, "price" => p}), do: [o, s, p]

  defp take(orders, nil), do: orders
  defp take(orders, n), do: Enum.take(orders, n)

  defp value(amount, rate, :base), do: Math.mul_floor(amount, rate)
  defp value(amount, rate, :quote), do: Math.div_floor(amount, rate)

  defp value_usd(:quote, base, quote_, remaining, filled),
    do: Prices.value_usd(quote_.ticker, remaining) + Prices.value_usd(base.ticker, filled)

  defp value_usd(:base, base, quote_, remaining, filled),
    do: Prices.value_usd(base.ticker, remaining) + Prices.value_usd(quote_.ticker, filled)
end
