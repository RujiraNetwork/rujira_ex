defmodule Rujira.CoinTest do
  use ExUnit.Case, async: true

  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Coin

  describe "new/2 with Asset struct" do
    test "creates coin directly" do
      asset = %Asset{
        id: "THOR.RUNE",
        type: :native,
        chain: "THOR",
        symbol: "RUNE",
        ticker: "RUNE"
      }

      coin = Coin.new(asset, 1000)
      assert %Coin{asset: ^asset, amount: 1000} = coin
    end
  end

  describe "new/2 with denom string + integer" do
    test "resolves asset from denom" do
      assert {:ok, %Coin{amount: 1000, asset: %Asset{id: "THOR.RUNE"}}} = Coin.new("rune", 1000)
    end

    test "resolves x/ denoms" do
      assert {:ok, %Coin{amount: 500, asset: %Asset{id: "THOR.RUJI"}}} = Coin.new("x/ruji", 500)
    end

    test "resolves secured denoms" do
      assert {:ok, %Coin{amount: 100, asset: %Asset{chain: "GAIA", type: :secured}}} =
               Coin.new("gaia-atom", 100)
    end

    test "rejects a dotted asset id, which is not a bank denom" do
      assert {:error, :invalid_denom} = Coin.new("gaia.atom", 100)
    end
  end

  describe "new/2 with denom string + string amount" do
    test "parses string amount" do
      assert {:ok, %Coin{amount: 42, asset: %Asset{id: "THOR.RUNE"}}} = Coin.new("rune", "42")
    end

    test "rejects non-integer string" do
      assert {:error, :invalid_amount} = Coin.new("rune", "abc")
    end
  end

  describe "new/1 from map" do
    test "accepts proto-style map" do
      assert {:ok, %Coin{amount: 99, asset: %Asset{id: "THOR.RUNE"}}} =
               Coin.new(%{denom: "rune", amount: "99"})
    end
  end

  describe "parse/1" do
    test "parses single coin (no space)" do
      assert {:ok, [%Coin{amount: 1000, asset: %Asset{id: "THOR.RUNE"}}]} = Coin.parse("1000rune")
    end

    test "parses single coin (space-separated)" do
      assert {:ok, [%Coin{amount: 1000, asset: %Asset{id: "THOR.RUNE"}}]} =
               Coin.parse("1000 rune")
    end

    test "parses multiple coins" do
      assert {:ok, coins} = Coin.parse("1000rune,500tcy")
      assert length(coins) == 2
      assert Enum.any?(coins, &(&1.asset.id == "THOR.RUNE" and &1.amount == 1000))
      assert Enum.any?(coins, &(&1.asset.id == "THOR.TCY" and &1.amount == 500))
    end

    test "parses x/ denoms" do
      assert {:ok, [%Coin{amount: 250, asset: %Asset{id: "THOR.RUJI"}}]} =
               Coin.parse("250x/ruji")
    end

    test "parses mixed formats" do
      assert {:ok, coins} = Coin.parse("1000 rune,500tcy")
      assert length(coins) == 2
    end

    test "returns error for invalid format" do
      assert {:error, :invalid_coin_format} = Coin.parse("notacoin")
    end
  end

  describe "from_asset_string/1" do
    test "parses a single asset-amount pair" do
      assert {:ok, [%Coin{amount: 100_000_000, asset: %Asset{id: "BTC.BTC"}}]} =
               Coin.from_asset_string("100000000 BTC.BTC")
    end

    test "parses a comma-separated list" do
      assert {:ok, coins} = Coin.from_asset_string("100000000 BTC.BTC,300000000 THOR.RUNE")
      assert length(coins) == 2
      assert Enum.any?(coins, &(&1.asset.id == "BTC.BTC" and &1.amount == 100_000_000))
      assert Enum.any?(coins, &(&1.asset.id == "THOR.RUNE" and &1.amount == 300_000_000))
    end

    test "parses a secured asset id" do
      assert {:ok, [%Coin{amount: 1, asset: %Asset{id: "BTC-BTC", type: :secured}}]} =
               Coin.from_asset_string("1 BTC-BTC")
    end

    test "parses THOR.RUNE" do
      assert {:ok, [%Coin{amount: 1, asset: %Asset{id: "THOR.RUNE"}}]} =
               Coin.from_asset_string("1 THOR.RUNE")
    end

    test "returns error for a malformed string" do
      assert {:error, :invalid_coin_format} = Coin.from_asset_string("notacoin")
    end

    test "returns error for an amount paired with an invalid asset id, without raising" do
      assert {:error, :invalid_coin_format} = Coin.from_asset_string("100 NOTANASSET")
    end
  end

  describe "denom/1" do
    test "returns the native denom of the coin's asset" do
      assert {:ok, coin} = Coin.new("rune", 1000)
      assert {:ok, "rune"} = Coin.denom(coin)

      assert {:ok, secured} = Coin.new("btc-btc", 1)
      assert {:ok, "btc-btc"} = Coin.denom(secured)
    end

    test "propagates the error when the asset has no native denom" do
      coin = Coin.new(Assets.from_string("BTC.BTC"), 1)
      assert {:error, :no_native_denom} = Coin.denom(coin)
    end
  end
end
