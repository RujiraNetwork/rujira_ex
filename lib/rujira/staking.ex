defmodule Rujira.Staking do
  @moduledoc """
  Public API for the rujira-staking protocol.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidate cache on the resource module, not here.
  """

  alias Rujira.Staking.Pool
  alias Rujira.Staking.Pool.Account
  alias Rujira.Staking.Pool.Status

  # --- Pool ---

  defdelegate get_pool(address), to: Pool, as: :get
  defdelegate list_pools(), to: Pool, as: :list
  defdelegate load_pool(pool), to: Status, as: :load
  defdelegate pool_from_id(id), to: Pool, as: :from_id

  # --- Account ---

  defdelegate load_account(pool, owner), to: Account, as: :load
  defdelegate account_from_id(id), to: Account, as: :from_id
end
