defmodule Rujira.Thorchain.LiquidityProviderTest do
  use Rujira.Test.CacheCase, async: false

  alias Rujira.Thorchain.LiquidityProvider
  alias Rujira.Test.MockNode
  alias Thorchain.Types.QueryLiquidityProviderRequest
  alias Thorchain.Types.QueryLiquidityProviderResponse

  describe "new/1" do
    test "builds the id, blanks empty addresses and zeroes the withdraw height" do
      res = %QueryLiquidityProviderResponse{
        asset: "BTC.BTC",
        rune_address: "thor1abc",
        asset_address: "",
        last_add_height: 100,
        last_withdraw_height: 0,
        units: "1000",
        pending_rune: "0",
        pending_asset: "0",
        rune_deposit_value: "0",
        asset_deposit_value: "0",
        rune_redeem_value: "0",
        asset_redeem_value: "0",
        luvi_deposit_value: "0",
        luvi_redeem_value: "0",
        luvi_growth_pct: "0"
      }

      assert {:ok,
              %LiquidityProvider{
                id: "BTC.BTC/thor1abc",
                units: 1000,
                asset_address: nil,
                last_add_height: 100,
                last_withdraw_height: nil
              } = lp} = LiquidityProvider.new(res)

      assert lp.asset.ticker == "BTC"
    end

    test "carries no value_usd - pricing the position is the caller's" do
      res = %QueryLiquidityProviderResponse{
        asset: "BTC.BTC",
        rune_address: "thor1abc",
        asset_address: "",
        last_add_height: 100,
        last_withdraw_height: 0,
        units: "1000",
        pending_rune: "0",
        pending_asset: "0",
        rune_deposit_value: "0",
        asset_deposit_value: "0",
        rune_redeem_value: "0",
        asset_redeem_value: "0",
        luvi_deposit_value: "0",
        luvi_redeem_value: "0",
        luvi_growth_pct: "0"
      }

      assert {:ok, %LiquidityProvider{} = lp} = LiquidityProvider.new(res)
      refute Map.has_key?(Map.from_struct(lp), :value_usd)
    end
  end

  describe "height reads" do
    @height 12_345
    @metadata %{"x-cosmos-block-height" => "12345"}

    setup do
      MockNode.expect(fn %QueryLiquidityProviderRequest{} ->
        {:ok,
         %QueryLiquidityProviderResponse{
           asset: "BTC.BTC",
           rune_address: "thor1abc",
           asset_address: "",
           last_add_height: 100,
           last_withdraw_height: 0,
           units: "1000",
           pending_rune: "0",
           pending_asset: "0",
           rune_deposit_value: "0",
           asset_deposit_value: "0",
           rune_redeem_value: "0",
           asset_redeem_value: "0",
           luvi_deposit_value: "0",
           luvi_redeem_value: "0",
           luvi_growth_pct: "0"
         }}
      end)

      :ok
    end

    test "query/3 carries the block-height metadata" do
      assert {:ok, %QueryLiquidityProviderResponse{}} =
               LiquidityProvider.query("BTC.BTC", "thor1abc", height: @height)

      assert_received {:mock_node, %QueryLiquidityProviderRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "a second read at the same height is served from the cache" do
      assert {:ok, _} = LiquidityProvider.query("BTC.BTC", "thor1abc", height: @height)
      assert {:ok, _} = LiquidityProvider.query("BTC.BTC", "thor1abc", height: @height)

      assert_received {:mock_node, %QueryLiquidityProviderRequest{}, _}
      refute_received {:mock_node, %QueryLiquidityProviderRequest{}, _}
    end

    test "get/3 forwards the height to the query it reads" do
      assert {:ok, %LiquidityProvider{units: 1000}} =
               LiquidityProvider.get("BTC.BTC", "thor1abc", height: @height)

      assert_received {:mock_node, %QueryLiquidityProviderRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "from_id/2 forwards the height" do
      assert {:ok, %LiquidityProvider{id: "BTC.BTC/thor1abc"}} =
               LiquidityProvider.from_id("BTC.BTC/thor1abc", height: @height)

      assert_received {:mock_node, %QueryLiquidityProviderRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end
  end
end
