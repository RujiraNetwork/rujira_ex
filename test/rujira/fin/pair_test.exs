defmodule Rujira.Fin.PairTest do
  use ExUnit.Case, async: true

  alias Rujira.Fin.Pair
  alias Rujira.Thorchain.Oracle

  describe "new/1 from map" do
    test "parses pair config with market_makers list" do
      config = %{
        "address" => "thor1pair",
        "market_makers" => ["thor1mm1", "thor1mm2"],
        "denoms" => ["gaia-atom", "eth-usdc-0xabc"],
        "oracles" => [
          %{"chain" => "GAIA", "symbol" => "ATOM"},
          %{"chain" => "ETH", "symbol" => "USDC"}
        ],
        "tick" => 6,
        "fee_taker" => "0.0015",
        "fee_maker" => "0.00075",
        "fee_address" => "thor1fee"
      }

      assert {:ok, %Pair{} = pair} = Pair.new(config)
      assert pair.address == "thor1pair"
      assert pair.id == "thor1pair"
      assert pair.market_makers == ["thor1mm1", "thor1mm2"]
      assert pair.token_base == "gaia-atom"
      assert pair.token_quote == "eth-usdc-0xabc"
      assert pair.tick == 6
      assert pair.fee_taker == Decimal.new("0.0015")
      assert pair.fee_maker == Decimal.new("0.00075")
      assert pair.fee_address == "thor1fee"
      assert pair.book == :not_loaded
    end

    test "parses enshrined oracle from bare symbol string" do
      config = %{
        "address" => "thor1pair",
        "market_makers" => [],
        "denoms" => ["rune", "eth-usdc-0xabc"],
        "oracles" => ["RUNE", %{"chain" => "ETH", "symbol" => "USDC"}],
        "tick" => 6,
        "fee_taker" => "0.0015",
        "fee_maker" => "0.00075",
        "fee_address" => "thor1fee"
      }

      assert {:ok, %Pair{oracle_base: base, oracle_quote: quote}} = Pair.new(config)
      assert base == %Oracle{id: "RUNE", symbol: "RUNE", asset: nil}
      assert %Oracle{id: "ETH.USDC", symbol: "ETH.USDC", asset: %{}} = quote
    end

    test "normalizes single market_maker to list" do
      config = %{
        "address" => "thor1pair",
        "market_maker" => "thor1mm",
        "denoms" => ["gaia-atom", "eth-usdc-0xabc"],
        "oracles" => nil,
        "tick" => 6,
        "fee_taker" => "0.0015",
        "fee_maker" => "0.00075",
        "fee_address" => "thor1fee"
      }

      assert {:ok, %Pair{market_makers: ["thor1mm"]}} = Pair.new(config)
    end

    test "normalizes nil market_maker to empty list" do
      config = %{
        "address" => "thor1pair",
        "market_maker" => nil,
        "denoms" => ["gaia-atom", "eth-usdc-0xabc"],
        "oracles" => nil,
        "tick" => 6,
        "fee_taker" => "0.0015",
        "fee_maker" => "0.00075",
        "fee_address" => "thor1fee"
      }

      assert {:ok, %Pair{market_makers: []}} = Pair.new(config)
    end
  end

  describe "pick_denom/2" do
    test "prefers ETH-chain denom when ticker appears on multiple chains" do
      denoms = ["bsc-usdc-0xaaa", "eth-usdc-0xbbb", "avax-usdc-0xccc"]
      assert {:ok, "eth-usdc-0xbbb"} = Pair.pick_denom(denoms, "USDC")
    end

    test "returns the single match when only one chain carries the ticker" do
      assert {:ok, "eth-eth"} = Pair.pick_denom(["eth-eth", "btc-btc"], "ETH")
    end

    test "matches on ticker, not on the full symbol" do
      assert {:ok, "eth-usdc-0xabc"} = Pair.pick_denom(["eth-usdc-0xabc"], "USDC")
    end

    test "returns :not_found when no denom matches" do
      assert {:error, :not_found} = Pair.pick_denom(["eth-eth", "btc-btc"], "DOGE")
    end

    test "ignores denoms that fail to parse" do
      assert {:ok, "eth-eth"} = Pair.pick_denom(["not-a-real-denom", "eth-eth"], "ETH")
    end

    test "deduplicates input denoms" do
      assert {:ok, "eth-eth"} = Pair.pick_denom(["eth-eth", "eth-eth"], "ETH")
    end

    test "picks native x/ruji for RUJI when it is the only base denom" do
      assert {:ok, "x/ruji"} = Pair.pick_denom(["x/ruji", "x/ruji"], "RUJI")
    end
  end

  describe "new/1 oracle parsing" do
    test "parses oracles from config maps" do
      config = %{
        "address" => "thor1pair",
        "market_makers" => [],
        "denoms" => ["gaia-atom", "eth-usdc-0xabc"],
        "oracles" => [
          %{"chain" => "GAIA", "symbol" => "ATOM"},
          %{"chain" => "ETH", "symbol" => "USDC"}
        ],
        "tick" => 6,
        "fee_taker" => "0.0015",
        "fee_maker" => "0.00075",
        "fee_address" => "thor1fee"
      }

      assert {:ok, %Pair{oracle_base: base, oracle_quote: quote_}} = Pair.new(config)
      assert base.id == "GAIA.ATOM"
      assert quote_.id == "ETH.USDC"
    end

    test "handles nil oracles" do
      config = %{
        "address" => "thor1pair",
        "market_makers" => [],
        "denoms" => ["gaia-atom", "eth-usdc-0xabc"],
        "oracles" => nil,
        "tick" => 6,
        "fee_taker" => "0.0015",
        "fee_maker" => "0.00075",
        "fee_address" => "thor1fee"
      }

      assert {:ok, %Pair{oracle_base: nil, oracle_quote: nil}} = Pair.new(config)
    end
  end
end
