defmodule Rujira.Prices.Noop do
  @moduledoc "No-op prices adapter. Returns 0 for all lookups."
  @behaviour Rujira.Prices

  @impl true
  @spec get(String.t()) :: {:ok, Decimal.t()}
  def get(_symbol), do: {:ok, Decimal.new(0)}

  @impl true
  @spec value_usd(String.t(), non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  def value_usd(_symbol, _amount, _decimals \\ 8), do: 0
end
