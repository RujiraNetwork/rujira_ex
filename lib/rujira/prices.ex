defmodule Rujira.Prices do
  @moduledoc """
  Behaviour and configurable delegator for asset price lookups.

  Consumers configure the implementation via application env:

      config :rujira_core, prices: MyApp.PricesImpl

  Defaults to `Rujira.Prices.Noop` which returns 0 for all lookups.
  """

  @callback value_usd(String.t(), integer(), integer()) :: integer()

  @spec value_usd(String.t(), integer(), integer()) :: integer()
  def value_usd(symbol, amount, decimals \\ 8) do
    impl().value_usd(symbol, amount, decimals)
  end

  defp impl do
    Application.get_env(:rujira_core, :prices, Rujira.Prices.Noop)
  end
end

defmodule Rujira.Prices.Noop do
  @moduledoc "No-op prices adapter. Returns 0 for all lookups."
  @behaviour Rujira.Prices

  @impl true
  def value_usd(_symbol, _amount, _decimals \\ 8), do: 0
end
