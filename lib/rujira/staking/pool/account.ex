defmodule Rujira.Staking.Pool.Account do
  @moduledoc """
  A user's position in a rujira-staking pool: direct account bond plus
  liquid receipt-token shares, and their pending revenue.

  Struct, construction, and queries. Use `Rujira.Staking` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Bank
  alias Rujira.Contracts
  alias Rujira.Math
  alias Rujira.Staking.Pool
  alias Rujira.Staking.Pool.Status

  use Memoize

  # --- Struct ---

  defstruct id: nil,
            pool: nil,
            owner: nil,
            bonded: 0,
            pending_revenue: 0,
            liquid_shares: 0,
            liquid_size: 0

  @type t :: %__MODULE__{
          id: String.t() | nil,
          pool: String.t() | nil,
          owner: String.t() | nil,
          bonded: Amount.t(),
          pending_revenue: Amount.t(),
          liquid_shares: Amount.t(),
          liquid_size: Amount.t()
        }

  # --- Construction ---

  @spec new(Pool.t(), String.t(), Amount.t(), Amount.t(), Amount.t()) :: t()
  def new(
        %Pool{address: address} = pool,
        owner,
        bonded,
        contract_pending_revenue,
        liquid_shares
      ) do
    %__MODULE__{
      id: "#{address}/#{owner}",
      pool: address,
      owner: owner,
      bonded: bonded,
      pending_revenue: contract_pending_revenue + revenue_share(pool, bonded),
      liquid_shares: liquid_shares,
      liquid_size: liquid_size(pool, liquid_shares)
    }
  end

  # --- Queries ---

  @spec load(Pool.t(), String.t()) :: {:ok, t()} | {:error, term()}
  def load(%Pool{status: :not_loaded} = pool, owner) do
    with {:ok, pool} <- Status.load(pool) do
      load(pool, owner)
    end
  end

  def load(%Pool{} = pool, owner) do
    with {:ok, res} <- account(pool.address, owner),
         {:ok, bonded} <- Amount.new(Map.get(res, "bonded")),
         {:ok, contract_pending_revenue} <- Amount.new(Map.get(res, "pending_revenue")),
         {:ok, %{amount: liquid_shares}} <- Bank.balance(owner, pool.receipt_asset) do
      {:ok, new(pool, owner, bonded, contract_pending_revenue, liquid_shares)}
    end
  end

  @spec from_id(String.t()) :: {:ok, t()} | {:error, term()}
  def from_id(id) do
    with [address, owner] <- String.split(id, "/"),
         {:ok, pool} <- Pool.get(address) do
      load(pool, owner)
    else
      {:error, _} = err -> err
      _ -> {:error, :invalid_id}
    end
  end

  # --- Private ---

  defmemop query(address, owner) do
    Contracts.query_state_smart(address, %{account: %{addr: owner}})
  end

  defp account(address, owner) do
    case query(address, owner) do
      {:error, %GRPC.RPCError{status: 2, message: "NotFound: query wasm contract failed"}} ->
        {:ok, %{"bonded" => "0", "pending_revenue" => "0"}}

      other ->
        other
    end
  end

  # `net = u - ceil(u * fee)`; `alloc = floor(account_bond * net / (account_bond + liquid_bond_size))`;
  # `share = floor(alloc * bonded / account_bond)` — mirrors rujira-staking's `distribute()`.
  defp revenue_share(_pool, 0), do: 0

  defp revenue_share(%Pool{status: status} = pool, bonded) do
    %Status{
      account_bond: account_bond,
      liquid_bond_size: liquid_bond_size,
      undistributed_revenue: undistributed_revenue
    } = status

    account_bond
    |> alloc(net(undistributed_revenue, pool.fee), liquid_bond_size)
    |> share(bonded, account_bond)
  end

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

  defp share(_alloc, 0, _account_bond), do: 0
  defp share(_alloc, _bonded, 0), do: 0

  defp share(alloc, bonded, account_bond),
    do: Math.div_floor(Decimal.mult(Decimal.new(alloc), Decimal.new(bonded)), account_bond)

  defp liquid_size(%Pool{status: %Status{liquid_bond_shares: 0}}, _liquid_shares), do: 0

  defp liquid_size(%Pool{status: status}, liquid_shares) do
    %Status{liquid_bond_shares: liquid_bond_shares, liquid_bond_size: liquid_bond_size} = status

    Math.div_floor(
      Decimal.mult(Decimal.new(liquid_shares), Decimal.new(liquid_bond_size)),
      liquid_bond_shares
    )
  end
end
