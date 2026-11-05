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
  alias Rujira.Fin
  alias Rujira.Fin.Pair
  alias Rujira.Fin.Pair.ArbMarketMaker
  alias Rujira.Fin.Pair.Commit
  alias Rujira.Fin.Pair.MarketMaker
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

      assert pair.market_makers == [
               %MarketMaker{address: "thor1mm1", arb: false},
               %MarketMaker{address: "thor1mm2", arb: false}
             ]

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

      assert {:ok, %Pair{market_makers: [%MarketMaker{address: "thor1mm", arb: false}]}} =
               Pair.new(config)
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

  # One raw `config` reply per shape the contract has served (see the table in
  # `Rujira.Fin.Pair`). S8 is the live BTC/TRON-USDT reply from #26; the
  # historical shapes follow the upstream `schema/rujira-fin.json` at each
  # shape's commit, as no archive node is available to read them from.
  @s8_address "thor18wkpr24rha007awldxx5hkyxdtnw5jamnuez9e27y6qy9u0tpkrqukal6t"

  defp shape(:s8) do
    %{
      "arb_commits" => [],
      "arb_market_makers" => [
        %{"endblock" => "thor1g7cqgq389q738jrwnxhuah0u86t2pwnruvsdq70l7yt6egj6q9jq4kfeqf"}
      ],
      "commits" => [],
      "denoms" => ["btc-btc", "tron-usdt-tr7nhqjekqxgtci8q8zy4pl8otszgjlj6t"],
      "fee_address" => "thor1gm8q2gr25nzzsxzdp2mpja4hyvyhjlr4s6krcsgv2y953uu0js3qhwpus7",
      "fee_maker" => "0.00075",
      "fee_range" => "0.00025",
      "fee_taker" => "0.0015",
      "market_makers" => [
        %{
          "addr" => "thor1prh3ue5nd4he254eyg3vq4lxvzed65afp9prv9qvdl2cwfq6xcnqah3aet",
          "arb" => true
        }
      ],
      "oracles" => ["BTC", "USDT"],
      "range_delta" => "0.001",
      "range_min" => "1000",
      "tick" => 6
    }
  end

  # `9126d72` (feat/optimize): adds `arb_market_makers` and `arb_commits`;
  # `market_makers` are still addresses.
  defp shape(:s7) do
    Map.merge(shape(:s6), %{
      "arb_market_makers" => [%{"endblock" => "thor1arbend"}, %{"standard" => "thor1arbstd"}],
      "arb_commits" => [%{"addr" => "thor1arbcommit", "msg" => Base.encode64("{\"arb\":{}}")}]
    })
  end

  # `3666e52` (fin/v2.2.0): adds `commits`. Oracles are an `OraclePair`.
  defp shape(:s6) do
    Map.put(shape(:s5), "commits", [
      %{"addr" => "thor1commit", "msg" => Base.encode64("{\"swap\":{}}")}
    ])
  end

  # `04bf399` (v2.1.0): adds `range_min`.
  defp shape(:s5), do: Map.put(shape(:s4), "range_min", "250")

  # `87e7a32` (v2.0.0): `fee_amm` renamed to `fee_range`; oracles may be
  # enshrined symbols.
  defp shape(:s4) do
    shape(:s3)
    |> Map.delete("fee_amm")
    |> Map.merge(%{"fee_range" => "0.0003", "oracles" => ["ATOM", "USDC"]})
  end

  # `2c308f8` (RUJI Trade v1.2, unchanged through v1.3.0 `332a3d2`): adds
  # `range_delta` and `fee_amm`.
  defp shape(:s3), do: Map.merge(shape(:s2), %{"range_delta" => "0.002", "fee_amm" => "0.0005"})

  # `1736222` (Fin/v1.1.0): `market_makers` is a list of addresses.
  defp shape(:s2) do
    %{
      "denoms" => ["gaia-atom", "eth-usdc-0xabc"],
      "oracles" => [
        %{"chain" => "GAIA", "symbol" => "ATOM"},
        %{"chain" => "ETH", "symbol" => "USDC"}
      ],
      "market_makers" => ["thor1mm1", "thor1mm2"],
      "tick" => 6,
      "fee_taker" => "0.0015",
      "fee_maker" => "0.00075",
      "fee_address" => "thor1fee"
    }
  end

  # `3216240^` (Jan 2025): no market-maker key at all. `3216240` added the
  # singular `market_maker`, so S1 is older than S0.
  defp shape(:s1), do: Map.delete(shape(:s2), "market_makers")

  # `3216240` to `1736222^`: the singular, nullable `market_maker`.
  defp shape(:s0), do: Map.put(shape(:s1), "market_maker", "thor1mm")

  defp serve_config(config) do
    MockNode.expect(fn
      %QueryContractInfosRequest{} ->
        {:ok,
         %{infos: [%ContractInfo{address: @s8_address, contract: "rujira-fin", version: "1"}]}}

      %QueryDenomMetadataRequest{denom: denom} ->
        {:error, %GRPC.RPCError{status: 5, message: "client metadata for denom #{denom}"}}

      %{"config" => _} ->
        MockNode.ok(config)
    end)
  end

  describe "config shapes, through Rujira.Fin" do
    test "S6: commits are typed, with their msg base64-decoded" do
      serve_config(shape(:s6))

      assert {:ok, %Pair{} = pair} = Fin.get_pair(@s8_address, height: @height)

      assert pair.commits == [%Commit{address: "thor1commit", msg: ~s({"swap":{}})}]
      assert pair.arb_market_makers == nil
      assert pair.arb_commits == nil
      assert pair.range_min == Decimal.new("250")
      assert [%MarketMaker{address: "thor1mm1", arb: false}, _] = pair.market_makers
    end

    test "S8: market makers are objects carrying the arb flag" do
      serve_config(shape(:s8))

      assert {:ok, %Pair{} = pair} = Fin.get_pair(@s8_address, height: @height)

      assert pair.market_makers == [
               %MarketMaker{
                 address: "thor1prh3ue5nd4he254eyg3vq4lxvzed65afp9prv9qvdl2cwfq6xcnqah3aet",
                 arb: true
               }
             ]

      assert pair.asset_base == asset("btc-btc")
      assert pair.tick == 6
      assert pair.fee_taker == Decimal.new("0.0015")
      assert pair.fee_maker == Decimal.new("0.00075")
    end

    test "S8 lists like any other pair" do
      serve_config(shape(:s8))

      assert {:ok, [%Pair{market_makers: [%MarketMaker{arb: true}]}]} =
               Fin.list_pairs(height: @height)
    end

    test "a market-maker object without arb reads as arb false" do
      shape(:s8)
      |> Map.put("market_makers", [%{"addr" => "thor1mm"}])
      |> serve_config()

      assert {:ok, %Pair{market_makers: [%MarketMaker{address: "thor1mm", arb: false}]}} =
               Fin.get_pair(@s8_address, height: @height)
    end

    test "a market-maker entry of unknown shape is an error" do
      shape(:s8)
      |> Map.put("market_makers", [%{"unexpected" => "thor1mm"}])
      |> serve_config()

      assert {:error, :invalid_attrs} = Fin.get_pair(@s8_address, height: @height)
    end

    test "unknown extra keys are ignored" do
      shape(:s8) |> Map.put("some_future_key", %{"x" => 1}) |> serve_config()

      assert {:ok, %Pair{market_makers: [%MarketMaker{arb: true}]}} =
               Fin.get_pair(@s8_address, height: @height)
    end

    test "S7: arb market makers and arb commits are typed, market makers still addresses" do
      serve_config(shape(:s7))

      assert {:ok, %Pair{} = pair} = Fin.get_pair(@s8_address, height: @height)

      assert pair.arb_market_makers == [
               %ArbMarketMaker{address: "thor1arbend", kind: :endblock},
               %ArbMarketMaker{address: "thor1arbstd", kind: :standard}
             ]

      assert pair.arb_commits == [%Commit{address: "thor1arbcommit", msg: ~s({"arb":{}})}]
      assert pair.commits == [%Commit{address: "thor1commit", msg: ~s({"swap":{}})}]
      assert [%MarketMaker{address: "thor1mm1", arb: false}, _] = pair.market_makers
      assert pair.range_min == Decimal.new("250")
    end

    test "S8: the live reply's arb market maker is typed, and its empty commits are []" do
      serve_config(shape(:s8))

      assert {:ok, %Pair{} = pair} = Fin.get_pair(@s8_address, height: @height)

      assert pair.arb_market_makers == [
               %ArbMarketMaker{
                 address: "thor1g7cqgq389q738jrwnxhuah0u86t2pwnruvsdq70l7yt6egj6q9jq4kfeqf",
                 kind: :endblock
               }
             ]

      assert pair.commits == []
      assert pair.arb_commits == []
    end

    test "S8: commits and arb commits carry decoded msg bytes, not parsed JSON" do
      shape(:s8)
      |> Map.merge(%{
        "commits" => [%{"addr" => "thor1commit", "msg" => "eyJzd2FwIjp7fX0="}],
        "arb_commits" => [%{"addr" => "thor1arbcommit", "msg" => "AAEC"}]
      })
      |> serve_config()

      assert {:ok, %Pair{} = pair} = Fin.get_pair(@s8_address, height: @height)

      assert pair.commits == [%Commit{address: "thor1commit", msg: ~s({"swap":{}})}]
      assert pair.arb_commits == [%Commit{address: "thor1arbcommit", msg: <<0, 1, 2>>}]
    end

    test "S6 to S8 list like any other pair" do
      for shape <- [:s6, :s7, :s8] do
        reset!()
        serve_config(shape(shape))

        assert {:ok, [%Pair{commits: commits}]} = Fin.list_pairs(height: @height)
        assert is_list(commits)
      end
    end

    test "S0 to S5 carry nil for commits, arb market makers and arb commits" do
      for shape <- [:s0, :s1, :s2, :s3, :s4, :s5] do
        reset!()
        serve_config(shape(shape))

        assert {:ok, %Pair{commits: nil, arb_market_makers: nil, arb_commits: nil}} =
                 Fin.get_pair(@s8_address, height: @height)
      end
    end

    test "a commit msg that is not base64 fails the pair read" do
      bad = [%{"addr" => "thor1commit", "msg" => "not base64!"}]

      for {shape, key} <- [s6: "commits", s7: "arb_commits", s8: "commits"] do
        reset!()
        shape(shape) |> Map.put(key, bad) |> serve_config()

        assert {:error, :invalid_msg} = Fin.get_pair(@s8_address, height: @height)
      end
    end

    test "an arb market maker of unknown kind is an error" do
      shape(:s8)
      |> Map.put("arb_market_makers", [%{"scheduled" => "thor1arb"}])
      |> serve_config()

      assert {:error, :invalid_attrs} = Fin.get_pair(@s8_address, height: @height)
    end

    test "arb market makers without arb commits match no shape" do
      shape(:s6) |> Map.put("arb_market_makers", []) |> serve_config()

      assert {:error, :invalid_attrs} = Fin.get_pair(@s8_address, height: @height)
    end

    test "commits without range_min match no shape" do
      shape(:s4) |> Map.put("commits", []) |> serve_config()

      assert {:error, :invalid_attrs} = Fin.get_pair(@s8_address, height: @height)
    end

    test "an unknown extra key is ignored on S6 and S7 too" do
      for shape <- [:s6, :s7] do
        reset!()
        shape(shape) |> Map.put("some_future_key", 1) |> serve_config()

        assert {:ok, %Pair{commits: [%Commit{}]}} = Fin.get_pair(@s8_address, height: @height)
      end
    end

    test "S3: fee_amm is read into fee_range, with range_delta and no range_min" do
      serve_config(shape(:s3))

      assert {:ok, %Pair{} = pair} = Fin.get_pair(@s8_address, height: @height)

      assert pair.fee_range == Decimal.new("0.0005")
      assert pair.range_delta == Decimal.new("0.002")
      assert pair.range_min == nil

      assert pair.market_makers == [
               %MarketMaker{address: "thor1mm1", arb: false},
               %MarketMaker{address: "thor1mm2", arb: false}
             ]
    end

    test "S4: fee_range is read, with range_delta and no range_min" do
      serve_config(shape(:s4))

      assert {:ok, %Pair{} = pair} = Fin.get_pair(@s8_address, height: @height)

      assert pair.fee_range == Decimal.new("0.0003")
      assert pair.range_delta == Decimal.new("0.002")
      assert pair.range_min == nil
      assert pair.oracle_base.id == "ATOM"
      assert [%MarketMaker{address: "thor1mm1", arb: false}, _] = pair.market_makers
    end

    test "S5: range_min is read alongside fee_range and range_delta" do
      serve_config(shape(:s5))

      assert {:ok, %Pair{} = pair} = Fin.get_pair(@s8_address, height: @height)

      assert pair.fee_range == Decimal.new("0.0003")
      assert pair.range_delta == Decimal.new("0.002")
      assert pair.range_min == Decimal.new("250")
    end

    test "S3, S4 and S5 list like any other pair" do
      for shape <- [:s3, :s4, :s5] do
        reset!()
        serve_config(shape(shape))

        assert {:ok, [%Pair{range_delta: range_delta}]} = Fin.list_pairs(height: @height)
        assert range_delta == Decimal.new("0.002")
      end
    end

    test "S8 carries the range fee fields" do
      serve_config(shape(:s8))

      assert {:ok, %Pair{} = pair} = Fin.get_pair(@s8_address, height: @height)

      assert pair.fee_range == Decimal.new("0.00025")
      assert pair.range_delta == Decimal.new("0.001")
      assert pair.range_min == Decimal.new("1000")
    end

    test "S0 to S2 carry nil for the range fee fields" do
      for shape <- [:s0, :s1, :s2] do
        reset!()
        serve_config(shape(shape))

        assert {:ok, %Pair{fee_range: nil, range_delta: nil, range_min: nil}} =
                 Fin.get_pair(@s8_address, height: @height)
      end
    end

    test "a non-numeric range fee field is an error" do
      for {shape, key} <- [
            s3: "fee_amm",
            s3: "range_delta",
            s4: "fee_range",
            s5: "range_min",
            s8: "range_delta"
          ] do
        reset!()
        shape(shape) |> Map.put(key, "abc") |> serve_config()

        assert {:error, :invalid_decimal} = Fin.get_pair(@s8_address, height: @height)
      end
    end

    test "fee_amm and fee_range together match no shape" do
      shape(:s4) |> Map.put("fee_amm", "0.0005") |> serve_config()

      assert {:error, :invalid_attrs} = Fin.get_pair(@s8_address, height: @height)
    end

    test "range_delta without a range fee matches no shape" do
      shape(:s2) |> Map.put("range_delta", "0.002") |> serve_config()

      assert {:error, :invalid_attrs} = Fin.get_pair(@s8_address, height: @height)
    end

    test "S2: plain address entries read as arb false" do
      serve_config(shape(:s2))

      assert {:ok, %Pair{} = pair} = Fin.get_pair(@s8_address, height: @height)

      assert pair.market_makers == [
               %MarketMaker{address: "thor1mm1", arb: false},
               %MarketMaker{address: "thor1mm2", arb: false}
             ]

      assert pair.oracle_base.id == "GAIA.ATOM"
      assert pair.fee_address == "thor1fee"
    end

    test "S1: no market-maker key reads as nil, not an empty list" do
      serve_config(shape(:s1))

      assert {:ok, %Pair{market_makers: nil, tick: 6}} =
               Fin.get_pair(@s8_address, height: @height)
    end

    test "S0: the singular market_maker becomes a one-entry list" do
      serve_config(shape(:s0))

      assert {:ok, %Pair{market_makers: [%MarketMaker{address: "thor1mm", arb: false}]}} =
               Fin.get_pair(@s8_address, height: @height)
    end

    test "S0: a nil market_maker is an empty list" do
      shape(:s0) |> Map.put("market_maker", nil) |> serve_config()

      assert {:ok, %Pair{market_makers: []}} = Fin.get_pair(@s8_address, height: @height)
    end

    test "a config missing a field every shape carries is an error" do
      shape(:s2) |> Map.delete("tick") |> serve_config()

      assert {:error, :invalid_attrs} = Fin.get_pair(@s8_address, height: @height)
    end

    test "both the singular and the plural key match no shape" do
      shape(:s2) |> Map.put("market_maker", "thor1mm") |> serve_config()

      assert {:error, :invalid_attrs} = Fin.get_pair(@s8_address, height: @height)
    end
  end

  describe "Pair.MarketMaker.new/1" do
    test "a plain address is a market maker without arb" do
      assert {:ok, %MarketMaker{address: "thor1mm", arb: false}} = MarketMaker.new("thor1mm")
    end

    test "an object carries its arb flag" do
      assert {:ok, %MarketMaker{address: "thor1mm", arb: true}} =
               MarketMaker.new(%{"addr" => "thor1mm", "arb" => true})
    end

    test "an object without arb defaults to false, as the contract does" do
      assert {:ok, %MarketMaker{address: "thor1mm", arb: false}} =
               MarketMaker.new(%{"addr" => "thor1mm"})
    end

    test "any other shape is invalid" do
      assert {:error, :invalid_attrs} = MarketMaker.new(%{"addr" => "thor1mm", "arb" => "yes"})
      assert {:error, :invalid_attrs} = MarketMaker.new(%{"address" => "thor1mm"})
      assert {:error, :invalid_attrs} = MarketMaker.new(nil)
      assert {:error, :invalid_attrs} = MarketMaker.new(42)
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
