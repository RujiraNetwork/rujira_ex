defmodule Rujira.Prices.Noop do
  @moduledoc "No-op prices adapter. Returns 0 for all lookups, at any height."
  @behaviour Rujira.Prices

  alias Rujira.Node

  @impl true
  @spec get(String.t()) :: {:ok, Decimal.t()}
  def get(_ticker), do: {:ok, Decimal.new(0)}

  @impl true
  @spec get(String.t(), Node.opts()) :: {:ok, Decimal.t()}
  def get(_ticker, _opts), do: {:ok, Decimal.new(0)}

  @impl true
  @spec value_usd(String.t(), integer(), integer()) :: integer()
  @spec value_usd(String.t(), integer(), integer(), Node.opts()) :: integer()
  def value_usd(_ticker, _amount, _decimals \\ 8, _opts \\ []), do: 0
end
