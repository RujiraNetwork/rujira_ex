defmodule Rujira.Thorchain.MimirTest do
  use ExUnit.Case, async: true

  alias Rujira.Thorchain.Mimir
  alias Rujira.Test.MockNode
  alias Thorchain.Types.QueryMimirValuesRequest
  alias Thorchain.Types.QueryMimirValuesResponse
  alias Thorchain.Types.Mimir, as: TcMimir

  describe "new/1" do
    test "uses the key as id" do
      assert {:ok, %Mimir{id: "MAXSYNTHPERPOOLDEPTH", key: "MAXSYNTHPERPOOLDEPTH", value: 5000}} =
               Mimir.new(%TcMimir{key: "MAXSYNTHPERPOOLDEPTH", value: 5000})
    end
  end

  describe "height reads" do
    @height 12_345
    @metadata %{"x-cosmos-block-height" => "12345"}

    setup do
      MockNode.expect(fn %QueryMimirValuesRequest{} ->
        {:ok,
         %QueryMimirValuesResponse{
           mimirs: [
             %TcMimir{key: "PAUSELPDEPOSIT-BTC-BTC", value: 1},
             %TcMimir{key: "MAXSYNTHPERPOOLDEPTH", value: 5000}
           ]
         }}
      end)

      :ok
    end

    test "list/1 carries the block-height metadata" do
      assert {:ok, [%Mimir{key: "PAUSELPDEPOSIT-BTC-BTC"}, %Mimir{}]} =
               Mimir.list(height: @height)

      assert_received {:mock_node, %QueryMimirValuesRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "a height read is never cached, so two calls reach the node twice" do
      assert {:ok, _} = Mimir.list(height: @height)
      assert {:ok, _} = Mimir.list(height: @height)

      assert_received {:mock_node, %QueryMimirValuesRequest{}, _}
      assert_received {:mock_node, %QueryMimirValuesRequest{}, _}
    end

    test "from_id/2 forwards the height to the list it reads" do
      assert {:ok, %Mimir{value: 5000}} = Mimir.from_id("MAXSYNTHPERPOOLDEPTH", height: @height)

      assert_received {:mock_node, %QueryMimirValuesRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "halted_pools/1 forwards the height to the list it reads" do
      assert {:ok, ["BTC.BTC"]} = Mimir.halted_pools(height: @height)

      assert_received {:mock_node, %QueryMimirValuesRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end
  end
end
