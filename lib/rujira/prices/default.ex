defmodule Rujira.Prices.Default do
  @moduledoc """
  Default price adapter: oracle → FIN book mid-price fallback.
  """
  @behaviour Rujira.Prices

  use Memoize

  alias Rujira.Amount
  alias Thorchain.Types.Query.Stub, as: Q
  alias Thorchain.Types.QueryOraclePriceRequest

  @impl true
  def get(symbol) do
    with {:error, _} <- oracle_price(symbol) do
      fin_price(symbol)
    end
  end

  @impl true
  def value_usd(symbol, amount, decimals \\ 8) do
    case get(symbol) do
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

  defmemo oracle_price(symbol), expires_in: Rujira.cache_ttl() do
    with {:ok, %{price: %{price: price_str}}} <-
           Rujira.Node.query(&Q.oracle_price/2, %QueryOraclePriceRequest{symbol: symbol}),
         {price, ""} <- Decimal.parse(price_str) do
      {:ok, price}
    else
      _ -> {:error, :no_price}
    end
  end

  defmemo fin_price(symbol), expires_in: Rujira.cache_ttl() do
    denom = String.downcase(symbol)

    with {:ok, pair} <- Rujira.Fin.get_stable_pair(denom),
         {:ok, %{book: %{center: center}}} <- Rujira.Fin.load_pair(pair, 1),
         false <- Decimal.equal?(center, 0) do
      {:ok, center}
    else
      _ -> {:error, :no_price}
    end
  end

end
