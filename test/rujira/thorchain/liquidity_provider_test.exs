defmodule Rujira.Thorchain.LiquidityProviderTest do
  use ExUnit.Case, async: true

  alias Rujira.Thorchain.LiquidityProvider
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
  end
end
