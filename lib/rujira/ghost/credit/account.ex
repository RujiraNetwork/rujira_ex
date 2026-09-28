defmodule Rujira.Ghost.Credit.Account do
  @moduledoc """
  A credit account: the `rujira-account` contract a credit contract opens for an
  owner, its collateral, its debts and its owner's liquidation preferences.

  `ltv`, and the value on every collateral and debt, are the credit contract's
  own response fields, in the unit it priced them in - nothing is re-derived and
  no total is added here.

  Struct, construction, and queries. Use `Rujira.Ghost` as the public API.
  """

  alias Rujira.Cache
  alias Rujira.Contracts
  alias Rujira.Ghost.Credit.Collateral
  alias Rujira.Ghost.Credit.Debt
  alias Rujira.Ghost.Credit.LiquidationPreferences
  alias Rujira.Math
  alias Rujira.Node
  alias Rujira.String

  @max_limit 100

  # --- Struct ---

  defstruct id: nil,
            credit: nil,
            owner: nil,
            account: nil,
            tag: nil,
            collaterals: [],
            debts: [],
            ltv: Decimal.new(0),
            liquidation_preferences: nil

  @type t :: %__MODULE__{
          id: String.t() | nil,
          credit: String.t() | nil,
          owner: String.t() | nil,
          account: String.t() | nil,
          tag: String.t() | nil,
          collaterals: [Collateral.t()],
          debts: [Debt.t()],
          ltv: Decimal.t(),
          liquidation_preferences: LiquidationPreferences.t() | nil
        }

  # --- Construction ---

  @doc """
  Builds an account from an `AccountResponse` and the address of the credit
  contract that served it - the response names the account, not its contract.
  """
  @spec new(String.t(), map()) :: {:ok, t()} | {:error, term()}
  def new(credit, %{
        "owner" => owner,
        "account" => account,
        "tag" => tag,
        "collaterals" => collaterals,
        "debts" => debts,
        "ltv" => ltv,
        "liquidation_preferences" => liquidation_preferences
      })
      when is_binary(credit) and is_binary(account) and is_list(collaterals) and is_list(debts) do
    with {:ok, collaterals} <- Rujira.Enum.reduce_while_ok(collaterals, [], &Collateral.new/1),
         {:ok, debts} <- Rujira.Enum.reduce_while_ok(debts, [], &Debt.new/1),
         {:ok, ltv} <- Math.to_decimal(ltv),
         {:ok, liquidation_preferences} <- LiquidationPreferences.new(liquidation_preferences) do
      {:ok,
       %__MODULE__{
         id: "#{credit}/#{account}",
         credit: credit,
         owner: owner,
         account: account,
         tag: String.nil_if_empty(tag),
         collaterals: collaterals,
         debts: debts,
         ltv: ltv,
         liquidation_preferences: liquidation_preferences
       }}
    end
  end

  def new(_, _), do: {:error, :invalid_attrs}

  # --- Queries ---

  @doc """
  Reads one account of a credit contract by the account's address.

  An address the credit contract holds no account for is
  `{:error, :not_found}`.
  """
  @spec get(String.t(), String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def get(credit, account, opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, res} <- account(credit, account, opts) do
      new(credit, res)
    end
  end

  @doc """
  Lists every account of a credit contract, paging `all_accounts` #{@max_limit}
  at a time.
  """
  @spec list(String.t(), Node.opts()) :: {:ok, [t()]} | {:error, term()}
  def list(credit, opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, accounts} <- all_accounts(credit, opts) do
      Rujira.Enum.reduce_while_ok(accounts, [], &new(credit, &1))
    end
  end

  @doc """
  Lists an owner's accounts on a credit contract, optionally filtered by the
  `tag` they were created with.
  """
  @spec list_by_owner(String.t(), String.t(), String.t() | nil, Node.opts()) ::
          {:ok, [t()]} | {:error, term()}
  def list_by_owner(credit, owner, tag \\ nil, opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, accounts} <- accounts_by_owner(credit, owner, tag, opts) do
      Rujira.Enum.reduce_while_ok(accounts, [], &new(credit, &1))
    end
  end

  @doc """
  Resolves an account from its `"<credit>/<account>"` id.

  An id that is not that shape is `{:error, :invalid_id}`; one that names no
  account on the credit contract is `{:error, :not_found}`.
  """
  @spec from_id(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def from_id(id, opts \\ []) do
    case String.split(id, "/") do
      [credit, account] -> get(credit, account, opts)
      _ -> {:error, :invalid_id}
    end
  end

  @doc """
  The address the credit contract would open an owner's next account at, for the
  given `salt` - the raw salt bytes, base64-encoded on the wire.

  Deterministic given the credit contract's `code_id`, so it is cached per
  `Rujira.Cache` against `{:contract, credit}`.
  """
  @spec predict(String.t(), String.t(), binary(), Node.opts()) ::
          {:ok, String.t()} | {:error, term()}
  def predict(credit, owner, salt, opts \\ []) when is_binary(salt) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, address} <-
           Cache.fetch(
             {__MODULE__, :predict, [credit, owner, salt]},
             [{:contract, credit}],
             opts,
             fn _height ->
               Contracts.query_state_smart(
                 credit,
                 %{predict: %{owner: owner, salt: Base.encode64(salt)}},
                 opts
               )
             end
           ) do
      predicted(address)
    end
  end

  # --- Private ---

  # The contract answers `predict` with a bare `Addr` - a JSON string, not an
  # object - so anything else is a malformed reply rather than an address.
  @spec predicted(term()) :: {:ok, String.t()} | {:error, :invalid_response}
  defp predicted(address) when is_binary(address), do: {:ok, address}
  defp predicted(_), do: {:error, :invalid_response}

  defp account(credit, account, opts) do
    {__MODULE__, :query_account, [credit, account]}
    |> Cache.fetch([:per_block], opts, fn _height -> fetch_account(credit, account, opts) end)
    |> not_found()
  end

  defp accounts_by_owner(credit, owner, tag, opts) do
    Cache.fetch(
      {__MODULE__, :query_accounts_by_owner, [credit, owner, tag]},
      [:per_block],
      opts,
      fn _height -> fetch_accounts_by_owner(credit, owner, tag, opts) end
    )
  end

  defp all_accounts(credit, opts) do
    Cache.fetch(
      {__MODULE__, :query_all_accounts, [credit]},
      [:per_block],
      opts,
      fn _height -> fetch_all_accounts_page(credit, nil, opts) end
    )
  end

  defp fetch_account(credit, account, opts) do
    Contracts.query_state_smart(credit, %{account: account}, opts)
  end

  defp fetch_accounts_by_owner(credit, owner, tag, opts) do
    credit
    |> Contracts.query_state_smart(%{accounts: %{owner: owner, tag: tag}}, opts)
    |> accounts()
  end

  defp fetch_all_accounts_page(credit, cursor, opts) do
    credit
    |> Contracts.query_state_smart(%{all_accounts: %{cursor: cursor, limit: @max_limit}}, opts)
    |> Contracts.paginate("accounts", @max_limit, fn accounts ->
      fetch_all_accounts_page(credit, accounts |> List.last() |> Map.get("account"), opts)
    end)
  end

  defp accounts({:ok, %{"accounts" => accounts}}) when is_list(accounts), do: {:ok, accounts}
  defp accounts({:ok, _}), do: {:error, :invalid_attrs}
  defp accounts({:error, _} = err), do: err

  # The contract loads the account bare, so an address it holds no account for is
  # a `StdError::NotFound` - a missing account, not a failed read.
  defp not_found({:error, err}) do
    if Contracts.not_found?(err), do: {:error, :not_found}, else: {:error, err}
  end

  defp not_found(other), do: other
end
