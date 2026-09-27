defmodule Rujira.Ghost do
  @moduledoc """
  Public API for the Ghost lending protocol.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidate cache on the resource module, not here.

  Every query takes a trailing `opts`, forwarded to `Rujira.Node.query/3`, so a
  caller can read a whole composite at one `height:`. A memoized query's opts
  arity reads the node uncached when given a `:height` - see the resource
  module.
  """

  alias Rujira.Ghost.Vault
  alias Rujira.Ghost.Vault.Account
  alias Rujira.Ghost.Vault.Borrower
  alias Rujira.Ghost.Vault.Delegate
  alias Rujira.Ghost.Vault.Status

  # --- Vault ---

  defdelegate list_vaults(opts \\ []), to: Vault, as: :list
  defdelegate get_vault(address, opts \\ []), to: Vault, as: :get
  defdelegate vault_from_id(id, opts \\ []), to: Vault, as: :get
  defdelegate load_vault(vault, opts \\ []), to: Status, as: :load

  # --- Borrower ---

  defdelegate vault_borrower(address, borrower, opts \\ []), to: Borrower, as: :get
  defdelegate vault_borrowers(address, opts \\ []), to: Borrower, as: :list

  # --- Delegate ---

  defdelegate vault_delegate(address, borrower, delegate, opts \\ []), to: Delegate, as: :get

  # --- Account ---

  defdelegate load_vault_account(vault, account, opts \\ []), to: Account, as: :load
  defdelegate vault_account_from_id(id, opts \\ []), to: Account, as: :from_id
end
