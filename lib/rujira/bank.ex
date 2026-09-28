defmodule Rujira.Bank do
  @moduledoc """
  Public API for Cosmos bank-module queries against the connected node.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidation is `Rujira.Cache`'s: it follows from a read's
  sources, not from a call here.

  Every query takes a trailing `opts`, forwarded to `Rujira.Node.query/3`, so a
  caller can read at a `height:`. Every lookup here is cached per
  `Rujira.Cache`, resolved at `opts[:height]` or, without one, at the head -
  see the resource module.
  """

  alias Rujira.Bank.Balance
  alias Rujira.Bank.Holder
  alias Rujira.Bank.Supply

  # --- Balance ---

  defdelegate balance(address, asset, opts \\ []), to: Balance, as: :get
  defdelegate balances(address, opts \\ []), to: Balance, as: :list
  defdelegate spendable_balances(address, opts \\ []), to: Balance, as: :list_spendable

  # --- Supply ---

  defdelegate supply(asset, opts \\ []), to: Supply, as: :get
  defdelegate total_supply(opts \\ []), to: Supply, as: :list

  # --- Holder ---

  defdelegate holders(asset), to: Holder
  defdelegate holders(asset, opts), to: Holder
end
