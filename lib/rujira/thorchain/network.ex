defmodule Rujira.Thorchain.Network do
  @moduledoc """
  THORChain network-wide economics.

  Struct, construction, and queries. Use `Rujira.Thorchain` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Math
  alias Thorchain.Types.Query.Stub
  alias Thorchain.Types.QueryNetworkRequest
  alias Thorchain.Types.QueryNetworkResponse

  use Memoize

  # --- Struct ---

  defstruct bond_reward_rune: 0,
            total_bond_units: 0,
            total_reserve: 0,
            effective_security_bond: 0,
            gas_spent_rune: 0,
            gas_withheld_rune: 0,
            native_outbound_fee_rune: 0,
            native_tx_fee_rune: 0,
            outbound_fee_multiplier: Decimal.new(0),
            rune_price_in_tor: 0,
            tor_price_in_rune: 0,
            vaults_migrating: false,
            tor_price_halted: false

  @type t :: %__MODULE__{
          bond_reward_rune: Amount.t(),
          total_bond_units: Amount.t(),
          total_reserve: Amount.t(),
          effective_security_bond: Amount.t(),
          gas_spent_rune: Amount.t(),
          gas_withheld_rune: Amount.t(),
          native_outbound_fee_rune: Amount.t(),
          native_tx_fee_rune: Amount.t(),
          outbound_fee_multiplier: Decimal.t(),
          rune_price_in_tor: Amount.t(),
          tor_price_in_rune: Amount.t(),
          vaults_migrating: boolean(),
          tor_price_halted: boolean()
        }

  # --- Construction ---

  @spec new(QueryNetworkResponse.t()) :: {:ok, t()} | {:error, term()}
  def new(%QueryNetworkResponse{} = network) do
    with {:ok, bond_reward_rune} <- Amount.new(network.bond_reward_rune),
         {:ok, total_bond_units} <- Amount.new(network.total_bond_units),
         {:ok, total_reserve} <- Amount.new(network.total_reserve),
         {:ok, effective_security_bond} <- Amount.new(network.effective_security_bond),
         {:ok, gas_spent_rune} <- Amount.new(network.gas_spent_rune),
         {:ok, gas_withheld_rune} <- Amount.new(network.gas_withheld_rune),
         {:ok, native_outbound_fee_rune} <- Amount.new(network.native_outbound_fee_rune),
         {:ok, native_tx_fee_rune} <- Amount.new(network.native_tx_fee_rune),
         {:ok, outbound_fee_multiplier} <- Math.to_decimal(network.outbound_fee_multiplier),
         {:ok, rune_price_in_tor} <- Amount.new(network.rune_price_in_tor),
         {:ok, tor_price_in_rune} <- Amount.new(network.tor_price_in_rune) do
      {:ok,
       %__MODULE__{
         bond_reward_rune: bond_reward_rune,
         total_bond_units: total_bond_units,
         total_reserve: total_reserve,
         effective_security_bond: effective_security_bond,
         gas_spent_rune: gas_spent_rune,
         gas_withheld_rune: gas_withheld_rune,
         native_outbound_fee_rune: native_outbound_fee_rune,
         native_tx_fee_rune: native_tx_fee_rune,
         outbound_fee_multiplier: outbound_fee_multiplier,
         rune_price_in_tor: rune_price_in_tor,
         tor_price_in_rune: tor_price_in_rune,
         vaults_migrating: network.vaults_migrating,
         tor_price_halted: network.tor_price_halted
       }}
    end
  end

  # --- Queries ---

  @doc """
  Memoized fetch of the network economics.

  Invalidate with `Memoize.invalidate(Rujira.Thorchain.Network, :get)`.
  """
  @spec get() :: {:ok, t()} | {:error, term()}
  defmemo get, expires_in: Rujira.cache_ttl() do
    with {:ok, res} <- Rujira.Node.query(&Stub.network/2, %QueryNetworkRequest{}) do
      new(res)
    end
  end
end
