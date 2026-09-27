defmodule Rujira.Thorchain.InboundAddressTest do
  use ExUnit.Case, async: true

  alias Rujira.Test.MockNode
  alias Rujira.Thorchain.InboundAddress
  alias Thorchain.Types.QueryInboundAddressesRequest
  alias Thorchain.Types.QueryInboundAddressesResponse
  alias Thorchain.Types.QueryInboundAddressResponse

  @height 12_345
  @metadata %{"x-cosmos-block-height" => "12345"}

  defp response do
    %QueryInboundAddressResponse{
      chain: "BTC",
      address: "bc1qabc",
      halted: false,
      pub_key: "",
      router: "",
      gas_rate: "10",
      gas_rate_units: "satsperbyte",
      outbound_tx_size: "1000",
      outbound_fee: "2000",
      dust_threshold: "10000"
    }
  end

  describe "new/1" do
    test "casts the gas and fee amounts and blanks empty strings" do
      assert {:ok,
              %InboundAddress{
                id: "BTC",
                chain: "BTC",
                address: "bc1qabc",
                gas_rate: 10,
                gas_rate_units: "satsperbyte",
                outbound_tx_size: 1000,
                outbound_fee: 2000,
                dust_threshold: 10_000,
                pub_key: nil,
                router: nil
              }} = InboundAddress.new(response())
    end
  end

  describe "height reads" do
    setup do
      MockNode.expect(fn %QueryInboundAddressesRequest{} ->
        {:ok, %QueryInboundAddressesResponse{inbound_addresses: [response()]}}
      end)

      :ok
    end

    test "list/1 carries the block-height metadata" do
      assert {:ok, [%InboundAddress{chain: "BTC"}]} = InboundAddress.list(height: @height)

      assert_received {:mock_node, %QueryInboundAddressesRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "a height read is never cached, so two calls reach the node twice" do
      assert {:ok, _} = InboundAddress.list(height: @height)
      assert {:ok, _} = InboundAddress.list(height: @height)

      assert_received {:mock_node, %QueryInboundAddressesRequest{}, _}
      assert_received {:mock_node, %QueryInboundAddressesRequest{}, _}
    end

    test "the Rujira.Thorchain facade exposes the opts arity" do
      assert {:ok, [%InboundAddress{}]} = Rujira.Thorchain.inbound_addresses(height: @height)

      assert_received {:mock_node, %QueryInboundAddressesRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end
  end
end
