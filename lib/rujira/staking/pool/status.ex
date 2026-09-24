defmodule Rujira.Staking.Pool.Status do
  @moduledoc """
  Live bonding and revenue state of a rujira-staking pool.

  Struct, construction, and queries. Use `Rujira.Staking` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Contracts
  alias Rujira.Staking.Pool

  use Memoize

  # --- Struct ---

  defstruct account_bond: 0,
            assigned_revenue: 0,
            liquid_bond_shares: 0,
            liquid_bond_size: 0,
            undistributed_revenue: 0

  @type t :: %__MODULE__{
          account_bond: Amount.t(),
          assigned_revenue: Amount.t(),
          liquid_bond_shares: Amount.t(),
          liquid_bond_size: Amount.t(),
          undistributed_revenue: Amount.t()
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "account_bond" => account_bond,
        "assigned_revenue" => assigned_revenue,
        "liquid_bond_shares" => liquid_bond_shares,
        "liquid_bond_size" => liquid_bond_size,
        "undistributed_revenue" => undistributed_revenue
      }) do
    with {:ok, account_bond} <- Amount.new(account_bond),
         {:ok, assigned_revenue} <- Amount.new(assigned_revenue),
         {:ok, liquid_bond_shares} <- Amount.new(liquid_bond_shares),
         {:ok, liquid_bond_size} <- Amount.new(liquid_bond_size),
         {:ok, undistributed_revenue} <- Amount.new(undistributed_revenue) do
      {:ok,
       %__MODULE__{
         account_bond: account_bond,
         assigned_revenue: assigned_revenue,
         liquid_bond_shares: liquid_bond_shares,
         liquid_bond_size: liquid_bond_size,
         undistributed_revenue: undistributed_revenue
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Queries ---

  @doc "Loads the pool's live status into its `status` field."
  @spec load(Pool.t()) :: {:ok, Pool.t()} | {:error, term()}
  def load(%Pool{address: address} = pool) do
    with {:ok, res} <- query(address),
         {:ok, status} <- new(res) do
      {:ok, %{pool | status: status}}
    end
  end

  @doc """
  Memoized fetch of a pool's live status.

  Invalidate with `Memoize.invalidate(Rujira.Staking.Pool.Status, :query, [address])`.
  """
  @spec query(String.t()) :: {:ok, map()} | {:error, term()}
  defmemo query(address) do
    Contracts.query_state_smart(address, %{status: %{}})
  end
end
