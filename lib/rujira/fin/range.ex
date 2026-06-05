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

  @max_limit 100

  # --- Struct ---

  defstruct id: nil,
            idx: nil,
            pair: nil,
            owner: nil,
            high: Decimal.new(0),
            low: Decimal.new(0),
            skew: Decimal.new(0),
            spread: Decimal.new(0),
            fee: Decimal.new(0),
            base: 0,
            quote: 0,
            price: Decimal.new(0),
            ask: Decimal.new(0),
            bid: Decimal.new(0),
            fees_base: 0,
            fees_quote: 0,
            value_usd: 0

  @type t :: %__MODULE__{
          id: String.t() | nil,
          idx: integer() | nil,
          pair: String.t() | nil,
          owner: String.t() | nil,
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
         {:ok, base} <- Amount.new(base_amount),
         {:ok, quote_} <- Amount.new(quote_amount),
         {:ok, fees_base} <- Amount.new(fees_base),
         {:ok, fees_quote} <- Amount.new(fees_quote),
         {:ok, price} <- Math.to_decimal(price),
         {:ok, high} <- Math.to_decimal(high),
         {:ok, low} <- Math.to_decimal(low),
         {:ok, skew} <- Math.to_decimal(skew),
         {:ok, spread} <- Math.to_decimal(spread),
         {:ok, fee} <- Math.to_decimal(fee),
         {:ok, idx} <- Math.to_integer(idx) do
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
         base: base,
         quote: quote_,
         price: price,
         ask: ask,
         bid: bid,
         fees_base: fees_base,
         fees_quote: fees_quote,
         value_usd: value_usd(asset_base, asset_quote, base, quote_, fees_base, fees_quote)
       }}
    end
  end

  defp placeholder(address, idx) do
    %__MODULE__{id: "#{address}/#{idx}", idx: idx, pair: address}
  end

  # --- Queries ---

  @spec list(Rujira.Fin.Pair.t(), String.t() | nil, integer() | nil) ::
          {:ok, [t()]} | {:error, term()}
  def list(pair, owner \\ nil, limit \\ nil) do
    with {:ok, ranges} <- query_ranges(pair.address, owner) do
      ranges
      |> take(limit)
      |> Rujira.Enum.reduce_while_ok(&new(pair, &1))
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
  def list_all(owner \\ nil, contracts \\ nil) do
    with {:ok, pairs} <- resolve_pairs(contracts) do
      collect(pairs, owner)
    end
  end

  @spec from_id(String.t()) :: {:ok, t()} | {:error, term()}
  def from_id(id) do
    with [pair_address, idx] <- String.split(id, "/"),
         {:ok, idx} <- Math.to_integer(idx),
         {:ok, pair} <- Rujira.Fin.Pair.get(pair_address) do
      load(pair, idx)
    else
      {:error, _} = err -> err
      _ -> {:error, :invalid_id}
    end
  end

  @spec tvl(Rujira.Fin.Pair.t()) :: {:ok, non_neg_integer()} | {:error, term()}
  def tvl(pair) do
    with {:ok, ranges} <- list(pair) do
      {:ok, Enum.sum_by(ranges, & &1.value_usd)}
    end
  end

  @spec total_tvl() :: {:ok, non_neg_integer()} | {:error, term()}
  def total_tvl do
    with {:ok, pairs} <- Rujira.Fin.Pair.list(),
         {:ok, tvls} <-
           Rujira.Enum.reduce_async_while_ok(pairs, &tvl_or_zero/1, timeout: 30_000) do
      {:ok, Enum.sum(tvls)}
    end
  end

  @doc """
  Memoized full fetch of ranges on a contract, optionally filtered by `owner`.

  Returns the flat list of raw range maps from the chain, paginated internally.
  Invalidate with `Memoize.invalidate(Rujira.Fin.Range, :query_ranges, [contract, owner])`.
  """
  @spec query_ranges(String.t(), String.t() | nil) :: {:ok, [map()]} | {:error, term()}
  defmemo query_ranges(contract, owner) do
    query_ranges_page(contract, owner, nil)
  end

  @doc """
  Memoized fetch of a single range by `idx` on a contract.

  Invalidate with `Memoize.invalidate(Rujira.Fin.Range, :query, [address, idx])`.
  """
  @spec query(String.t(), integer()) :: {:ok, map()} | {:error, term()}
  defmemo query(address, idx) do
    Contracts.query_state_smart(address, %{range: Kernel.to_string(idx)})
  end

  # --- Private ---

  defp resolve_pairs(nil), do: Rujira.Fin.Pair.list()

  defp resolve_pairs(contracts) when is_list(contracts),
    do: Rujira.Enum.reduce_while_ok(contracts, &Rujira.Fin.Pair.get/1)

  defp collect(pairs, owner) do
    with {:ok, ranges} <-
           Rujira.Enum.reduce_async_while_ok(pairs, &list(&1, owner), timeout: 15_000) do
      {:ok, List.flatten(ranges)}
    end
  end

  defp tvl_or_zero(pair) do
    case tvl(pair) do
      {:ok, _} = ok -> ok
      {:error, _} -> {:ok, 0}
    end
  end

  defp take(ranges, nil), do: ranges
  defp take(ranges, n), do: Enum.take(ranges, n)

  defp value_usd(asset_base, asset_quote, base, quote_, fees_base, fees_quote) do
    Prices.value_usd(asset_base.symbol, base + fees_base) +
      Prices.value_usd(asset_quote.symbol, quote_ + fees_quote)
  end

  defp query_ranges_page(contract, owner, cursor) do
    contract
    |> Contracts.query_state_smart_with_retry(%{
      ranges: %{owner: owner, cursor: cursor, limit: @max_limit}
    })
    |> Contracts.paginate("ranges", @max_limit, fn ranges ->
      query_ranges_page(contract, owner, List.last(ranges)["idx"])
    end)
  end
end
