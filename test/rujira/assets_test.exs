defmodule Rujira.AssetsTest do
  @moduledoc """
  Denom metadata is cached as an identity fact and the cache is global, so this
  case runs sync and starts from an empty one.
  """
  use Rujira.Test.CacheCase, async: false

  alias Cosmos.Bank.V1beta1.DenomUnit
  alias Cosmos.Bank.V1beta1.Metadata, as: DenomMetadata
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataRequest
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataResponse
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Assets.Metadata
  alias Rujira.Test.MockNode

  # A token-factory denom takes its identity from the chain's metadata for it.
  # Unless a test scripts one, these denoms are ones the node holds none for.
  setup do
    MockNode.expect(fn %QueryDenomMetadataRequest{denom: denom} -> no_denom_metadata(denom) end)
  end

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

    test "normalises lowercase and mixed-case ids to the uppercase asset" do
      assert Assets.from_string("eth.eth") == Assets.from_string("ETH.ETH")
      assert Assets.from_string("Eth.Usdc-0xAbC") == Assets.from_string("ETH.USDC-0XABC")
      assert Assets.from_string("btc-btc") == Assets.from_string("BTC-BTC")
      assert Assets.from_string("btc~btc") == Assets.from_string("BTC~BTC")
      assert Assets.from_string("btc/btc") == Assets.from_string("BTC/BTC")
    end

    test "derives type, decimals and conversions from a lowercase id" do
      eth = Assets.from_string("eth.eth")
      assert %Asset{id: "ETH.ETH", type: :layer_1, chain: "ETH"} = eth
      assert Assets.decimals(eth) == 18
      assert {:ok, "ETH.ETH"} = Assets.pool_id(eth)
      assert {:ok, "rune"} = Assets.to_native(Assets.from_string("thor.rune"))
    end

    test "keeps the case of x/ ids" do
      assert %Asset{id: "x/ruji", chain: "THOR"} = Assets.from_string("x/ruji")
      assert %Asset{id: "x/staking-ruji"} = Assets.from_string("x/staking-ruji")
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

    test "resolves well-formed asset ids across delimiters" do
      assert {:ok, %Asset{id: "GAIA-ATOM"}} = Assets.from_id("GAIA-ATOM")
      assert {:ok, %Asset{id: "BTC/BTC"}} = Assets.from_id("BTC/BTC")
      assert {:ok, %Asset{id: "BTC~BTC"}} = Assets.from_id("BTC~BTC")
    end

    test "accepts real THORChain ids" do
      for id <- [
            "ETH.USDC-0XA0B86991C6218B36C1D19D4A2E9EB0CE3606EB48",
            "THOR.RUNE",
            "BTC~BTC",
            "BTC/BTC",
            "BTC-BTC",
            "GAIA.ATOM"
          ] do
        assert {:ok, %Asset{id: ^id}} = Assets.from_id(id)
      end
    end

    test "normalises case like from_string/1" do
      assert {:ok, asset} = Assets.from_id("eth.usdc-0xabc")
      assert asset == Assets.from_string("ETH.USDC-0XABC")
      assert {:ok, %Asset{id: "THOR.RUNE"}} = Assets.from_id("Thor.Rune")
    end

    test "keeps the case of x/ ids" do
      assert {:ok, %Asset{id: "x/staking-ruji"}} = Assets.from_id("x/staking-ruji")
    end

    test "resolves an x/ id exactly as from_denom/2 does, chain metadata and all" do
      expect_metadata("RUJI")

      assert {:ok, %Asset{id: "x/from-id-test", ticker: "RUJI"} = asset} =
               Assets.from_id("x/from-id-test")

      assert {:ok, ^asset} = Assets.from_denom("x/from-id-test")
    end

    test "THOR.RUJI is x/ruji, the one asset behind both ids" do
      assert {:ok, asset} = Assets.from_id("x/ruji")
      assert {:ok, %Asset{id: "THOR.RUJI", symbol: "RUJI"}} = Assets.from_id("THOR.RUJI")
      assert {:ok, ^asset} = Assets.from_id("THOR.RUJI")
    end

    test "hands back the node's error when an x/ id's metadata cannot be read" do
      MockNode.expect(fn %QueryDenomMetadataRequest{} ->
        {:error, %GRPC.RPCError{status: 13, message: "boom"}}
      end)

      assert {:error, %GRPC.RPCError{status: 13}} = Assets.from_id("x/from-id-error-test")
    end

    test "returns an error instead of raising on a malformed id" do
      for id <- [
            "",
            "NOTANASSET",
            "BTC",
            ".BTC",
            "BTC.",
            "BTC..BTC",
            "BTC.BTC.BTC",
            "B1C.BTC",
            "BTC.BT$C",
            "ETH.USDC-0X1-0X2",
            "x/"
          ] do
        assert {:error, :invalid_asset_id} = Assets.from_id(id)
      end
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

    test "falls back to a token-factory asset for an unrecognised staked denom" do
      assert {:ok,
              %Asset{
                id: "x/staking-uruji",
                type: :native,
                chain: "THOR",
                symbol: "staking-uruji",
                ticker: "staking-uruji"
              }} = Assets.from_denom("x/staking-uruji")
    end

    test "names a generic x/ denom after the denom, as the chain spells it" do
      assert {:ok, %Asset{id: "x/foo", symbol: "foo", ticker: "foo", chain: "THOR"}} =
               Assets.from_denom("x/foo")

      assert {:ok, %Asset{id: "x/Foo-Bar", symbol: "Foo-Bar"}} = Assets.from_denom("x/Foo-Bar")
    end

    test "takes an x/ denom's symbol, ticker and decimals from the chain's metadata" do
      expect_metadata("yRUNE", 6)

      assert {:ok,
              %Asset{
                id: "x/metadata-test",
                type: :native,
                chain: "THOR",
                symbol: "yRUNE",
                ticker: "yRUNE",
                metadata: %Metadata{symbol: "yRUNE", decimals: 6}
              } = asset} = Assets.from_denom("x/metadata-test")

      assert Assets.decimals(asset) == 6
    end

    test "resolves tor, which THORChain names THOR.TOR" do
      assert {:ok, %Asset{id: "THOR.TOR", type: :native, chain: "THOR", ticker: "TOR"} = tor} =
               Assets.from_denom("tor")

      assert {:ok, "tor"} = Assets.to_native(tor)
    end

    test "upcases thor. denoms" do
      assert {:ok, %Asset{id: "THOR.ABC", symbol: "ABC", chain: "THOR"}} =
               Assets.from_denom("thor.abc")
    end

    test "resolves secured denoms, upcasing the id" do
      assert {:ok, %Asset{id: "BTC-BTC", chain: "BTC", ticker: "BTC", type: :secured}} =
               Assets.from_denom("btc-btc")
    end

    test "round-trips BNB through its BSC secured denom" do
      assert {:ok, %Asset{id: "BSC-BNB", chain: "BSC", type: :secured} = secured} =
               Assets.from_denom("bsc-bnb")

      assert {:ok, "bsc-bnb"} = Assets.to_native(secured)
      assert {:ok, "BSC.BNB"} = Assets.pool_id(secured)
      assert {:ok, ^secured} = Assets.to_secured(Assets.from_shortcode("BNB"))
    end

    test "never rewrites a denom's chain, so every denom round-trips" do
      assert {:ok, %Asset{chain: "BNB"} = asset} = Assets.from_denom("bnb-bnb")
      assert {:ok, "bnb-bnb"} = Assets.to_native(asset)
    end

    test "resolves synth and trade denoms" do
      assert {:ok, %Asset{id: "BTC/BTC", type: :synth, chain: "BTC", symbol: "BTC"}} =
               Assets.from_denom("btc/btc")

      assert {:ok, %Asset{id: "BTC~BTC", type: :trade, chain: "BTC", symbol: "BTC"}} =
               Assets.from_denom("btc~btc")
    end

    test "splits a contract suffix into symbol and ticker" do
      assert {:ok, %Asset{symbol: "USDC-0X123", ticker: "USDC"}} =
               Assets.from_denom("eth-usdc-0x123")
    end

    test "resolves the long TRON contract denoms" do
      assert {:ok, %Asset{id: "TRX-USDT-TR7NHQJEKQXGTCI8Q8ZY4PL8OTSZGJLJ6T", ticker: "USDT"}} =
               Assets.from_denom("trx-usdt-tr7nhqjekqxgtci8q8zy4pl8otszgjlj6t")
    end

    test "rejects a dotted asset id — those are ids, not denoms" do
      assert {:error, :invalid_denom} = Assets.from_denom("btc.btc")
      assert {:error, :invalid_denom} = Assets.from_denom("bnb.bnb")
      assert {:error, :invalid_denom} = Assets.from_denom("BTC.BTC")
    end

    test "keeps a token-factory denom native rather than reading it as secured" do
      assert {:ok, %Asset{id: "x/btc-btc", type: :native, chain: "THOR"}} =
               Assets.from_denom("x/btc-btc")
    end

    test "rejects a secured denom that is not all lowercase" do
      assert {:error, :invalid_denom} = Assets.from_denom("BTC-btc")
      assert {:error, :invalid_denom} = Assets.from_denom("btc-BTC")
      assert {:error, :invalid_denom} = Assets.from_denom("eth-USDC-0xa0b86991")
    end

    test "rejects a secured denom with a second suffix" do
      assert {:error, :invalid_denom} = Assets.from_denom("eth-usdc-0x123-extra")
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

    test "returns a secured asset unchanged" do
      asset = Assets.from_string("BTC-BTC")
      assert {:ok, ^asset} = Assets.to_secured(asset)
    end

    test "refuses trade assets" do
      assert {:error, :not_supported} = Assets.to_secured(Assets.from_string("BTC~BTC"))
    end

    test "refuses synth assets" do
      assert {:error, :not_supported} = Assets.to_secured(Assets.from_string("BTC/BTC"))
    end

    test "refuses token-factory denoms" do
      assert {:error, :not_supported} = Assets.to_secured(Assets.from_string("x/ruji"))
    end
  end

  describe "to_layer1/1" do
    test "converts a secured asset back to its layer_1 form" do
      assert {:ok, %Asset{id: "BTC.BTC", type: :layer_1, chain: "BTC", symbol: "BTC"}} =
               Assets.to_layer1(Assets.from_string("BTC-BTC"))
    end

    test "keeps a contract suffix in the symbol" do
      assert {:ok, %Asset{id: "ETH.USDC-0X123", type: :layer_1, ticker: "USDC"}} =
               Assets.to_layer1(Assets.from_string("ETH-USDC-0X123"))
    end

    test "converts synth and trade assets" do
      assert {:ok, %Asset{id: "BTC.BTC", type: :layer_1}} =
               Assets.to_layer1(Assets.from_string("BTC/BTC"))

      assert {:ok, %Asset{id: "BTC.BTC", type: :layer_1}} =
               Assets.to_layer1(Assets.from_string("BTC~BTC"))
    end

    test "returns a layer_1 asset unchanged" do
      asset = Assets.from_string("BTC.BTC")
      assert {:ok, ^asset} = Assets.to_layer1(asset)
    end

    test "returns a THOR asset unchanged" do
      asset = Assets.from_string("THOR.RUNE")
      assert {:ok, ^asset} = Assets.to_layer1(asset)
    end

    test "refuses token-factory denoms, which exist only on THORChain" do
      assert {:error, :not_supported} = Assets.to_layer1(Assets.from_string("x/ruji"))
      assert {:error, :not_supported} = Assets.to_layer1(Assets.from_string("x/staking-ruji"))
    end
  end

  describe "pool_id/1" do
    test "is the id of the layer_1 form" do
      assert {:ok, "BTC.BTC"} = Assets.pool_id(Assets.from_string("BTC-BTC"))
      assert {:ok, "BTC.BTC"} = Assets.pool_id(Assets.from_string("BTC.BTC"))
      assert {:ok, "BTC.BTC"} = Assets.pool_id(Assets.from_string("BTC~BTC"))
      assert {:ok, "THOR.RUNE"} = Assets.pool_id(Assets.from_string("THOR.RUNE"))
    end

    test "keeps the full symbol, as THORChain names the pool" do
      assert {:ok, "TRX.USDT-TR7NHQJEKQXGTCI8Q8ZY4PL8OTSZGJLJ6T"} =
               Assets.pool_id(Assets.from_string("TRX-USDT-TR7NHQJEKQXGTCI8Q8ZY4PL8OTSZGJLJ6T"))
    end

    test "propagates the to_layer1/1 error" do
      assert {:error, :not_supported} = Assets.pool_id(Assets.from_string("x/ruji"))
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

    test "refuses a layer_1 asset on another chain, rather than securing it silently" do
      assert {:error, :no_native_denom} = Assets.to_native(Assets.from_string("BTC.BTC"))
    end

    test "refuses synth and trade assets" do
      assert {:error, :no_native_denom} = Assets.to_native(Assets.from_string("BTC/BTC"))
      assert {:error, :no_native_denom} = Assets.to_native(Assets.from_string("BTC~BTC"))
    end

    test "handles a THOR asset whose id carries the prefix before reaching to_secured/1" do
      # The "THOR." <> _ clause matches first, so this never reaches the
      # to_secured/1 fallback below.
      assert {:ok, "thor.xyz"} = Assets.to_native(Assets.from_string("THOR.XYZ"))
    end

    test "refuses a THOR-chain asset whose id does not carry the chain" do
      # The THOR clauses key on the id, which is the canonical `CHAIN.SYMBOL`
      # identity. An asset built without it is not recognised as a THOR asset.
      asset = %Asset{id: "RUNE", type: :native, chain: "THOR", symbol: "RUNE", ticker: "RUNE"}
      assert {:error, :no_native_denom} = Assets.to_native(asset)
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

  describe "Metadata.load_metadata/1" do
    @denom "x/cached-metadata-test"

    test "queries the node once per denom, and again after the documented invalidation" do
      {:ok, calls} = Agent.start_link(fn -> 0 end)

      MockNode.expect(fn %QueryDenomMetadataRequest{denom: @denom} ->
        Agent.update(calls, &(&1 + 1))

        {:ok,
         %QueryDenomMetadataResponse{
           metadata: %DenomMetadata{
             description: "memoized",
             display: "MEMO",
             name: "Memo",
             symbol: "MEMO",
             uri: "",
             uri_hash: ""
           }
         }}
      end)

      assert {:ok, %Metadata{symbol: "MEMO"}} = Metadata.load_metadata(@denom)
      assert {:ok, %Metadata{symbol: "MEMO"}} = Metadata.load_metadata(@denom)
      assert Agent.get(calls, & &1) == 1

      Rujira.Cache.invalidate_all()

      assert {:ok, %Metadata{symbol: "MEMO"}} = Metadata.load_metadata(@denom)
      assert Agent.get(calls, & &1) == 2
    end

    test "the node holding no metadata for a denom is a cached fact" do
      {:ok, calls} = Agent.start_link(fn -> 0 end)

      MockNode.expect(fn %QueryDenomMetadataRequest{denom: @denom} ->
        Agent.update(calls, &(&1 + 1))
        no_denom_metadata(@denom)
      end)

      assert {:error, :not_found} = Metadata.load_metadata(@denom)
      assert {:error, :not_found} = Metadata.load_metadata(@denom)
      assert Agent.get(calls, & &1) == 1
    end

    test "returns the node's error unchanged when the query fails" do
      {:ok, calls} = Agent.start_link(fn -> 0 end)
      error = %GRPC.RPCError{status: 13, message: "boom"}

      MockNode.expect(fn %QueryDenomMetadataRequest{} ->
        Agent.update(calls, &(&1 + 1))
        {:error, error}
      end)

      assert {:error, ^error} = Metadata.load_metadata(@denom)
      assert {:error, ^error} = Metadata.load_metadata(@denom)
      assert Agent.get(calls, & &1) == 2
    end

    test "a failed query is not cached, so a later call retries and succeeds" do
      {:ok, calls} = Agent.start_link(fn -> 0 end)

      MockNode.expect(fn %QueryDenomMetadataRequest{denom: @denom} ->
        case Agent.get_and_update(calls, &{&1, &1 + 1}) do
          0 ->
            {:error, :not_found}

          _ ->
            {:ok,
             %QueryDenomMetadataResponse{
               metadata: %DenomMetadata{
                 description: "memoized",
                 display: "MEMO",
                 name: "Memo",
                 symbol: "MEMO",
                 uri: "",
                 uri_hash: ""
               }
             }}
        end
      end)

      assert {:error, :not_found} = Metadata.load_metadata(@denom)
      assert {:ok, %Metadata{symbol: "MEMO"}} = Metadata.load_metadata(@denom)
      assert Agent.get(calls, & &1) == 2
    end
  end

  describe "denom metadata is read at latest, not at height" do
    @height 12_345

    defp expect_metadata_once(symbol) do
      MockNode.expect(fn %QueryDenomMetadataRequest{} -> metadata_reply(symbol) end)
    end

    test "Metadata.load_metadata/2 with :height sends no height metadata" do
      expect_metadata_once("BRUNE")

      assert {:ok, %Metadata{symbol: "BRUNE"}} =
               Metadata.load_metadata("x/height-test-brune", height: @height)

      assert_received {:mock_node, %QueryDenomMetadataRequest{denom: "x/height-test-brune"}, opts}
      refute Keyword.has_key?(opts, :metadata)
    end

    test "Metadata.load_metadata/2 reuses the cached fact across a plain and a height read" do
      expect_metadata_once("BRUNE")

      assert {:ok, %Metadata{symbol: "BRUNE"}} = Metadata.load_metadata("x/height-test-memo")

      assert {:ok, %Metadata{symbol: "BRUNE"}} =
               Metadata.load_metadata("x/height-test-memo", height: @height)

      assert_received {:mock_node, %QueryDenomMetadataRequest{denom: "x/height-test-memo"}, _}
      refute_received {:mock_node, %QueryDenomMetadataRequest{}, _}
    end

    test "Assets.load_metadata/2 with :height ignores it and never returns an error" do
      expect_metadata_once("RUJI")

      assert {:ok, %{symbol: "RUJI"}} =
               Assets.load_metadata(%Asset{id: "x/height-test-ruji"}, height: @height)

      assert_received {:mock_node, %QueryDenomMetadataRequest{denom: "x/height-test-ruji"}, opts}
      refute Keyword.has_key?(opts, :metadata)
    end

    test "from_denom/2 with :height ignores it for the staking denom it wraps" do
      MockNode.expect(fn
        %QueryDenomMetadataRequest{denom: "x/staking-" <> _ = denom} -> no_denom_metadata(denom)
        %QueryDenomMetadataRequest{} -> metadata_reply("NAMI")
      end)

      assert {:ok, %Asset{id: "x/staking-x/nami-index-height-test-staking", symbol: "sNAMI"}} =
               Assets.from_denom("x/staking-x/nami-index-height-test-staking", height: @height)

      assert_received {:mock_node,
                       %QueryDenomMetadataRequest{denom: "x/nami-index-height-test-staking"},
                       opts}

      refute Keyword.has_key?(opts, :metadata)
    end

    test "from_denom/2 with :height ignores it for a nami index denom" do
      expect_metadata_once("NAMI")

      assert {:ok, %Asset{id: "x/nami-index-height-test", symbol: "NAMI"}} =
               Assets.from_denom("x/nami-index-height-test", height: @height)

      assert_received {:mock_node, %QueryDenomMetadataRequest{denom: "x/nami-index-height-test"},
                       opts}

      refute Keyword.has_key?(opts, :metadata)
    end

    test "display unit exponent 6 wins over another unit's exponent 8" do
      MockNode.expect(fn %QueryDenomMetadataRequest{denom: "x/decimals-display-wins"} ->
        {:ok,
         %QueryDenomMetadataResponse{
           metadata: %DenomMetadata{
             description: "",
             display: "DISP",
             name: "Display Wins",
             symbol: "DISP",
             uri: "",
             uri_hash: "",
             denom_units: [
               %DenomUnit{denom: "DISP", exponent: 6},
               %DenomUnit{denom: "UNIT", exponent: 8}
             ]
           }
         }}
      end)

      assert {:ok, %Metadata{symbol: "DISP", decimals: 6}} =
               Metadata.load_metadata("x/decimals-display-wins")
    end

    test "largest exponent 8 wins when display unit is base (exponent 0)" do
      MockNode.expect(fn %QueryDenomMetadataRequest{denom: "x/decimals-base-display"} ->
        {:ok,
         %QueryDenomMetadataResponse{
           metadata: %DenomMetadata{
             description: "",
             display: "BASE",
             name: "Base Display",
             symbol: "BASE",
             uri: "",
             uri_hash: "",
             denom_units: [
               %DenomUnit{denom: "BASE", exponent: 0},
               %DenomUnit{denom: "UNIT", exponent: 8}
             ]
           }
         }}
      end)

      assert {:ok, %Metadata{symbol: "BASE", decimals: 8}} =
               Metadata.load_metadata("x/decimals-base-display")
    end

    test "decimals is nil when there are no denom_units" do
      MockNode.expect(fn %QueryDenomMetadataRequest{denom: "x/decimals-empty"} ->
        {:ok,
         %QueryDenomMetadataResponse{
           metadata: %DenomMetadata{
             description: "",
             display: "EMPTY",
             name: "Empty Units",
             symbol: "EMPTY",
             uri: "",
             uri_hash: "",
             denom_units: []
           }
         }}
      end)

      assert {:ok, %Metadata{symbol: "EMPTY", decimals: nil}} =
               Metadata.load_metadata("x/decimals-empty")
    end

    test "eq_denom/3 with :height ignores it" do
      expect_metadata_once("NAMI")

      assert Assets.eq_denom(
               %Asset{chain: "THOR", ticker: "NAMI"},
               "x/nami-index-height-test-eq",
               height: @height
             )

      assert_received {:mock_node,
                       %QueryDenomMetadataRequest{denom: "x/nami-index-height-test-eq"}, opts}

      refute Keyword.has_key?(opts, :metadata)
    end
  end

  # --- Metadata replies ---

  defp expect_metadata(symbol, decimals \\ 8) do
    MockNode.expect(fn %QueryDenomMetadataRequest{} -> metadata_reply(symbol, decimals) end)
  end

  defp metadata_reply(symbol, decimals \\ 8) do
    {:ok,
     %QueryDenomMetadataResponse{
       metadata: %DenomMetadata{
         description: "",
         display: symbol,
         name: symbol,
         symbol: symbol,
         uri: "",
         uri_hash: "",
         denom_units: [%DenomUnit{denom: symbol, exponent: decimals}]
       }
     }}
  end

  # The node's own reply for a denom it holds no metadata for.
  defp no_denom_metadata(denom),
    do: {:error, %GRPC.RPCError{status: 5, message: "client metadata for denom #{denom}"}}
end
