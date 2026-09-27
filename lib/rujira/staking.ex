defmodule Rujira.Staking do
  @moduledoc """
  Public API for the rujira-staking protocol.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidate cache on the resource module, not here.

  Every query takes a trailing `opts`, forwarded to `Rujira.Node.query/3`, so a
  caller can read a whole composite at one `height:` - `load_account/3` reads
  the pool status, the contract account and the bank balance at the same one.
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
end
