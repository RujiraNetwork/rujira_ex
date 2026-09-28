defmodule Rujira.Staking do
  @moduledoc """
  Public API for the rujira-staking protocol.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidation is `Rujira.Cache`'s: it follows from a read's
  sources, not from a call here.

  Every query takes a trailing `opts`, forwarded to `Rujira.Node.query/3`, so a
  caller can read a whole composite at one `height:`.

  `account_revenue_share/2` and `account_liquid_size/2` reach no node: they are
  pure over a pool whose status is loaded - see `Rujira.Staking.Pool.Account`.
  """

  alias Rujira.Staking.Pool
  alias Rujira.Staking.Pool.Account
  alias Rujira.Staking.Pool.Status

  # --- Pool ---

  defdelegate get_pool(address, opts \\ []), to: Pool, as: :get
  defdelegate list_pools(opts \\ []), to: Pool, as: :list
  defdelegate load_pool(pool, opts \\ []), to: Status, as: :load
  defdelegate pool_from_id(id, opts \\ []), to: Pool, as: :from_id

  # --- Account ---

  defdelegate load_account(pool, owner, opts \\ []), to: Account, as: :load
  defdelegate account_from_id(id, opts \\ []), to: Account, as: :from_id
  defdelegate account_revenue_share(account, pool), to: Account, as: :revenue_share
  defdelegate account_liquid_size(shares, pool), to: Account, as: :liquid_size
end
