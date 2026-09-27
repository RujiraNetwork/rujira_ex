defmodule Rujira.Prices do
  @moduledoc """
  Behaviour and configurable delegator for asset price lookups.

  Ships with two built-in implementations:

    * `Rujira.Prices.Default` — oracle → FIN book mid-price fallback
    * `Rujira.Prices.Noop` — returns a zero price (useful for tests)

  Consumers can override via application env:

      config :rujira_ex, prices: MyApp.CustomPrices

  Defaults to `Rujira.Prices.Default`.

  ## Cache TTL

  The default implementation memoizes prices using the global cache TTL.
  See `Rujira.cache_ttl/0`.

  ## Query options

  `get/2` and `value_usd/4` take a trailing `opts`, forwarded to
  `Rujira.Node.query/3`, so a position read at a `height:` is valued with the
  prices of that height rather than of now.

  Both are *optional* callbacks — an implementation written before they existed
  still satisfies the behaviour. Asked for a `:height` such an implementation
  cannot serve, both return `{:error, :height_not_supported}`: a price from the
  present is not a price at that height, and returning one would misvalue the
  position silently.

  Without a `:height`, both fall through to the arity the implementation does
  export, so the other opts are not applied.
  """

  alias Rujira.Node

  @callback get(String.t()) :: {:ok, Decimal.t()} | {:error, term()}
  @callback get(String.t(), Node.opts()) :: {:ok, Decimal.t()} | {:error, term()}
  @callback value_usd(String.t(), integer(), integer()) :: {:ok, integer()} | {:error, term()}
  @callback value_usd(String.t(), integer(), integer(), Node.opts()) ::
              {:ok, integer()} | {:error, term()}

  @optional_callbacks get: 2, value_usd: 4

  @doc """
  Fetches the USD price for an asset.

  `ticker` must be the bare ticker from `Rujira.Assets.Asset.ticker` (e.g. `"USDC"`),
  not the full symbol (e.g. `"USDC-0xAbc..."`).
  """
  @spec get(String.t()) :: {:ok, Decimal.t()} | {:error, term()}
  def get(ticker), do: impl().get(ticker)

  @doc """
  As `get/1`, priced at `opts[:height]` when one is given.

  `{:error, :height_not_supported}` when a `:height` is given and the configured
  implementation does not export `get/2`.
  """
  @spec get(String.t(), Node.opts()) :: {:ok, Decimal.t()} | {:error, term()}
  def get(ticker, opts) do
    impl = impl()

    if exports?(impl, :get, 2) do
      impl.get(ticker, opts)
    else
      Node.at_height(opts, fn -> {:error, :height_not_supported} end, fn -> impl.get(ticker) end)
    end
  end

  @doc """
  Values `amount` of `ticker` in USD, priced at `opts[:height]` when one is given.

  `{:error, :height_not_supported}` when a `:height` is given and the configured
  implementation does not export `value_usd/4`.
  """
  @spec value_usd(String.t(), integer(), integer()) :: {:ok, integer()} | {:error, term()}
  @spec value_usd(String.t(), integer(), integer(), Node.opts()) ::
          {:ok, integer()} | {:error, term()}
  def value_usd(ticker, amount, decimals \\ 8, opts \\ []) do
    impl = impl()

    if exports?(impl, :value_usd, 4) do
      impl.value_usd(ticker, amount, decimals, opts)
    else
      Node.at_height(
        opts,
        fn -> {:error, :height_not_supported} end,
        fn -> impl.value_usd(ticker, amount, decimals) end
      )
    end
  end

  # --- Private ---

  defp exports?(module, fun, arity) do
    Code.ensure_loaded(module)
    function_exported?(module, fun, arity)
  end

  defp impl do
    Application.get_env(:rujira_ex, :prices, Rujira.Prices.Default)
  end
end
