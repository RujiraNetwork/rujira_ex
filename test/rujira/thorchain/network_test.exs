defmodule Rujira.Thorchain.NetworkTest do
  use Rujira.Test.CacheCase, async: false

  alias Rujira.Thorchain.Network
  alias Rujira.Test.MockNode
  alias Thorchain.Types.QueryNetworkRequest
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

  describe "height reads" do
    @height 12_345
    @metadata %{"x-cosmos-block-height" => "12345"}

    setup do
      MockNode.expect(fn %QueryNetworkRequest{} ->
        {:ok,
         %QueryNetworkResponse{
           bond_reward_rune: "1000",
           total_bond_units: "0",
           total_reserve: "0",
           effective_security_bond: "0",
           gas_spent_rune: "0",
           gas_withheld_rune: "0",
           native_outbound_fee_rune: "0",
           native_tx_fee_rune: "0",
           outbound_fee_multiplier: "1",
           rune_price_in_tor: "0",
           tor_price_in_rune: "0"
         }}
      end)

      :ok
    end

    test "get/1 carries the block-height metadata" do
      assert {:ok, %Network{bond_reward_rune: 1000}} = Network.get(height: @height)

      assert_received {:mock_node, %QueryNetworkRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "a second read at the same height is served from the cache" do
      assert {:ok, _} = Network.get(height: @height)
      assert {:ok, _} = Network.get(height: @height)

      assert_received {:mock_node, %QueryNetworkRequest{}, _}
      refute_received {:mock_node, %QueryNetworkRequest{}, _}
    end

    test "the Rujira.Thorchain facade exposes the opts arity" do
      assert {:ok, %Network{}} = Rujira.Thorchain.network(height: @height)

      assert_received {:mock_node, %QueryNetworkRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end
  end
end
