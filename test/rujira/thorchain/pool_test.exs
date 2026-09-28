defmodule Rujira.Thorchain.PoolTest do
  use Rujira.Test.CacheCase, async: false

  alias Rujira.Thorchain.Pool
  alias Rujira.Test.MockNode
  alias Thorchain.Types.QueryPoolsRequest
  alias Thorchain.Types.QueryPoolsResponse
  alias Thorchain.Types.QueryPoolResponse

  defp response(extra) do
    base = %{
      asset: "BTC.BTC",
      status: "Available",
      balance_asset: "0",
      balance_rune: "0",
      asset_tor_price: "0",
      pool_units: "0",
      pending_inbound_asset: "0",
      pending_inbound_rune: "0",
      derived_depth_bps: "0",
      savers_fill_bps: "0",
      savers_depth: "0",
      savers_units: "0",
      savers_capacity_remaining: "0",
      synth_supply: "0",
      synth_supply_remaining: "0",
      synth_units: "0"
    }

    struct(QueryPoolResponse, Map.merge(base, extra)) |> Map.put(:LP_units, "0")
  end

  describe "new/1" do
    test "casts balances, lp units and the tor price (1e8 fixed-point)" do
      res =
        response(%{balance_asset: "150000000", balance_rune: "200000000000"})
        |> Map.put(:LP_units, "250")
        |> Map.put(:asset_tor_price, "150000000")

      assert {:ok, %Pool{id: "BTC.BTC", balance_asset: 150_000_000, lp_units: 250} = pool} =
               Pool.new(res)

      assert pool.asset.ticker == "BTC"
      assert Decimal.equal?(pool.asset_tor_price, Decimal.new("1.5"))
    end

    test "leaves the tor price nil when blank" do
      assert {:ok, %Pool{asset_tor_price: nil}} = Pool.new(response(%{asset_tor_price: ""}))
    end
  end

  describe "height reads" do
    @height 12_345
    @metadata %{"x-cosmos-block-height" => "12345"}

    setup do
      MockNode.expect(fn %QueryPoolsRequest{} ->
        {:ok, %QueryPoolsResponse{pools: [response(%{})]}}
      end)

      :ok
    end

    test "list/1 carries the block-height metadata" do
      assert {:ok, [%Pool{id: "BTC.BTC"}]} = Pool.list(height: @height)

      assert_received {:mock_node, %QueryPoolsRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "a second read at the same height is served from the cache" do
      assert {:ok, _} = Pool.list(height: @height)
      assert {:ok, _} = Pool.list(height: @height)

      assert_received {:mock_node, %QueryPoolsRequest{}, _}
      refute_received {:mock_node, %QueryPoolsRequest{}, _}
    end

    test "get/2 forwards the height to the list it reads" do
      assert {:ok, %Pool{id: "BTC.BTC"}} = Pool.get("BTC.BTC", height: @height)

      assert_received {:mock_node, %QueryPoolsRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "from_id/2 forwards the height" do
      assert {:ok, %Pool{id: "BTC.BTC"}} = Pool.from_id("BTC.BTC", height: @height)

      assert_received {:mock_node, %QueryPoolsRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "the Rujira.Thorchain facade exposes the opts arity" do
      assert {:ok, [%Pool{}]} = Rujira.Thorchain.pools(height: @height)

      assert_received {:mock_node, %QueryPoolsRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end
  end
end
