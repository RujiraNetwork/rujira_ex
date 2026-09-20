defmodule Rujira.Thorchain.PoolTest do
  use ExUnit.Case, async: true

  alias Rujira.Thorchain.Pool
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
end
