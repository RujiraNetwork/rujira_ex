defmodule Rujira.Prices.Noop do
  @moduledoc "No-op prices adapter. Returns 0 for all lookups."
  @behaviour Rujira.Prices

  @impl true
  @spec get(String.t()) :: {:ok, Decimal.t()}
  def get(_ticker), do: {:ok, Decimal.new(0)}

  @impl true
  @spec value_usd(String.t(), integer(), integer()) :: integer()
  def value_usd(_ticker, _amount, _decimals \\ 8), do: 0
end
