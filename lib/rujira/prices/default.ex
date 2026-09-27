defmodule Rujira.Prices.Default do
  @moduledoc """
  Default price adapter: oracle → FIN book mid-price fallback.

  Every lookup takes a trailing `opts`, forwarded to `Rujira.Node.query/3`, so a
  price can be read at a `height:`. The memoized lookups keep their name, arity
  and cache key and gain a sibling one arity higher — a height read is never
  cached.
  """
  @behaviour Rujira.Prices

  use Memoize

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Node
  alias Thorchain.Types.Query.Stub, as: Q
  alias Thorchain.Types.QueryOraclePriceRequest

  @impl true
  def get(ticker), do: get(ticker, [])

  @impl true
  # bRUNE (bonded RUNE) is priced 1:1 with RUNE.
  def get("bRUNE", opts), do: get("RUNE", opts)

  def get(ticker, opts) do
    case oracle_price(ticker, opts) do
      {:ok, _} = ok -> ok
      {:error, err} -> unless_height_error(err, fn -> fin_price(ticker, opts) end)
    end
  end

  @impl true
  # A USD value is a bare number, so it has no error channel of its own: a height
  # that could not be served comes back from `get/2` as an error and is valued at
  # `0` - see the `Rujira.Prices` moduledoc. The position read at that same
  # height is where the height error itself surfaces.
  def value_usd(ticker, amount, decimals \\ 8, opts \\ []) do
    case get(ticker, opts) do
      {:ok, price} ->
        amount
        |> Decimal.new()
        |> Decimal.mult(price)
        |> Decimal.mult(Decimal.new(Amount.precision()))
        |> Decimal.div(Decimal.new(10 ** decimals))
        |> Decimal.round(0, :floor)
        |> Decimal.to_integer()

      _ ->
        0
    end
  end

  @doc """
  Memoized oracle price lookup.

  Invalidate with `Memoize.invalidate(Rujira.Prices.Default, :oracle_price, [ticker])`.
  """
  @spec oracle_price(String.t()) :: {:ok, Decimal.t()} | {:error, :no_price}
  defmemo oracle_price(ticker), expires_in: Rujira.cache_ttl() do
    fetch_oracle_price(ticker, [])
  end

  @doc """
  As `oracle_price/1`, read at `opts[:height]` when one is given - a height read
  is never cached. Without a `:height` this is `oracle_price/1`, so the other
  opts are not applied.
  """
  @spec oracle_price(String.t(), Node.opts()) :: {:ok, Decimal.t()} | {:error, :no_price}
  def oracle_price(ticker, opts) do
    Node.at_height(
      opts,
      fn -> fetch_oracle_price(ticker, opts) end,
      fn -> oracle_price(ticker) end
    )
  end

  @doc """
  Memoized FIN-derived price: mid-price of the asset's default pair (a stable
  pair when one exists, otherwise the first pair quoting that asset), multiplied
  by the quote asset's USD price.

  Invalidate with `Memoize.invalidate(Rujira.Prices.Default, :fin_price, [ticker])`.
  """
  @spec fin_price(String.t()) :: {:ok, Decimal.t()} | {:error, :no_price}
  defmemo fin_price(ticker), expires_in: Rujira.cache_ttl() do
    fetch_fin_price(ticker, [])
  end

  @doc """
  As `fin_price/1`, read at `opts[:height]` when one is given - a height read is
  never cached. Without a `:height` this is `fin_price/1`, so the other opts are
  not applied.
  """
  @spec fin_price(String.t(), Node.opts()) :: {:ok, Decimal.t()} | {:error, :no_price}
  def fin_price(ticker, opts) do
    Node.at_height(opts, fn -> fetch_fin_price(ticker, opts) end, fn -> fin_price(ticker) end)
  end

  # --- Private ---

  defp fetch_oracle_price(ticker, opts) do
    with {:ok, %{price: %{price: price_str}}} <-
           Node.query(&Q.oracle_price/3, %QueryOraclePriceRequest{symbol: ticker}, opts),
         {:ok, price} <- Rujira.Math.to_decimal(price_str) do
      {:ok, price}
    else
      {:error, err} -> unless_height_error(err, fn -> {:error, :no_price} end)
      _ -> {:error, :no_price}
    end
  end

  defp fetch_fin_price(ticker, opts) do
    with {:ok, denom} <- Rujira.Fin.denom_for_ticker(ticker, opts),
         {:ok, pair} <- Rujira.Fin.get_default_pair(denom, opts),
         {:ok, %{book: %{center: center}}} <- Rujira.Fin.load_pair(pair, 1, opts),
         false <- Decimal.equal?(center, 0),
         {:ok, quote_asset} <- Assets.from_denom(pair.token_quote, opts),
         false <- quote_asset.ticker == ticker,
         {:ok, quote_price} <- get(quote_asset.ticker, opts) do
      {:ok, Decimal.mult(center, quote_price)}
    else
      {:error, err} -> unless_height_error(err, fn -> {:error, :no_price} end)
      _ -> {:error, :no_price}
    end
  end

  # A height read that could not be served is an error, never a default: the
  # caller asked for the state at one height and must be told that height was
  # not read. Every other error keeps today's behaviour.
  defp unless_height_error({:height_unavailable, _} = err, _fallback), do: {:error, err}
  defp unless_height_error({:height_mismatch, _, _} = err, _fallback), do: {:error, err}
  defp unless_height_error(:invalid_height, _fallback), do: {:error, :invalid_height}
  defp unless_height_error(:height_not_supported, _fallback), do: {:error, :height_not_supported}
  defp unless_height_error(_err, fallback), do: fallback.()
end
