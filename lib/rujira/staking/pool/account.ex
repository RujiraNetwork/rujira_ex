defmodule Rujira.Staking.Pool.Account do
  @moduledoc """
  A user's bonded account in a rujira-staking pool: the bond the contract holds
  and the revenue it has already assigned to it.

  The contract never removes an account, so an owner it holds no record for has
  the same position as a fully unbonded one: `load/3` answers with an empty
  account - `bonded` and `pending_revenue` zero - rather than
  `{:error, :not_found}`.

  The account is the contract's own record, nothing more. A holder's liquid
  receipt tokens are a bank balance - read them with
  `Rujira.Bank.balance(owner, pool.receipt_asset)`. What the next distribution
  will add to `pending_revenue`, and what a parcel of receipt tokens is worth,
  are `revenue_share/2` and `liquid_size/2`: pure over a pool whose `status` is
  loaded.

  Struct, construction, and queries. Use `Rujira.Staking` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Cache
  alias Rujira.Contracts
  alias Rujira.Math
  alias Rujira.Node
  alias Rujira.Staking.Pool
  alias Rujira.Staking.Pool.Status

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
  given.

  An owner the contract holds no account for has never bonded, which is the
  position of an empty account: `bonded` and `pending_revenue` zero.
  """
  @spec load(Pool.t(), String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def load(%Pool{} = pool, owner, opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, res} <- account(pool.address, owner, opts) do
      build(pool, owner, res)
    end
  end

  @spec from_id(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def from_id(id, opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts),
         [address, owner] <- String.split(id, "/"),
         {:ok, [pool, res]} <-
           Rujira.Enum.all_async_while_ok(
             [
               fn -> Pool.get(address, opts) end,
               fn -> account(address, owner, opts) end
             ],
             opts,
             __MODULE__
           ) do
      build(pool, owner, res)
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

    {:ok, Math.div_floor(Math.mul(shares, liquid_bond_size), liquid_bond_shares)}
  end

  # --- Private ---

  defp fetch(address, owner, opts) do
    address
    |> Contracts.query_state_smart(%{account: %{addr: owner}}, opts)
    |> never_bonded()
  end

  defp account(address, owner, opts) do
    Cache.fetch(
      {__MODULE__, :query, [address, owner]},
      [{:contract, address}],
      opts,
      fn _height ->
        fetch(address, owner, opts)
      end
    )
  end

  # The contract loads the account bare and never removes one, so an owner that
  # has never bonded is a `StdError::NotFound` - an empty account, not a failed
  # read. It is the contract's own state, cached as the value it stands for.
  defp never_bonded({:error, err} = result) do
    if Contracts.not_found?(err), do: {:ok, :none}, else: result
  end

  defp never_bonded(result), do: result

  defp build(pool, owner, :none), do: {:ok, new(pool, owner, 0, 0)}

  defp build(pool, owner, res) do
    with {:ok, bonded} <- Amount.new(Map.get(res, "bonded")),
         {:ok, pending_revenue} <- Amount.new(Map.get(res, "pending_revenue")) do
      {:ok, new(pool, owner, bonded, pending_revenue)}
    end
  end

  defp net(undistributed_revenue, nil), do: undistributed_revenue

  defp net(undistributed_revenue, fee) do
    fee_amount = Math.mul_ceil(undistributed_revenue, fee)

    Math.sub(undistributed_revenue, fee_amount)
  end

  defp alloc(0, _net, _liquid_bond_size), do: 0

  defp alloc(account_bond, net, liquid_bond_size),
    do: Math.div_floor(Math.mul(account_bond, net), Math.add(account_bond, liquid_bond_size))

  defp share(_alloc, _bonded, 0), do: 0

  defp share(alloc, bonded, account_bond),
    do: Math.div_floor(Math.mul(alloc, bonded), account_bond)
end
