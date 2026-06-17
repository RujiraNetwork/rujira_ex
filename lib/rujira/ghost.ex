defmodule Rujira.Ghost do
  @moduledoc """
  Public API for the Ghost lending protocol.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidate cache on the resource module, not here.
  """

  alias Rujira.Ghost.Vault
  alias Rujira.Ghost.Vault.Account
  alias Rujira.Ghost.Vault.Borrower
  alias Rujira.Ghost.Vault.Delegate
  alias Rujira.Ghost.Vault.Status

  # --- Vault ---

  defdelegate list_vaults(), to: Vault, as: :list
  defdelegate get_vault(address), to: Vault, as: :get
  defdelegate vault_from_id(id), to: Vault, as: :get
  defdelegate load_vault(vault), to: Status, as: :load

  # --- Borrower ---

  defdelegate vault_borrower(address, borrower), to: Borrower, as: :get
  defdelegate vault_borrowers(address), to: Borrower, as: :list

  # --- Delegate ---

  defdelegate vault_delegate(address, borrower, delegate), to: Delegate, as: :get

  # --- Account ---

  defdelegate load_vault_account(vault, account), to: Account, as: :load
  defdelegate vault_account_from_id(id), to: Account, as: :from_id
end
