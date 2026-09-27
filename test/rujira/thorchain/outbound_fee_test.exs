defmodule Rujira.Thorchain.OutboundFeeTest do
  use ExUnit.Case, async: true

  alias Rujira.Test.MockNode
  alias Rujira.Thorchain.OutboundFee
  alias Thorchain.Types.QueryOutboundFeeResponse
  alias Thorchain.Types.QueryOutboundFeesRequest
  alias Thorchain.Types.QueryOutboundFeesResponse

  @height 12_345
  @metadata %{"x-cosmos-block-height" => "12345"}

  defp response do
    %QueryOutboundFeeResponse{
      asset: "BTC.BTC",
      outbound_fee: "2000",
      fee_withheld_rune: "10",
      fee_spent_rune: "5",
      surplus_rune: "5",
      dynamic_multiplier_basis_points: "15000"
    }
  end

  describe "new/1" do
    test "uses the asset as id and casts every amount" do
      assert {:ok,
              %OutboundFee{
                id: "BTC.BTC",
                asset: "BTC.BTC",
                outbound_fee: 2000,
                fee_withheld_rune: 10,
                fee_spent_rune: 5,
                surplus_rune: 5,
                dynamic_multiplier_basis_points: 15_000
              }} = OutboundFee.new(response())
    end
  end

  describe "height reads" do
    setup do
      MockNode.expect(fn %QueryOutboundFeesRequest{} ->
        {:ok, %QueryOutboundFeesResponse{outbound_fees: [response()]}}
      end)

      :ok
    end

    test "list/1 carries the block-height metadata" do
      assert {:ok, [%OutboundFee{id: "BTC.BTC"}]} = OutboundFee.list(height: @height)

      assert_received {:mock_node, %QueryOutboundFeesRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "a height read is never cached, so two calls reach the node twice" do
      assert {:ok, _} = OutboundFee.list(height: @height)
      assert {:ok, _} = OutboundFee.list(height: @height)

      assert_received {:mock_node, %QueryOutboundFeesRequest{}, _}
      assert_received {:mock_node, %QueryOutboundFeesRequest{}, _}
    end

    test "the Rujira.Thorchain facade exposes the opts arity" do
      assert {:ok, [%OutboundFee{}]} = Rujira.Thorchain.outbound_fees(height: @height)

      assert_received {:mock_node, %QueryOutboundFeesRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end
  end
end
