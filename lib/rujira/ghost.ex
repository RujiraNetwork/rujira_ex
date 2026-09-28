defmodule Rujira.Ghost do
  @moduledoc """
  Public API for the Ghost lending protocol.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidation is `Rujira.Cache`'s: it follows from a read's
  sources, not from a call here.

  Every query takes a trailing `opts`, forwarded to `Rujira.Node.query/3`, so a
  caller can read a whole composite at one `height:`. Every lookup here is
  cached per `Rujira.Cache`, resolved at `opts[:height]` or, without one, at the
  head - see the resource module.

  `vault_account_value/2` reaches no node: it is pure over a vault whose status
  is loaded - see `Rujira.Ghost.Vault.Account`.

  Ghost has two families: the vaults that lend (`Rujira.Ghost.Vault`) and the
  credit contracts that borrow from them on an account holder's behalf
  (`Rujira.Ghost.Credit`).
  """

  alias Rujira.Ghost.Credit
  alias Rujira.Ghost.Credit.Account, as: CreditAccount
  alias Rujira.Ghost.Vault
  alias Rujira.Ghost.Vault.Account
  alias Rujira.Ghost.Vault.Borrower
  alias Rujira.Ghost.Vault.Delegate
  alias Rujira.Ghost.Vault.Status

  # --- Vault ---

  defdelegate list_vaults(opts \\ []), to: Vault, as: :list
  defdelegate get_vault(address, opts \\ []), to: Vault, as: :get
  defdelegate vault_from_id(id, opts \\ []), to: Vault, as: :from_id
  defdelegate load_vault(vault, opts \\ []), to: Status, as: :load

  # --- Borrower ---

  defdelegate vault_borrower(address, borrower, opts \\ []), to: Borrower, as: :get
  defdelegate vault_borrowers(address, opts \\ []), to: Borrower, as: :list

  # --- Delegate ---

  defdelegate vault_delegate(address, borrower, delegate, opts \\ []), to: Delegate, as: :get

  # --- Account ---

  defdelegate load_vault_account(vault, account, opts \\ []), to: Account, as: :load
  defdelegate vault_account_from_id(id, opts \\ []), to: Account, as: :from_id
  defdelegate vault_account_value(account, vault), to: Account, as: :value

  # --- Credit ---

  defdelegate get_credit(address, opts \\ []), to: Credit, as: :get
  defdelegate list_credits(opts \\ []), to: Credit, as: :list
  defdelegate credit_from_id(id, opts \\ []), to: Credit, as: :from_id
  defdelegate load_credit(credit, opts \\ []), to: Credit, as: :load

  # --- Credit account ---

  defdelegate credit_account(credit, account, opts \\ []), to: CreditAccount, as: :get
  defdelegate credit_accounts(credit, opts \\ []), to: CreditAccount, as: :list

  defdelegate credit_accounts_by_owner(credit, owner, tag \\ nil, opts \\ []),
    to: CreditAccount,
    as: :list_by_owner

  defdelegate credit_account_from_id(id, opts \\ []), to: CreditAccount, as: :from_id

  defdelegate credit_account_predict(credit, owner, salt, opts \\ []),
    to: CreditAccount,
    as: :predict
end
