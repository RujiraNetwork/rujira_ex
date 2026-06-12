defmodule Rujira.Prices.Default do
  @moduledoc """
  Default price adapter: oracle → FIN book mid-price fallback.
  """
  @behaviour Rujira.Prices

  use Memoize

  alias Rujira.Amount
  alias Rujira.Assets
  alias Thorchain.Types.Query.Stub, as: Q
  alias Thorchain.Types.QueryOraclePriceRequest

  @impl true
  # bRUNE (bonded RUNE) is priced 1:1 with RUNE.
  def get("bRUNE"), do: get("RUNE")

  def get(ticker) do
    with {:error, _} <- oracle_price(ticker) do
      fin_price(ticker)
    end
  end

  @impl true
  def value_usd(ticker, amount, decimals \\ 8) do
    case get(ticker) do
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
    with {:ok, %{price: %{price: price_str}}} <-
           Rujira.Node.query(&Q.oracle_price/2, %QueryOraclePriceRequest{symbol: ticker}),
         {:ok, price} <- Rujira.Math.to_decimal(price_str) do
      {:ok, price}
    else
      _ -> {:error, :no_price}
    end
  end

  @doc """
  Memoized FIN-derived price: mid-price of the asset's default pair (a stable
  pair when one exists, otherwise the first pair quoting that asset), multiplied
  by the quote asset's USD price.

  Invalidate with `Memoize.invalidate(Rujira.Prices.Default, :fin_price, [ticker])`.
  """
  @spec fin_price(String.t()) :: {:ok, Decimal.t()} | {:error, :no_price}
  defmemo fin_price(ticker), expires_in: Rujira.cache_ttl() do
    with {:ok, denom} <- Rujira.Fin.denom_for_ticker(ticker),
         {:ok, pair} <- Rujira.Fin.get_default_pair(denom),
         {:ok, %{book: %{center: center}}} <- Rujira.Fin.load_pair(pair, 1),
         false <- Decimal.equal?(center, 0),
         {:ok, quote_asset} <- Assets.from_denom(pair.token_quote),
         false <- quote_asset.ticker == ticker,
         {:ok, quote_price} <- get(quote_asset.ticker) do
      {:ok, Decimal.mult(center, quote_price)}
    else
      _ -> {:error, :no_price}
    end
  end
end
