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

  defstruct id: nil,
            pair: nil,
            owner: nil,
            side: nil,
            rate: 0,
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
          id: String.t(),
          pair: String.t(),
          owner: String.t(),
          side: side,
          rate: Decimal.t(),
          updated_at: DateTime.t(),
          offer: Amount.t(),
          offer_value: Amount.t(),
          remaining: Amount.t(),
          remaining_value: Amount.t(),
          filled: Amount.t(),
          filled_value: Amount.t(),
          filled_fee: Amount.t(),
          value_usd: Amount.t(),
          type: type_order,
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
         {:ok, offer} <- Math.to_integer(offer),
         {:ok, remaining} <- Math.to_integer(remaining),
         {:ok, filled} <- Math.to_integer(filled),
         {:ok, fee_taker} <- Math.to_decimal(fee_taker),
         {:ok, asset_quote} <- Assets.from_denom(token_quote),
         {:ok, asset_base} <- Assets.from_denom(token_base) do
      side = String.to_existing_atom(side)

      filled_fee = Math.mul_floor(filled, fee_taker)

      remaining_value = value(remaining, rate, side)
      filled_value = value(filled, Decimal.div(Decimal.new(1), rate), side)

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
         remaining_value: remaining_value,
         filled: filled,
         filled_value: filled_value,
         filled_fee: filled_fee,
         type: type,
         deviation: deviation,
         value_usd:
           case side do
             :quote ->
               Prices.value_usd(asset_quote.symbol, remaining) +
                 Prices.value_usd(asset_base.symbol, filled)

             :base ->
               Prices.value_usd(asset_base.symbol, remaining) +
                 Prices.value_usd(asset_quote.symbol, filled)
           end
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

  @spec list(Rujira.Fin.Pair.t(), String.t(), integer()) ::
          {:ok, [t()]} | {:error, term()}
  def list(pair, address, limit \\ 30)
  def list(%{deployment_status: :preview}, _, _), do: {:ok, []}

  def list(pair, address, limit) do
    case query_list(pair.address, address, limit) do
      {:ok, %{"orders" => orders}} ->
        Rujira.Enum.reduce_while_ok(orders, &new(pair, &1))

      err ->
        err
    end
  end

  @spec list_all(Rujira.Fin.Pair.t(), keyword()) :: {:ok, [t()]} | {:error, term()}
  def list_all(%{address: address} = pair, opts) do
    with {:ok, raw_orders} <- query_all(address, opts) do
      Rujira.Enum.reduce_while_ok(raw_orders, &new(pair, &1))
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
      {:error, err} -> {:error, err}
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


  defmemop query(address, owner, side, price) do
    Contracts.query_state_smart(
      address,
      %{order: [owner, side, decode_price(price)]}
    )
  end

  defmemo query_list(contract, address, limit \\ 30) do
    Contracts.query_state_smart_with_retry(contract, %{
      orders: %{owner: address, limit: limit}
    })
  end

  defp query_all(contract, opts, cursor \\ nil, limit \\ 30) do
    Contracts.query_state_smart(
      contract,
      %{orders: %{owner: nil, start_after: to_cursor(cursor), limit: limit}},
      opts
    )
    |> Contracts.paginate("orders", limit, fn orders ->
      query_all(contract, opts, List.last(orders), limit)
    end)
  end

  defp to_cursor(nil), do: nil
  defp to_cursor(%{"owner" => o, "side" => s, "price" => p}), do: [o, s, p]

  defp value(amount, rate, :base), do: Math.mul_floor(amount, rate)
  defp value(amount, rate, :quote), do: Math.div_floor(amount, rate)
end
