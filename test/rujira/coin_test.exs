defmodule Rujira.CoinTest do
  use ExUnit.Case, async: true

  alias Rujira.Coin
  alias Rujira.Assets.Asset

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

    test "resolves layer1 denoms" do
      assert {:ok, %Coin{amount: 100, asset: %Asset{chain: "GAIA"}}} = Coin.new("gaia-atom", 100)
    end
  end

  describe "new/2 with denom string + string amount" do
    test "parses string amount" do
      assert {:ok, %Coin{amount: 42, asset: %Asset{id: "THOR.RUNE"}}} = Coin.new("rune", "42")
    end

    test "rejects non-integer string" do
      assert :error = Coin.new("rune", "abc")
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
end
