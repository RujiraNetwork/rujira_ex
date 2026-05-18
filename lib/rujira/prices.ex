defmodule Rujira.Prices do
  @moduledoc """
  Behaviour and configurable delegator for asset price lookups.

  Ships with two built-in implementations:

    * `Rujira.Prices.Default` — oracle → FIN book mid-price fallback
    * `Rujira.Prices.Noop` — returns 0 (useful for tests)

  Consumers can override via application env:

      config :rujira_ex, prices: MyApp.CustomPrices

  Defaults to `Rujira.Prices.Default`.

  ## Cache TTL

  The default implementation memoizes prices using the global cache TTL.
  See `Rujira.cache_ttl/0`.
  """

  @callback get(String.t()) :: {:ok, Decimal.t()} | {:error, term()}
  @callback value_usd(String.t(), integer(), integer()) :: integer()

  @spec get(String.t()) :: {:ok, Decimal.t()} | {:error, term()}
  def get(symbol), do: impl().get(symbol)

  @spec value_usd(String.t(), integer(), integer()) :: integer()
  def value_usd(symbol, amount, decimals \\ 8) do
    impl().value_usd(symbol, amount, decimals)
  end

  defp impl do
    Application.get_env(:rujira_ex, :prices, Rujira.Prices.Default)
  end
end
