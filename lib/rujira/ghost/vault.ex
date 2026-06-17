defmodule Rujira.Ghost.Vault do
  @moduledoc """
  A Ghost money-market vault: a single-denom lending pool that whitelisted
  market contracts borrow from.

  Struct, construction, and queries. Use `Rujira.Ghost` as the public API.
  """

  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Ghost.Vault.Borrower
  alias Rujira.Ghost.Vault.Delegate
  alias Rujira.Ghost.Vault.Interest
  alias Rujira.Ghost.Vault.Status
  alias Rujira.Math

  use Memoize

  @max_limit 100

  # --- Struct ---

  defstruct id: nil,
            address: nil,
            denom: nil,
            receipt_denom: nil,
            interest: nil,
            fee: Decimal.new(0),
            fee_address: nil,
            status: :not_loaded

  @type t :: %__MODULE__{
          id: String.t() | nil,
          address: String.t() | nil,
          denom: String.t() | nil,
          receipt_denom: String.t() | nil,
          interest: Interest.t() | nil,
          fee: Decimal.t(),
          fee_address: String.t() | nil,
          status: :not_loaded | Status.t()
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "address" => address,
        "denom" => denom,
        "interest" => interest,
        "fee" => fee,
        "fee_address" => fee_address
      }) do
    with {:ok, interest} <- Interest.new(interest),
         {:ok, fee} <- Math.to_decimal(fee) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         denom: denom,
         receipt_denom: "x/ghost-vault/#{denom}",
         interest: interest,
         fee: fee,
         fee_address: fee_address
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Queries ---

  @spec get(String.t()) :: {:ok, t()} | {:error, term()}
  def get(address), do: Contracts.get({__MODULE__, address})

  @doc """
  Lists all deployed Ghost vaults.

  Not memoized: `Deployments.list_targets/1` and `get/1` are already cached, so
  invalidate those rather than this.
  """
  @spec list() :: {:ok, [t()]} | {:error, term()}
  def list do
    __MODULE__
    |> Deployments.list_targets()
    |> Rujira.Enum.reduce_async_while_ok(fn %{address: address} ->
      Contracts.get({__MODULE__, address})
    end)
  end

  @doc "Loads the vault's live status into the `status` field."
  @spec load(t()) :: {:ok, t()} | {:error, term()}
  def load(%__MODULE__{address: address} = vault) do
    with {:ok, res} <- query_status(address),
         {:ok, status} <- Status.new(res) do
      {:ok, %{vault | status: status}}
    end
  end

  @spec borrower(String.t(), String.t()) :: {:ok, Borrower.t()} | {:error, term()}
  def borrower(address, borrower) do
    with {:ok, res} <- query_borrower(address, borrower) do
      Borrower.new(res)
    end
  end

  @spec borrowers(String.t()) :: {:ok, [Borrower.t()]} | {:error, term()}
  def borrowers(address) do
    with {:ok, borrowers} <- query_borrowers(address) do
      Rujira.Enum.reduce_while_ok(borrowers, &Borrower.new/1)
    end
  end

  @spec delegate(String.t(), String.t(), String.t()) :: {:ok, Delegate.t()} | {:error, term()}
  def delegate(address, borrower, delegate) do
    with {:ok, res} <- query_delegate(address, borrower, delegate) do
      Delegate.new(res)
    end
  end

  @doc """
  Memoized fetch of a vault's live status.

  Invalidate with `Memoize.invalidate(Rujira.Ghost.Vault, :query_status, [address])`.
  """
  @spec query_status(String.t()) :: {:ok, map()} | {:error, term()}
  defmemo query_status(address) do
    Contracts.query_state_smart(address, %{status: %{}})
  end

  @doc """
  Memoized fetch of a borrower's raw position on a vault.

  Invalidate with `Memoize.invalidate(Rujira.Ghost.Vault, :query_borrower, [address, borrower])`.
  """
  @spec query_borrower(String.t(), String.t()) :: {:ok, map()} | {:error, term()}
  defmemo query_borrower(address, borrower) do
    Contracts.query_state_smart(address, %{borrower: %{addr: borrower}})
  end

  @doc """
  Memoized fetch of all raw borrower positions on a vault, paginated internally.

  Invalidate with `Memoize.invalidate(Rujira.Ghost.Vault, :query_borrowers, [address])`.
  """
  @spec query_borrowers(String.t()) :: {:ok, [map()]} | {:error, term()}
  defmemo query_borrowers(address) do
    query_borrowers_page(address, nil)
  end

  @doc """
  Memoized fetch of a delegate's raw position on a vault.

  Invalidate with `Memoize.invalidate(Rujira.Ghost.Vault, :query_delegate, [address, borrower, delegate])`.
  """
  @spec query_delegate(String.t(), String.t(), String.t()) :: {:ok, map()} | {:error, term()}
  defmemo query_delegate(address, borrower, delegate) do
    Contracts.query_state_smart(address, %{delegate: %{borrower: borrower, addr: delegate}})
  end

  # --- Private ---

  defp query_borrowers_page(address, cursor) do
    address
    |> Contracts.query_state_smart_with_retry(%{
      borrowers: %{start_after: cursor, limit: @max_limit}
    })
    |> Contracts.paginate("borrowers", @max_limit, fn borrowers ->
      query_borrowers_page(address, borrowers |> List.last() |> Map.get("addr"))
    end)
  end
end
