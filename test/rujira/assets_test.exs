defmodule Rujira.AssetsTest do
  use ExUnit.Case, async: true

  alias Rujira.Assets
  alias Rujira.Assets.Asset

  # Only the pure resolution paths are exercised here. Anything routing through
  # Rujira.Assets.Metadata performs a gRPC query against a node — that needs
  # test/support/mock_node.ex and belongs with the node-layer tranche.

  describe "type/1" do
    test "classifies THOR-prefixed ids as native" do
      assert Assets.type("THOR.RUNE") == :native
      assert Assets.type("THOR.RUJI") == :native
    end

    test "classifies dotted ids as layer_1" do
      assert Assets.type("BTC.BTC") == :layer_1
      assert Assets.type("ETH.USDC") == :layer_1
    end

    test "classifies slashed ids as synth" do
      assert Assets.type("BTC/BTC") == :synth
    end

    test "classifies tilde ids as trade" do
      assert Assets.type("BTC~BTC") == :trade
    end

    test "classifies hyphenated ids as secured" do
      assert Assets.type("BTC-BTC") == :secured
    end

    test "falls back to native for anything unrecognised" do
      assert Assets.type("rune") == :native
      assert Assets.type("x/ruji") == :native
      assert Assets.type("") == :native
    end
  end

  describe "chain/1" do
    test "takes the segment before the delimiter" do
      assert Assets.chain("BTC.BTC") == "BTC"
      assert Assets.chain("ETH-USDC") == "ETH"
      assert Assets.chain("BTC/BTC") == "BTC"
      assert Assets.chain("BTC~BTC") == "BTC"
    end

    test "maps x/ denoms onto THOR" do
      assert Assets.chain("x/ruji") == "THOR"
      assert Assets.chain("x/staking-ruji") == "THOR"
    end

    test "returns the whole string when there is no delimiter" do
      assert Assets.chain("RUNE") == "RUNE"
    end
  end

  describe "symbol/1" do
    test "takes everything after the first delimiter" do
      assert Assets.symbol("THOR.RUNE") == "RUNE"
      assert Assets.symbol("BTC.BTC") == "BTC"
    end

    test "keeps contract-address suffixes intact" do
      assert Assets.symbol("ETH.USDC-0X123") == "USDC-0X123"
    end

    test "upcases x/ denoms" do
      assert Assets.symbol("x/ruji") == "RUJI"
    end
  end

  describe "ticker/1" do
    test "matches the symbol when there is no suffix" do
      assert Assets.ticker("THOR.RUNE") == "RUNE"
    end

    test "drops a contract-address suffix, unlike symbol/1" do
      assert Assets.ticker("ETH.USDC-0X123") == "USDC"
      assert Assets.symbol("ETH.USDC-0X123") == "USDC-0X123"
    end

    test "upcases x/ denoms" do
      assert Assets.ticker("x/ruji") == "RUJI"
    end
  end

  describe "from_string/1" do
    test "builds a fully populated asset" do
      assert %Asset{
               id: "THOR.RUNE",
               type: :native,
               chain: "THOR",
               symbol: "RUNE",
               ticker: "RUNE"
             } = Assets.from_string("THOR.RUNE")
    end

    test "builds a layer_1 asset with a contract suffix" do
      assert %Asset{
               id: "ETH.USDC-0X123",
               type: :layer_1,
               chain: "ETH",
               symbol: "USDC-0X123",
               ticker: "USDC"
             } = Assets.from_string("ETH.USDC-0X123")
    end
  end

  describe "from_id/1" do
    test "wraps from_string/1 in an ok tuple" do
      assert {:ok, %Asset{id: "THOR.RUNE"}} = Assets.from_id("THOR.RUNE")
    end

    test "agrees with from_string/1" do
      assert {:ok, asset} = Assets.from_id("BTC.BTC")
      assert asset == Assets.from_string("BTC.BTC")
    end
  end

  describe "from_shortcode/1" do
    test "resolves the known shortcodes" do
      assert %Asset{id: "THOR.RUJI"} = Assets.from_shortcode("RUJI")
      assert %Asset{id: "THOR.RUNE"} = Assets.from_shortcode("RUNE")
      assert %Asset{id: "THOR.TCY"} = Assets.from_shortcode("TCY")
      assert %Asset{id: "GAIA.ATOM"} = Assets.from_shortcode("ATOM")
    end

    test "maps BNB onto the BSC chain" do
      assert %Asset{id: "BSC.BNB", chain: "BSC"} = Assets.from_shortcode("BNB")
    end

    test "doubles a bare symbol into chain.ticker" do
      assert %Asset{id: "BTC.BTC", chain: "BTC", ticker: "BTC"} = Assets.from_shortcode("BTC")
    end

    test "splits a dotted or hyphenated shortcode" do
      assert %Asset{id: "ETH.USDC"} = Assets.from_shortcode("ETH.USDC")
      assert %Asset{id: "ETH.USDC"} = Assets.from_shortcode("ETH-USDC")
    end
  end

  describe "decimals/1" do
    test "defaults to 8" do
      assert Assets.decimals(%{type: :native, chain: "THOR", ticker: "RUNE"}) == 8
      assert Assets.decimals(%{type: :layer_1, chain: "UNKNOWN", ticker: "X"}) == 8
    end

    test "uses 18 for EVM chains" do
      assert Assets.decimals(%{type: :layer_1, chain: "ETH", ticker: "ETH"}) == 18
      assert Assets.decimals(%{type: :layer_1, chain: "AVAX", ticker: "AVAX"}) == 18
      assert Assets.decimals(%{type: :layer_1, chain: "BSC", ticker: "BNB"}) == 18
      assert Assets.decimals(%{type: :layer_1, chain: "BASE", ticker: "ETH"}) == 18
    end

    test "uses 6 for stablecoins on EVM chains, overriding the chain default" do
      assert Assets.decimals(%{type: :layer_1, chain: "ETH", ticker: "USDC"}) == 6
      assert Assets.decimals(%{type: :layer_1, chain: "ETH", ticker: "USDT"}) == 6
      assert Assets.decimals(%{type: :layer_1, chain: "AVAX", ticker: "USDC"}) == 6
      assert Assets.decimals(%{type: :layer_1, chain: "BASE", ticker: "USDC"}) == 6
    end

    test "uses 8 for WBTC on ETH, not the chain default of 18" do
      assert Assets.decimals(%{type: :layer_1, chain: "ETH", ticker: "WBTC"}) == 8
    end

    test "uses 8 for UTXO chains" do
      for chain <- ["BTC", "BCH", "LTC", "DOGE"] do
        assert Assets.decimals(%{type: :layer_1, chain: chain, ticker: chain}) == 8
      end
    end

    test "uses 6 for the Cosmos chains" do
      for chain <- ["GAIA", "KUJI", "OSMO", "TRON", "XRP"] do
        assert Assets.decimals(%{type: :layer_1, chain: chain, ticker: chain}) == 6
      end
    end

    test "uses 9 for SOL and TON" do
      assert Assets.decimals(%{type: :layer_1, chain: "SOL", ticker: "SOL"}) == 9
      assert Assets.decimals(%{type: :layer_1, chain: "TON", ticker: "TON"}) == 9
    end

    test "special-cases USDT on TON and USDY on NOBLE" do
      assert Assets.decimals(%{type: :layer_1, chain: "TON", ticker: "USDT"}) == 6
      assert Assets.decimals(%{type: :layer_1, chain: "NOBLE", ticker: "USDY"}) == 18
      assert Assets.decimals(%{type: :layer_1, chain: "NOBLE", ticker: "USDC"}) == 6
    end

    test "ignores the lookup table for non-layer_1 types" do
      # The table only matches type: :layer_1, so a secured ETH asset falls through.
      assert Assets.decimals(%{type: :secured, chain: "ETH", ticker: "ETH"}) == 8
    end
  end

  describe "from_denom/1" do
    test "resolves the well-known native denoms" do
      assert {:ok, %Asset{id: "THOR.RUJI", symbol: "RUJI"}} = Assets.from_denom("x/ruji")
      assert {:ok, %Asset{id: "THOR.RUNE", symbol: "RUNE"}} = Assets.from_denom("rune")
      assert {:ok, %Asset{id: "THOR.TCY", symbol: "TCY"}} = Assets.from_denom("tcy")
    end

    test "prefixes staking denoms with s" do
      assert {:ok, %Asset{id: "x/staking-rune", symbol: "sRUNE", ticker: "sRUNE"}} =
               Assets.from_denom("x/staking-rune")
    end

    test "upcases generic x/ denoms" do
      assert {:ok, %Asset{id: "x/foo", symbol: "FOO", ticker: "FOO", chain: "THOR"}} =
               Assets.from_denom("x/foo")
    end

    test "upcases thor. denoms" do
      assert {:ok, %Asset{id: "THOR.ABC", symbol: "ABC", chain: "THOR"}} =
               Assets.from_denom("thor.abc")
    end

    test "resolves layer_1 denoms, upcasing the id" do
      assert {:ok, %Asset{id: "BTC.BTC", chain: "BTC", ticker: "BTC", type: :layer_1}} =
               Assets.from_denom("btc.btc")
    end

    test "rewrites the BNB chain to BSC" do
      assert {:ok, %Asset{chain: "BSC"}} = Assets.from_denom("bnb.bnb")
    end

    test "splits a contract suffix into symbol and ticker" do
      assert {:ok, %Asset{symbol: "USDC-0X123", ticker: "USDC"}} =
               Assets.from_denom("eth-usdc-0x123")
    end

    test "rejects a denom with no delimiter" do
      assert {:error, :invalid_denom} = Assets.from_denom("nodelimiter")
    end
  end

  describe "eq_denom/2" do
    test "matches on chain and ticker" do
      asset = Assets.from_string("THOR.RUNE")
      assert Assets.eq_denom(asset, "rune")
    end

    test "rejects a different asset" do
      asset = Assets.from_string("THOR.RUNE")
      refute Assets.eq_denom(asset, "tcy")
    end

    test "rejects an unresolvable denom instead of raising" do
      asset = Assets.from_string("THOR.RUNE")
      refute Assets.eq_denom(asset, "nodelimiter")
    end

    test "ignores a contract-address suffix, since it compares tickers" do
      asset = Assets.from_string("ETH.USDC")
      assert Assets.eq_denom(asset, "eth-usdc-0x123")
    end
  end

  describe "to_secured/1" do
    test "refuses THOR-chain assets" do
      assert {:error, :not_supported} = Assets.to_secured(Assets.from_string("THOR.RUNE"))
    end

    test "replaces only the first delimiter" do
      assert {:ok, %Asset{id: "ETH-USDC-0X123", type: :secured}} =
               Assets.to_secured(Assets.from_string("ETH.USDC-0X123"))
    end

    test "converts a simple layer_1 asset" do
      assert {:ok, %Asset{id: "BTC-BTC", type: :secured}} =
               Assets.to_secured(Assets.from_string("BTC.BTC"))
    end
  end

  describe "to_native/1" do
    test "maps the special-cased THOR assets onto their denoms" do
      assert {:ok, "rune"} = Assets.to_native(%{id: "THOR.RUNE"})
      assert {:ok, "x/ruji"} = Assets.to_native(%{id: "THOR.RUJI"})
      assert {:ok, "tcy"} = Assets.to_native(%{id: "THOR.TCY"})
    end

    test "downcases any other THOR asset" do
      assert {:ok, "thor.abc"} = Assets.to_native(%{id: "THOR.ABC"})
    end

    test "passes x/ denoms through untouched" do
      assert {:ok, "x/staking-ruji"} = Assets.to_native(%{id: "x/staking-ruji"})
    end

    test "joins chain and symbol for secured assets" do
      assert {:ok, "btc-btc"} =
               Assets.to_native(%{type: :secured, chain: "BTC", symbol: "BTC"})
    end

    test "accepts the string SECURED type as well as the atom" do
      assert {:ok, "btc-btc"} =
               Assets.to_native(%{type: "SECURED", chain: "BTC", symbol: "BTC"})
    end

    test "routes a layer_1 asset through to_secured/1" do
      assert {:ok, "btc-btc"} = Assets.to_native(Assets.from_string("BTC.BTC"))
    end

    test "handles a THOR asset whose id carries the prefix before reaching to_secured/1" do
      # The "THOR." <> _ clause matches first, so this never reaches the
      # to_secured/1 fallback below.
      assert {:ok, "thor.xyz"} = Assets.to_native(Assets.from_string("THOR.XYZ"))
    end

    test "propagates the to_secured/1 error for a THOR-chain asset with no prefix in its id" do
      # Reaching the %Asset{} fallback needs chain: "THOR" without a "THOR."
      # or "x/" id, which from_string/1 cannot produce — hence the literal struct.
      asset = %Asset{id: "RUNE", type: :native, chain: "THOR", symbol: "RUNE", ticker: "RUNE"}
      assert {:error, :not_supported} = Assets.to_native(asset)
    end

    test "passes nil through" do
      assert {:ok, nil} = Assets.to_native(nil)
    end
  end

  describe "label/1" do
    test "shows a bare ticker by default" do
      assert Assets.label(%{chain: "BTC", ticker: "BTC"}) == "BTC"
    end

    test "shows USDC on ETH without a chain suffix" do
      assert Assets.label(%{chain: "ETH", ticker: "USDC"}) == "USDC"
    end

    test "qualifies stablecoins on every other chain" do
      assert Assets.label(%{chain: "AVAX", ticker: "USDC"}) == "USDC.AVAX"
      assert Assets.label(%{chain: "ETH", ticker: "USDT"}) == "USDT.ETH"
    end

    test "qualifies ETH held on a non-ETH chain" do
      assert Assets.label(%{chain: "BSC", ticker: "ETH"}) == "ETH.BSC"
    end

    test "leaves native ETH unqualified" do
      assert Assets.label(%{chain: "ETH", ticker: "ETH"}) == "ETH"
    end
  end

  describe "load_metadata/1" do
    test "derives symbol and decimals from the asset for non-x/ denoms" do
      asset = Assets.from_string("ETH.USDC")
      assert {:ok, %{symbol: "USDC", decimals: 6}} = Assets.load_metadata(asset)
    end

    test "uses the 8-decimal default for a native asset" do
      asset = Assets.from_string("THOR.RUNE")
      assert {:ok, %{symbol: "RUNE", decimals: 8}} = Assets.load_metadata(asset)
    end
  end
end
