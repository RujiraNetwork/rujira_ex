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
      assert base == %Oracle{id: "RUNE", ticker: "RUNE", asset: nil}
      assert %Oracle{id: "ETH.USDC", ticker: "USDC", asset: %{}} = quote
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

  describe "pick_default/2" do
    @pairs [
      %Pair{address: "p_btc_rune", token_base: "btc-btc", token_quote: "thor.rune"},
      %Pair{address: "p_btc_usdc", token_base: "btc-btc", token_quote: "eth-usdc-0xabc"},
      %Pair{address: "p_eth_rune", token_base: "eth-eth", token_quote: "thor.rune"}
    ]

    test "prefers the stable (usdc/usdt) pair when one exists" do
      assert {:ok, %Pair{address: "p_btc_usdc"}} = Pair.pick_default(@pairs, "btc-btc")
    end

    test "falls back to the first pair quoting the base when no stable exists" do
      assert {:ok, %Pair{address: "p_eth_rune"}} = Pair.pick_default(@pairs, "eth-eth")
    end

    test "does not treat a usdc quote for a different base as a match" do
      pairs = [%Pair{address: "p_eth_usdc", token_base: "eth-eth", token_quote: "eth-usdc-0xabc"}]
      assert {:error, :not_found} = Pair.pick_default(pairs, "btc-btc")
    end

    test "returns :not_found when no pair quotes the base" do
      assert {:error, :not_found} = Pair.pick_default(@pairs, "doge-doge")
    end

    test "tolerates a nil token_quote" do
      pairs = [%Pair{address: "p_nil_quote", token_base: "btc-btc", token_quote: nil}]
      assert {:ok, %Pair{address: "p_nil_quote"}} = Pair.pick_default(pairs, "btc-btc")
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
      assert base.ticker == "ATOM"
      assert quote_.id == "ETH.USDC"
      assert quote_.ticker == "USDC"
    end

    test "derives ticker from asset, stripping contract suffix" do
      config = %{
        "address" => "thor1pair",
        "market_makers" => [],
        "denoms" => ["gaia-atom", "eth-usdc-0xabc"],
        "oracles" => [%{"chain" => "ETH", "symbol" => "USDC-0xabc"}],
        "tick" => 6,
        "fee_taker" => "0.0015",
        "fee_maker" => "0.00075",
        "fee_address" => "thor1fee"
      }

      assert {:ok, %Pair{oracle_base: base}} = Pair.new(config)
      assert base.id == "ETH.USDC-0xabc"
      assert base.ticker == "USDC"
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
