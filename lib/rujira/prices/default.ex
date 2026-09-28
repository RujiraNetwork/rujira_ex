defmodule Rujira.Prices.Default do
  @moduledoc """
  Default price adapter: oracle → FIN book mid-price fallback.

  The fallback is reached for one reason only: the oracle has no price for the
  asset. Any other error — a transport failure, an unservable height, an
  unparseable price — is returned unchanged rather than sent down a second path
  that would answer with a price nobody asked for.

  Every lookup takes a trailing `opts`, forwarded to `Rujira.Node.query/3`, so a
  price can be read at a `height:`. Both legs are cached per `Rujira.Cache`,
  resolved at `opts[:height]` or - without one - at the head. A price moves
  every block with no event of its own, so each is read per block: the oracle
  price directly, the FIN price through the book it is derived from.
  """
  @behaviour Rujira.Prices

  alias Rujira.Amount
  alias Rujira.Cache
  alias Rujira.Node
  alias Thorchain.Types.Query.Stub, as: Q
  alias Thorchain.Types.QueryOraclePriceRequest

  # `queryOraclePrice` (thornode `x/thorchain/querier.go:4389`) answers a symbol
  # it holds no price for with the error of `Keeper.GetPrice`
  # (`x/thorchain/keeper/v1/keeper_oracle.go:38`), rendered as
  # `"fail to get price for symbol '<symbol>': Price not found: <symbol>"`. It
  # is a plain Go error, so Cosmos SDK v0.53.0 gives it a code by serving path:
  # the node's own gRPC server passes it through unchanged -> gRPC status 2
  # (Unknown); the ABCI query path (`baseapp/abci.go:1168`
  # `gRPCErrorToSDKError`) reclassifies it as `ErrInvalidRequest` and appends
  # ": invalid request" -> gRPC status 3 (InvalidArgument). The status code
  # identifies the path, not the error, so both are treated the same here.
  @price_not_found ~r/Price not found: (?<symbol>.+?)(:|$)/

  @impl true
  def get(ticker), do: get(ticker, [])

  @impl true
  # bRUNE (bonded RUNE) is priced 1:1 with RUNE.
  def get("bRUNE", opts), do: get("RUNE", opts)

  def get(ticker, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      case oracle_price(ticker, opts) do
        {:error, :no_price} -> fin_price(ticker, opts)
        result -> result
      end
    end
  end

  @impl true
  def value_usd(ticker, amount, decimals \\ 8, opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, price} <- get(ticker, opts) do
      {:ok, to_usd(amount, price, decimals)}
    end
  end

  @doc "The chain oracle's price for `ticker`."
  @spec oracle_price(String.t()) :: {:ok, Decimal.t()} | {:error, term()}
  def oracle_price(ticker), do: oracle_price(ticker, [])

  @doc "As `oracle_price/1`, read at `opts[:height]` when given."
  @spec oracle_price(String.t(), Node.opts()) :: {:ok, Decimal.t()} | {:error, term()}
  def oracle_price(ticker, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch({__MODULE__, :oracle_price, [ticker]}, [:per_block], opts, fn _height ->
        fetch_oracle_price(ticker, opts)
      end)
    end
  end

  @doc """
  The FIN-derived price: mid-price of the asset's default pair (a stable pair
  when one exists, otherwise the first pair quoting that asset), multiplied by
  the quote asset's USD price.
  """
  @spec fin_price(String.t()) :: {:ok, Decimal.t()} | {:error, term()}
  def fin_price(ticker), do: fin_price(ticker, [])

  @doc "As `fin_price/1`, read at `opts[:height]` when given."
  @spec fin_price(String.t(), Node.opts()) :: {:ok, Decimal.t()} | {:error, term()}
  def fin_price(ticker, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch({__MODULE__, :fin_price, [ticker]}, [:per_block], opts, fn _height ->
        fetch_fin_price(ticker, opts)
      end)
    end
  end

  # --- Private ---

  defp to_usd(amount, price, decimals) do
    amount
    |> Rujira.Math.normalize(decimals, Amount.decimals())
    |> Rujira.Math.mul_floor(price)
  end

  defp fetch_oracle_price(ticker, opts) do
    (&Q.oracle_price/3)
    |> Node.query(%QueryOraclePriceRequest{symbol: ticker}, opts)
    |> oracle_result(ticker)
  end

  # An unset price message, or a price the chain renders as absent, is the same
  # answer as the not-found error: this symbol has no oracle price.
  defp oracle_result({:ok, %{price: nil}}, _ticker), do: {:error, :no_price}

  defp oracle_result({:ok, %{price: %{price: price}}}, _ticker) do
    case Rujira.Math.to_decimal(price) do
      {:ok, nil} -> {:error, :no_price}
      result -> result
    end
  end

  defp oracle_result({:error, %GRPC.RPCError{status: status, message: message}} = err, ticker)
       when status in [2, 3] and is_binary(message) do
    case Regex.named_captures(@price_not_found, message) do
      %{"symbol" => ^ticker} -> {:error, :no_price}
      _ -> err
    end
  end

  defp oracle_result({:error, _} = err, _ticker), do: err

  # `:not_found` anywhere down this chain means FIN has no market for the asset,
  # which is `:no_price`. Every other error - a transport failure, an unservable
  # height, a denom FIN quotes that `Assets` does not know - is returned
  # unchanged.
  defp fetch_fin_price(ticker, opts) do
    with {:ok, denom} <- Rujira.Fin.denom_for_ticker(ticker, opts),
         {:ok, pair} <- Rujira.Fin.get_default_pair(denom, opts),
         {:ok, %{book: %{center: center}}} <- Rujira.Fin.load_pair(pair, 1, opts),
         {:ok, center} <- mid_price(center),
         {:ok, quote_price} <- quote_price(pair.asset_quote, ticker, opts) do
      {:ok, Rujira.Math.mul(center, quote_price)}
    else
      {:error, :not_found} -> {:error, :no_price}
      {:error, _} = err -> err
    end
  end

  # A book with no level on one side has no mid-price, and a mid-price of zero
  # prices nothing: either way FIN quotes the asset at no price at all.
  defp mid_price(nil), do: {:error, :no_price}
  defp mid_price(%Decimal{coef: 0}), do: {:error, :no_price}
  defp mid_price(%Decimal{} = center), do: {:ok, center}

  # A pair quoting the asset against itself prices it in itself, which says
  # nothing about its USD price.
  defp quote_price(%{ticker: ticker}, ticker, _opts), do: {:error, :no_price}
  defp quote_price(%{ticker: quote_ticker}, _ticker, opts), do: get(quote_ticker, opts)
end
