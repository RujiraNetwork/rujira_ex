defmodule Rujira.Thorchain.NetworkTest do
  use ExUnit.Case, async: true

  alias Rujira.Thorchain.Network
  alias Thorchain.Types.QueryNetworkResponse

  describe "new/1" do
    test "casts rune amounts and the fee multiplier" do
      res = %QueryNetworkResponse{
        bond_reward_rune: "1000",
        total_bond_units: "2000",
        total_reserve: "3000",
        effective_security_bond: "4000",
        gas_spent_rune: "5",
        gas_withheld_rune: "6",
        native_outbound_fee_rune: "2000000",
        native_tx_fee_rune: "2000000",
        outbound_fee_multiplier: "1.5",
        rune_price_in_tor: "150000000",
        tor_price_in_rune: "66666666",
        vaults_migrating: false,
        tor_price_halted: false
      }

      assert {:ok, %Network{bond_reward_rune: 1000, rune_price_in_tor: 150_000_000} = network} =
               Network.new(res)

      assert Decimal.equal?(network.outbound_fee_multiplier, Decimal.new("1.5"))
    end
  end
end
