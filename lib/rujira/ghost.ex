defmodule Rujira.Ghost do
  @moduledoc """
  Public API for the Ghost lending protocol.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidate cache on the resource module, not here.
  """

  alias Rujira.Ghost.Vault

  # --- Vault ---

  defdelegate list_vaults(), to: Vault, as: :list
  defdelegate get_vault(address), to: Vault, as: :get
  defdelegate vault_from_id(id), to: Vault, as: :get
  defdelegate load_vault(vault), to: Vault, as: :load
  defdelegate vault_borrower(address, borrower), to: Vault, as: :borrower
  defdelegate vault_borrowers(address), to: Vault, as: :borrowers
  defdelegate vault_delegate(address, borrower, delegate), to: Vault, as: :delegate
end
