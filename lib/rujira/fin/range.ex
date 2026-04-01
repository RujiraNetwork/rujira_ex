defmodule Rujira.Fin.Range do
  @moduledoc """
  Concentrated liquidity position (range) for the FIN protocol.

  Struct, construction, and queries. Use `Rujira.Fin` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Contracts
  alias Rujira.Math
  alias Rujira.Prices

  use Memoize

  defstruct id: nil,
            idx: nil,
            pair: nil,
            owner: nil,
            high: 0,
            low: 0,
            skew: 0,
            spread: 0,
            fee: 0,
            base: 0,
            quote: 0,
            price: 0,
            ask: 0,
            bid: 0,
            fees_base: 0,
            fees_quote: 0,
            value_usd: 0

  @type t :: %__MODULE__{
          id: String.t(),
          idx: integer(),
          pair: String.t(),
          owner: String.t(),
          high: Decimal.t(),
          low: Decimal.t(),
          skew: Decimal.t(),
          spread: Decimal.t(),
          fee: Decimal.t(),
          base: Amount.t(),
          quote: Amount.t(),
          price: Decimal.t(),
          ask: Decimal.t(),
          bid: Decimal.t(),
          fees_base: Amount.t(),
          fees_quote: Amount.t(),
          value_usd: Amount.t()
        }

  # --- Construction ---

  @doc """
  Parses a range from a contract query response.

  When called with a string address and integer index, creates a minimal
  range struct for subscription edge responses.
  """
  @spec new(Rujira.Fin.Pair.t(), map()) :: {:ok, t()} | {:error, term()}
  def new(
        %{address: address, token_quote: token_quote, token_base: token_base},
        %{
          "idx" => idx,
          "owner" => owner,
          "high" => high,
          "low" => low,
          "skew" => skew,
          "spread" => spread,
          "fee" => fee,
          "base" => base_amount,
          "quote" => quote_amount,
          "price" => price,
          "ask" => ask,
          "bid" => bid,
          "fees" => [fees_base, fees_quote]
        }
      ) do
    with {:ok, asset_quote} <- Assets.from_denom(token_quote),
         {:ok, asset_base} <- Assets.from_denom(token_base),
         {:ok, ask} <- Math.to_decimal(ask),
         {:ok, bid} <- Math.to_decimal(bid),
         {:ok, base_amount} <- Math.to_decimal(base_amount),
         {:ok, quote_amount} <- Math.to_decimal(quote_amount),
         {:ok, fees_base} <- Math.to_decimal(fees_base),
         {:ok, fees_quote} <- Math.to_decimal(fees_quote),
         {:ok, price} <- Math.to_decimal(price),
         {:ok, high} <- Math.to_decimal(high),
         {:ok, low} <- Math.to_decimal(low),
         {:ok, skew} <- Math.to_decimal(skew),
         {:ok, spread} <- Math.to_decimal(spread),
         {:ok, fee} <- Math.to_decimal(fee),
         {:ok, idx} <- Math.to_integer(idx) do
      base_int = Math.floor(base_amount)
      quote_int = Math.floor(quote_amount)
      base_fees_int = Math.floor(fees_base)
      quote_fees_int = Math.floor(fees_quote)

      {:ok,
       %__MODULE__{
         id: "#{address}/#{idx}",
         idx: idx,
         pair: address,
         owner: owner,
         high: high,
         low: low,
         skew: skew,
         spread: spread,
         fee: fee,
         base: base_int,
         quote: quote_int,
         price: price,
         ask: ask,
         bid: bid,
         fees_base: base_fees_int,
         fees_quote: quote_fees_int,
         value_usd:
           Prices.value_usd(asset_base.symbol, base_int + base_fees_int) +
             Prices.value_usd(asset_quote.symbol, quote_int + quote_fees_int)
       }}
    end
  end

  defp placeholder(address, idx) do
    %__MODULE__{id: "#{address}/#{idx}", idx: idx, pair: address}
  end

  # --- Queries ---

  @spec list(Rujira.Fin.Pair.t(), String.t() | nil, keyword()) ::
          {:ok, [t()]} | {:error, term()}
  def list(pair, address \\ nil, opts \\ [])
  def list(%{deployment_status: :preview}, _, _), do: {:ok, []}

  def list(pair, address, opts) do
    case query_list(pair.address, address, opts) do
      {:ok, ranges} when is_list(ranges) ->
        Rujira.Enum.reduce_while_ok(ranges, [], &new(pair, &1))

      err ->
        err
    end
  end

  @spec load(Rujira.Fin.Pair.t(), integer()) :: {:ok, t()} | {:error, term()}
  def load(%{address: address} = pair, idx) do
    case query(address, idx) do
      {:ok, range} ->
        new(pair, range)

      {:error, %GRPC.RPCError{status: 2, message: "NotFound: query wasm contract failed"}} ->
        {:ok, placeholder(address, idx)}

      err ->
        err
    end
  end

  @spec list_all(String.t() | nil, [String.t()] | nil) :: {:ok, [t()]} | {:error, term()}
  def list_all(address \\ nil, contracts \\ nil)

  def list_all(address, nil) do
    with {:ok, pairs} <- Rujira.Fin.Pair.list() do
      pairs
      |> Enum.filter(&(&1.deployment_status == :live))
      |> collect(address)
    end
  end

  def list_all(address, contracts) when is_list(contracts) do
    with {:ok, pairs} <- Rujira.Enum.reduce_while_ok(contracts, [], &Rujira.Fin.Pair.get/1) do
      collect(pairs, address)
    end
  end

  @spec from_id(String.t()) :: {:ok, t()} | {:error, term()}
  def from_id(id) do
    with [pair_address, idx] <- String.split(id, "/"),
         {:ok, idx} <- Math.to_integer(idx),
         {:ok, pair} <- Rujira.Fin.Pair.get(pair_address) do
      load(pair, idx)
    else
      {:error, err} -> {:error, err}
      _ -> {:error, :invalid_id}
    end
  end

  @spec tvl(Rujira.Fin.Pair.t()) :: {:ok, non_neg_integer()} | {:error, term()}
  def tvl(pair) do
    case list(pair) do
      {:ok, ranges} -> {:ok, Enum.reduce(ranges, 0, fn r, acc -> acc + r.value_usd end)}
      {:error, _} = err -> err
    end
  end

  @spec total_tvl() :: {:ok, non_neg_integer()} | {:error, term()}
  def total_tvl do
    with {:ok, pairs} <- Rujira.Fin.Pair.list(),
         {:ok, tvls} <-
           pairs
           |> Enum.filter(&(&1.deployment_status == :live))
           |> Rujira.Enum.reduce_async_while_ok(
             fn pair ->
               case tvl(pair) do
                 {:ok, _} = ok -> ok
                 {:error, _} -> {:ok, 0}
               end
             end,
             timeout: 30_000
           ) do
      {:ok, Enum.sum(tvls)}
    end
  end

  # --- Private ---

  defp collect(pairs, address) do
    with {:ok, ranges} <-
           Rujira.Enum.reduce_async_while_ok(pairs, &list(&1, address), timeout: 15_000) do
      {:ok, List.flatten(ranges)}
    end
  end

  defmemo query_list(contract, address, opts, cursor \\ nil, limit \\ 30) do
    Contracts.query_state_smart(
      contract,
      %{ranges: %{owner: address, cursor: cursor, limit: limit}},
      opts
    )
    |> Contracts.paginate("ranges", limit, fn ranges ->
      query_list(contract, address, opts, List.last(ranges)["idx"], limit)
    end)
  end

  defmemop query(address, idx) do
    Contracts.query_state_smart(
      address,
      %{range: Kernel.to_string(idx)}
    )
  end
end
