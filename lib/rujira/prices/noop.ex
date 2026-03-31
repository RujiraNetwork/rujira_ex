defmodule Rujira.Prices.Noop do
  @moduledoc "No-op prices adapter. Returns 0 for all lookups."
  @behaviour Rujira.Prices

  @impl true
  def get(_symbol), do: {:ok, Decimal.new(0)}

  @impl true
  def value_usd(_symbol, _amount, _decimals \\ 8), do: 0
end
