defmodule Rujira.Fin.Order do
  @moduledoc """
  Trading order for the FIN protocol.

  Struct, construction, and queries. Use `Rujira.Fin` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Contracts
  alias Rujira.Math
  alias Rujira.Prices

  use Memoize

  @max_limit 100

  # --- Struct ---

  defstruct id: nil,
            pair: nil,
            owner: nil,
            side: nil,
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

  @spec new(Rujira.Fin.Pair.t(), map()) :: {:ok, t()} | {:error, term()}
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
    with {type, deviation, price_id} <- parse_price(price),
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
         id: "#{address}/#{side}/#{price_id}/#{owner}",
         pair: address,
         owner: owner,
         side: side,
         rate: rate,
         updated_at: updated_at,
         offer: offer,
         offer_value: value(offer, rate, side),
         remaining: remaining,
         remaining_value: value(remaining, rate, side),
         filled: filled,
         filled_value: value(filled, Decimal.div(Decimal.new(1), rate), side),
         filled_fee: Math.mul_floor(filled, fee_taker),
         type: type,
         deviation: deviation,
         value_usd: value_usd(side, asset_base, asset_quote, remaining, filled)
       }}
    end
  end

  defp placeholder(address, side, price, owner) do
    [type | _] = String.split(price, ":")

    %__MODULE__{
      id: "#{address}/#{side}/#{price}/#{owner}",
      pair: address,
      owner: owner,
      side: String.to_existing_atom(side),
      rate: Decimal.new(0),
      updated_at: DateTime.utc_now(),
      offer: 0,
      remaining: 0,
      filled: 0,
      type: String.to_existing_atom(type),
      deviation: nil
    }
  end

  # --- Queries ---

  @spec list(Rujira.Fin.Pair.t(), String.t() | nil, integer() | nil) ::
          {:ok, [t()]} | {:error, term()}
  def list(pair, owner \\ nil, limit \\ nil) do
    with {:ok, orders} <- query_orders(pair.address, owner) do
      orders
      |> take(limit)
      |> Rujira.Enum.reduce_while_ok(&new(pair, &1))
    end
  end

  @spec load(Rujira.Fin.Pair.t(), String.t(), String.t(), String.t()) ::
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
    with {:ok, pairs} <- Rujira.Fin.Pair.list(),
         {:ok, orders} <-
           Rujira.Enum.reduce_async_while_ok(pairs, &list(&1, address), timeout: 15_000) do
      {:ok, List.flatten(orders)}
    end
  end

  @spec from_id(String.t()) :: {:ok, t()} | {:error, term()}
  def from_id(id) do
    with [pair_address, side, price, owner] <- String.split(id, "/"),
         {:ok, pair} <- Rujira.Fin.Pair.get(pair_address) do
      load(pair, side, price, owner)
    else
      {:error, _} = err -> err
      _ -> {:error, :invalid_id}
    end
  end

  # --- Private ---

  defp parse_price(%{"fixed" => v}), do: {:fixed, nil, "fixed:#{v}"}
  defp parse_price(%{"oracle" => v}), do: {:oracle, v, "oracle:#{v}"}

  defp decode_price("fixed:" <> v), do: %{fixed: v}

  defp decode_price("oracle:" <> v) do
    {:ok, val} = Math.to_integer(v)
    %{oracle: val}
  end

  @doc """
  Memoized fetch of a single order by `(owner, side, price)` on a contract.

  Invalidate with `Memoize.invalidate(Rujira.Fin.Order, :query, [address, owner, side, price])`.
  """
  @spec query(String.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, term()}
  defmemo query(address, owner, side, price) do
    Contracts.query_state_smart(
      address,
      %{order: [owner, side, decode_price(price)]}
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
