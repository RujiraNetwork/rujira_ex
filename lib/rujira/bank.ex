defmodule Rujira.Bank do
  @moduledoc """
  Public API for Cosmos bank-module queries against the connected node.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidate cache on the resource module, not here.
  """

  alias Rujira.Bank.Balance
  alias Rujira.Bank.Holder
  alias Rujira.Bank.Supply

  # --- Balance ---

  defdelegate balance(address, asset), to: Balance, as: :get
  defdelegate balances(address), to: Balance, as: :list
  defdelegate spendable_balances(address), to: Balance, as: :list_spendable

  # --- Supply ---

  defdelegate supply(asset), to: Supply, as: :get
  defdelegate total_supply(), to: Supply, as: :list

  # --- Holder ---

  defdelegate holders(asset), to: Holder
  defdelegate holders(asset, limit), to: Holder
end
