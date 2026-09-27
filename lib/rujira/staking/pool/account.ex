defmodule Rujira.Staking.Pool.Account do
  @moduledoc """
  A user's bonded account in a rujira-staking pool: the bond the contract holds
  and the revenue it has already assigned to it.

  The account is the contract's own record, nothing more. A holder's liquid
  receipt tokens are a bank balance - read them with
  `Rujira.Bank.balance(owner, pool.receipt_asset)`. What the next distribution
  will add to `pending_revenue`, and what a parcel of receipt tokens is worth,
  are `revenue_share/2` and `liquid_size/2`: pure over a pool whose `status` is
  loaded.

  Struct, construction, and queries. Use `Rujira.Staking` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Contracts
  alias Rujira.Math
  alias Rujira.Node
  alias Rujira.Staking.Pool
  alias Rujira.Staking.Pool.Status

  use Memoize

  # --- Struct ---

  defstruct id: nil,
            pool: nil,
            owner: nil,
            bonded: 0,
            pending_revenue: 0

  @type t :: %__MODULE__{
          id: String.t() | nil,
          pool: String.t() | nil,
          owner: String.t() | nil,
          bonded: Amount.t(),
          pending_revenue: Amount.t()
        }

  # --- Construction ---

  @spec new(Pool.t(), String.t(), Amount.t(), Amount.t()) :: t()
  def new(%Pool{address: address}, owner, bonded, pending_revenue) do
    %__MODULE__{
      id: "#{address}/#{owner}",
      pool: address,
      owner: owner,
      bonded: bonded,
      pending_revenue: pending_revenue
    }
  end

  # --- Queries ---

  @doc """
  Loads the contract's account for `owner`, at `opts[:height]` when one is
  given. An owner the contract holds no account for is `{:error, :not_found}`.
  """
  @spec load(Pool.t(), String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def load(%Pool{} = pool, owner, opts \\ []) do
    with {:ok, res} <- account(pool.address, owner, opts),
         {:ok, bonded} <- Amount.new(Map.get(res, "bonded")),
         {:ok, pending_revenue} <- Amount.new(Map.get(res, "pending_revenue")) do
      {:ok, new(pool, owner, bonded, pending_revenue)}
    end
  end

  @spec from_id(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def from_id(id, opts \\ []) do
    with [address, owner] <- String.split(id, "/"),
         {:ok, pool} <- Pool.get(address, opts) do
      load(pool, owner, opts)
    else
      {:error, _} = err -> err
      _ -> {:error, :invalid_id}
    end
  end

  # --- Calculations ---

  @doc """
  The revenue the pool's undistributed revenue will assign to `account` on the
  next distribution, on top of its `pending_revenue`.

  Pure over a pool whose `status` is loaded - `{:error, :not_loaded}` otherwise.
  """
  # `net = u - ceil(u * fee)`, or `net = u` when the pool has no fee;
  # `alloc = floor(account_bond * net / (account_bond + liquid_bond_size))`;
  # `share = floor(alloc * bonded / account_bond)` — mirrors rujira-staking's `distribute()`.
  @spec revenue_share(t(), Pool.t()) :: {:ok, Amount.t()} | {:error, :not_loaded}
  def revenue_share(%__MODULE__{}, %Pool{status: :not_loaded}), do: {:error, :not_loaded}

  def revenue_share(%__MODULE__{bonded: 0}, %Pool{}), do: {:ok, 0}

  def revenue_share(%__MODULE__{bonded: bonded}, %Pool{status: status, fee: fee}) do
    %Status{
      account_bond: account_bond,
      liquid_bond_size: liquid_bond_size,
      undistributed_revenue: undistributed_revenue
    } = status

    {:ok,
     account_bond
     |> alloc(net(undistributed_revenue, fee), liquid_bond_size)
     |> share(bonded, account_bond)}
  end

  @doc """
  The bonded size `shares` receipt tokens of the pool redeem for.

  Pure over a pool whose `status` is loaded - `{:error, :not_loaded}` otherwise.
  """
  @spec liquid_size(Amount.t(), Pool.t()) :: {:ok, Amount.t()} | {:error, :not_loaded}
  def liquid_size(_shares, %Pool{status: :not_loaded}), do: {:error, :not_loaded}

  def liquid_size(_shares, %Pool{status: %Status{liquid_bond_shares: 0}}), do: {:ok, 0}

  def liquid_size(shares, %Pool{status: status}) do
    %Status{liquid_bond_shares: liquid_bond_shares, liquid_bond_size: liquid_bond_size} = status

    {:ok,
     Math.div_floor(
       Decimal.mult(Decimal.new(shares), Decimal.new(liquid_bond_size)),
       liquid_bond_shares
     )}
  end

  # --- Private ---

  defmemop query(address, owner) do
    fetch(address, owner, [])
  end

  defp fetch(address, owner, opts) do
    Contracts.query_state_smart(address, %{account: %{addr: owner}}, opts)
  end

  defp account(address, owner, opts) do
    opts
    |> Node.at_height(fn -> fetch(address, owner, opts) end, fn -> query(address, owner) end)
    |> not_found()
  end

  # The contract loads the account bare, so an owner that has never bonded is a
  # `StdError::NotFound` - a missing account, not a failed read.
  defp not_found({:error, err}) do
    if Contracts.not_found?(err), do: {:error, :not_found}, else: {:error, err}
  end

  defp not_found(other), do: other

  defp net(undistributed_revenue, nil), do: undistributed_revenue

  defp net(undistributed_revenue, fee) do
    fee_amount =
      undistributed_revenue
      |> Decimal.new()
      |> Decimal.mult(fee)
      |> Decimal.round(0, :ceiling)
      |> Decimal.to_integer()

    undistributed_revenue - fee_amount
  end

  defp alloc(0, _net, _liquid_bond_size), do: 0

  defp alloc(account_bond, net, liquid_bond_size),
    do:
      Math.div_floor(
        Decimal.mult(Decimal.new(account_bond), Decimal.new(net)),
        account_bond + liquid_bond_size
      )

  defp share(_alloc, _bonded, 0), do: 0

  defp share(alloc, bonded, account_bond),
    do: Math.div_floor(Decimal.mult(Decimal.new(alloc), Decimal.new(bonded)), account_bond)
end
