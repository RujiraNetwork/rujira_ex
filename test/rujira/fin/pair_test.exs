defmodule Rujira.Fin.PairTest do
  @moduledoc """
  The pair list is read through `Rujira.Cache`, whose stores and head are
  global, so this case runs sync and starts from an empty cache.
  """
  use Rujira.Test.CacheCase, async: false

  alias Cosmos.Bank.V1beta1.Metadata, as: DenomMetadata
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataRequest
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataResponse
  alias Rujira.Assets
  alias Rujira.Fin.Pair
  alias Rujira.Test.MockNode
  alias Rujira.Thorchain.Oracle
  alias Thorchain.Types.ContractInfo
  alias Thorchain.Types.QueryContractInfosRequest

  @height 500
  @metadata %{"x-cosmos-block-height" => "500"}

  defp asset(denom) do
    {:ok, asset} = Assets.from_denom(denom)
    asset
  end

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
      assert pair.asset_base == asset("gaia-atom")
      assert pair.asset_quote == asset("eth-usdc-0xabc")
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
      MockNode.expect(fn %QueryDenomMetadataRequest{denom: "x/ruji"} ->
        {:error, %GRPC.RPCError{status: 5, message: "client metadata for denom x/ruji"}}
      end)

      assert {:ok, "x/ruji"} = Pair.pick_denom(["x/ruji", "x/ruji"], "RUJI")
    end
  end

  describe "pick_default/2" do
    defp pairs do
      [
        %Pair{
          address: "p_btc_rune",
          asset_base: asset("btc-btc"),
          asset_quote: asset("thor.rune")
        },
        %Pair{
          address: "p_btc_usdc",
          asset_base: asset("btc-btc"),
          asset_quote: asset("eth-usdc-0xabc")
        },
        %Pair{
          address: "p_eth_rune",
          asset_base: asset("eth-eth"),
          asset_quote: asset("thor.rune")
        }
      ]
    end

    test "prefers the stable (usdc/usdt) pair when one exists" do
      assert {:ok, %Pair{address: "p_btc_usdc"}} = Pair.pick_default(pairs(), "btc-btc")
    end

    test "falls back to the first pair quoting the base when no stable exists" do
      assert {:ok, %Pair{address: "p_eth_rune"}} = Pair.pick_default(pairs(), "eth-eth")
    end

    test "does not treat a usdc quote for a different base as a match" do
      pairs = [
        %Pair{
          address: "p_eth_usdc",
          asset_base: asset("eth-eth"),
          asset_quote: asset("eth-usdc-0xabc")
        }
      ]

      assert {:error, :not_found} = Pair.pick_default(pairs, "btc-btc")
    end

    test "returns :not_found when no pair quotes the base" do
      assert {:error, :not_found} = Pair.pick_default(pairs(), "doge-doge")
    end

    test "tolerates a nil asset_quote" do
      pairs = [%Pair{address: "p_nil_quote", asset_base: asset("btc-btc"), asset_quote: nil}]
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

    test "an oracle shape it does not know is an error, not a pair with no oracle" do
      config = %{
        "address" => "thor1pair",
        "market_makers" => [],
        "denoms" => ["gaia-atom", "eth-usdc-0xabc"],
        "oracles" => [%{"unexpected" => "shape"}],
        "tick" => 6,
        "fee_taker" => "0.0015",
        "fee_maker" => "0.00075",
        "fee_address" => "thor1fee"
      }

      assert {:error, :invalid_attrs} = Pair.new(config)
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

  describe "from_id/2 by asset form" do
    setup do
      MockNode.expect(fn
        %QueryContractInfosRequest{} ->
          {:ok,
           %{infos: [%ContractInfo{address: "thor1pair", contract: "rujira-fin", version: "1"}]}}

        %QueryDenomMetadataRequest{denom: "x/brune"} ->
          {:ok,
           %QueryDenomMetadataResponse{
             metadata: %DenomMetadata{
               description: "",
               display: "bRUNE",
               name: "Bonded RUNE",
               symbol: "bRUNE",
               uri: "",
               uri_hash: ""
             }
           }}

        %{"config" => _} ->
          MockNode.ok(brune_pair_config())
      end)
    end

    test "resolves a ticker the token spells in mixed case" do
      assert {:ok, %Pair{id: "THOR.bRUNE/THOR.RUNE", address: "thor1pair"}} =
               Pair.from_id("THOR.bRUNE/THOR.RUNE", height: @height)
    end

    test "resolves the same pair whatever case the ticker is typed in" do
      assert {:ok, %Pair{address: "thor1pair"}} =
               Pair.from_id("THOR.BRUNE/THOR.RUNE", height: @height)

      assert {:ok, %Pair{address: "thor1pair"}} =
               Pair.from_id("ThOr.bRuNe/THOR.RUNE", height: @height)
    end

    test "still matches the chain exactly" do
      assert {:error, :not_found} = Pair.from_id("BSC.bRUNE/THOR.RUNE", height: @height)
    end
  end

  describe "list/1" do
    setup do
      MockNode.expect(fn
        %QueryContractInfosRequest{} ->
          {:ok,
           %{infos: [%ContractInfo{address: "thor1pair", contract: "rujira-fin", version: "1"}]}}

        %QueryDenomMetadataRequest{denom: denom} ->
          {:error,
           %GRPC.RPCError{status: 5, message: "client metadata for denom #{denom}: not found"}}

        %{"config" => _} ->
          MockNode.ok(brune_pair_config())
      end)
    end

    test "a height read carries the block-height metadata into every leg" do
      assert {:ok, [%Pair{address: "thor1pair"}]} = Pair.list(height: @height)

      for {request, opts} <- config_and_registry_calls() do
        assert Keyword.get(opts, :metadata) == @metadata,
               "#{inspect(request)} did not carry the height"
      end
    end

    test "a second read at the same height is served from the cache" do
      assert {:ok, [_]} = Pair.list(height: @height)
      flush()
      assert {:ok, [_]} = Pair.list(height: @height)

      assert config_and_registry_calls() == []
    end

    test "the lookups derived from it read nothing of their own" do
      assert {:ok, [_]} = Pair.list(height: @height)
      flush()

      assert {:ok, "x/brune"} = Pair.denom_for_ticker("bRUNE", height: @height)
      assert {:ok, %Pair{}} = Pair.find_by_denoms("x/brune", "rune", height: @height)
      assert {:ok, %Pair{}} = Pair.find_default("x/brune", height: @height)

      assert config_and_registry_calls() == []
    end

    test "another height is another list, so it reaches the node again" do
      assert {:ok, [_]} = Pair.list(height: @height)
      flush()
      assert {:ok, [_]} = Pair.list(height: @height - 1)

      assert config_and_registry_calls() != []
    end

    test "a heightless read is at the head, and has none before the first advance" do
      assert {:ok, [_]} = Pair.list()

      reset_cache()
      assert {:error, :no_head} = Pair.list()
    end

    test "the configs are fetched concurrently, not one at a time" do
      counter = :atomics.new(1, signed: false)

      MockNode.expect(fn
        %QueryContractInfosRequest{} ->
          {:ok,
           %{
             infos: [
               %ContractInfo{address: "thor1paira", contract: "rujira-fin", version: "1"},
               %ContractInfo{address: "thor1pairb", contract: "rujira-fin", version: "1"}
             ]
           }}

        %QueryDenomMetadataRequest{denom: denom} ->
          {:error,
           %GRPC.RPCError{status: 5, message: "client metadata for denom #{denom}: not found"}}

        %{"config" => _} ->
          :atomics.add(counter, 1, 1)
          # A sequential fetch would deadlock here forever, since the second
          # leg only starts once the first one returns.
          await_both_legs(counter)
          MockNode.ok(brune_pair_config())
      end)

      assert {:ok, [_, _]} = Pair.list(height: @height)
    end
  end

  defp await_both_legs(counter, attempts \\ 100)

  defp await_both_legs(_counter, 0),
    do: flunk("second config leg never started - fetch is not concurrent")

  defp await_both_legs(counter, attempts) do
    if :atomics.get(counter, 1) >= 2 do
      :ok
    else
      Process.sleep(5)
      await_both_legs(counter, attempts - 1)
    end
  end

  # Denom metadata is token identity, read at latest - it is the one query a
  # height read does not carry the height on, so it is not one of the legs.
  defp config_and_registry_calls(acc \\ []) do
    receive do
      {:mock_node, %QueryDenomMetadataRequest{}, _opts} -> config_and_registry_calls(acc)
      {:mock_node, request, opts} -> config_and_registry_calls([{request, opts} | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  defp flush do
    receive do
      {:mock_node, _, _} -> flush()
    after
      0 -> :ok
    end
  end

  defp brune_pair_config do
    %{
      "address" => "thor1pair",
      "market_makers" => [],
      "denoms" => ["x/brune", "rune"],
      "oracles" => [],
      "tick" => 6,
      "fee_taker" => "0.0015",
      "fee_maker" => "0.00075",
      "fee_address" => "thor1fee"
    }
  end
end
