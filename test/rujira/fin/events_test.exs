defmodule Rujira.Fin.EventsTest do
  use ExUnit.Case, async: true

  alias Rujira.Events.Event
  alias Rujira.Fin.Events
  alias Rujira.Fin.Events.Arb
  alias Rujira.Fin.Events.Event, as: FinEvent
  alias Rujira.Fin.Events.OrderCreate
  alias Rujira.Fin.Events.OrderIncrease
  alias Rujira.Fin.Events.OrderRetract
  alias Rujira.Fin.Events.OrderWithdraw
  alias Rujira.Fin.Price
  alias Rujira.Fin.Events.RangeClaim
  alias Rujira.Fin.Events.RangeClose
  alias Rujira.Fin.Events.RangeCreate
  alias Rujira.Fin.Events.RangeDeposit
  alias Rujira.Fin.Events.RangeFee
  alias Rujira.Fin.Events.RangeTransfer
  alias Rujira.Fin.Events.RangeWithdraw
  alias Rujira.Fin.Events.Trade
  alias Rujira.Fin.Events.TradeRange
  alias Rujira.Fin.Range.Dynamic.Params

  # A dynamic fill: 20 colon-separated fields, ordered as the contract emits them.
  # pre_aep 100 → aep 120, gross 10 base sold for 1100 quote, so profit is
  # 1100 - 10 * 100 = 100, split 50/50 by a claimable_share of 0.5.
  @dynamic_fill "dynamic:7:base:100:120:120:110:10:0.1:btc-btc:10:1100:100:50:50:90:1050:0:50:9000"

  defp parse(type, attrs) do
    Events.parse(Event.new(type, Map.put(attrs, "_contract_address", "thor1abc")))
  end

  describe "trade" do
    test "order-pool fill with a fixed price" do
      assert {:ok, %FinEvent{address: "thor1abc", data: data}} =
               parse("wasm-rujira-fin/trade", %{
                 "side" => "Base",
                 "price" => "fixed:1.5",
                 "rate" => "1.5",
                 "offer" => "100",
                 "bid" => "150"
               })

      assert %Trade{side: :base, offer: 100, bid: 150, ranges: nil} = data
      assert %Price.Fixed{value: value} = data.price
      assert Decimal.equal?(value, Decimal.new("1.5"))
      assert Decimal.equal?(data.rate, Decimal.new("1.5"))
    end

    test "order-pool fill with an oracle price" do
      assert {:ok, %FinEvent{data: %Trade{price: %Price.Oracle{deviation: -25}}}} =
               parse("wasm-rujira-fin/trade", %{
                 "side" => "Quote",
                 "price" => "oracle:-25",
                 "rate" => "1.0",
                 "offer" => "100",
                 "bid" => "100"
               })
    end

    test "market-maker fill" do
      assert {:ok, %FinEvent{data: %Trade{price: %Price.MarketMaker{} = price}}} =
               parse("wasm-rujira-fin/trade", %{
                 "side" => "Base",
                 "price" => "thor1mm:0.97",
                 "rate" => "0.97",
                 "offer" => "103",
                 "bid" => "100"
               })

      assert price.address == "thor1mm"
      assert Decimal.equal?(price.rate, Decimal.new("0.97"))
    end

    test "concentrated-liquidity fill parses ranges into structs" do
      assert {:ok, %FinEvent{data: data}} =
               parse("wasm-rujira-fin/trade", %{
                 "side" => "Quote",
                 "price" => "ccl:0.95",
                 "rate" => "0.95",
                 "offer" => "1052",
                 "bid" => "1000",
                 "ranges" => "0:10-20:100:50:10:9::1,1:30-40:200:75:20:18:2:"
               })

      assert %Price.Ccl{rate: rate} = data.price
      assert Decimal.equal?(rate, Decimal.new("0.95"))
      assert [base_fill, quote_fill] = data.ranges
      assert %TradeRange{idx: 0, side: :base, range: %TradeRange.Fixed{} = base_range} = base_fill
      assert Decimal.equal?(base_range.low, Decimal.new("10"))
      assert Decimal.equal?(base_range.high, Decimal.new("20"))
      assert Decimal.equal?(base_range.fee, Decimal.new("1"))

      assert %TradeRange{idx: 1, side: :quote, range: %TradeRange.Fixed{} = quote_range} =
               quote_fill

      assert Decimal.equal?(quote_range.fee, Decimal.new("2"))
    end

    test "parses a real high-precision range entry" do
      ranges =
        "1:48-130:3745471358.610017999149322488:432374745.239347707518992478:2079070:99974982.0045::0"

      assert {:ok, %FinEvent{data: %{ranges: [range]}}} =
               parse("wasm-rujira-fin/trade", %{
                 "side" => "Base",
                 "price" => "ccl:0.115",
                 "rate" => "0.115",
                 "offer" => "2079070",
                 "bid" => "99974982",
                 "ranges" => ranges
               })

      assert %TradeRange{idx: 1, side: :base, range: %TradeRange.Fixed{} = fill} = range
      assert Decimal.equal?(fill.low, Decimal.new("48"))
      assert Decimal.equal?(fill.high, Decimal.new("130"))
      assert Decimal.equal?(fill.base, Decimal.new("3745471358.610017999149322488"))
      assert Decimal.equal?(fill.quote, Decimal.new("432374745.239347707518992478"))
      assert Decimal.equal?(fill.deduct, Decimal.new("2079070"))
      assert Decimal.equal?(fill.add, Decimal.new("99974982.0045"))
      assert Decimal.equal?(fill.fee, Decimal.new("0"))
    end

    test "dynamic fill parses the full profit attribution" do
      assert {:ok, %FinEvent{data: %{ranges: [range]}}} =
               parse("wasm-rujira-fin/trade", %{
                 "side" => "Base",
                 "price" => "ccl:110",
                 "rate" => "110",
                 "offer" => "10",
                 "bid" => "1100",
                 "ranges" => @dynamic_fill
               })

      assert %TradeRange{idx: 7, side: :base, range: %TradeRange.Dynamic{} = fill} = range
      assert fill.denom == "btc-btc"
      assert Decimal.equal?(fill.pre_aep, Decimal.new("100"))
      assert Decimal.equal?(fill.aep, Decimal.new("120"))
      assert Decimal.equal?(fill.oracle, Decimal.new("120"))
      assert Decimal.equal?(fill.effective_price, Decimal.new("110"))
      assert Decimal.equal?(fill.gross, Decimal.new("10"))
      assert Decimal.equal?(fill.fee, Decimal.new("0.1"))
      assert Decimal.equal?(fill.deduct, Decimal.new("10"))
      assert Decimal.equal?(fill.add, Decimal.new("1100"))
      assert Decimal.equal?(fill.cost_basis, Decimal.new("9000"))

      # profit realized against pre_aep, split by claimable_share
      assert Decimal.equal?(
               fill.profit,
               Decimal.sub(fill.add, Decimal.mult(fill.gross, fill.pre_aep))
             )

      assert Decimal.equal?(fill.profit, Decimal.add(fill.claimable, fill.compounded))
      assert Decimal.equal?(fill.claimable_quote, Decimal.new("50"))
      assert Decimal.equal?(fill.claimable_base, Decimal.new("0"))
    end

    test "fixed and dynamic entries can be mixed in one attribute" do
      assert {:ok, %FinEvent{data: %{ranges: [fixed, dynamic]}}} =
               parse("wasm-rujira-fin/trade", %{
                 "side" => "Base",
                 "price" => "ccl:110",
                 "rate" => "110",
                 "offer" => "20",
                 "bid" => "1150",
                 "ranges" => "0:10-20:100:50:10:9::1," <> @dynamic_fill
               })

      assert %TradeRange{idx: 0, range: %TradeRange.Fixed{}} = fixed
      assert %TradeRange{idx: 7, range: %TradeRange.Dynamic{}} = dynamic
    end

    test "a dynamic entry of the wrong arity is an error" do
      short = "dynamic:7:base:100:120:120:110:10:0.1:btc-btc:10:1100:100:50:50:90:1050:0:50"

      assert {:error, :invalid_range} =
               parse("wasm-rujira-fin/trade", %{
                 "side" => "Base",
                 "price" => "ccl:110",
                 "rate" => "110",
                 "offer" => "10",
                 "bid" => "1100",
                 "ranges" => short
               })
    end
  end

  describe "order" do
    test "order.create" do
      assert {:ok,
              %FinEvent{
                data: %OrderCreate{
                  owner: "thor1owner",
                  side: :base,
                  offer: 1000
                }
              }} =
               parse("wasm-rujira-fin/order.create", %{
                 "owner" => "thor1owner",
                 "side" => "Base",
                 "price" => "fixed:1.5",
                 "offer" => "1000"
               })
    end

    test "order.withdraw" do
      assert {:ok, %FinEvent{data: %OrderWithdraw{owner: "thor1owner", amount: 500}}} =
               parse("wasm-rujira-fin/order.withdraw", %{
                 "owner" => "thor1owner",
                 "side" => "Base",
                 "price" => "fixed:1.5",
                 "amount" => "500"
               })
    end

    test "order.increase" do
      assert {:ok, %FinEvent{data: %OrderIncrease{owner: "thor1owner", amount: 250}}} =
               parse("wasm-rujira-fin/order.increase", %{
                 "owner" => "thor1owner",
                 "side" => "Quote",
                 "price" => "oracle:100",
                 "amount" => "250"
               })
    end

    test "order.retract" do
      assert {:ok, %FinEvent{data: %OrderRetract{owner: "thor1owner", amount: 300}}} =
               parse("wasm-rujira-fin/order.retract", %{
                 "owner" => "thor1owner",
                 "side" => "Quote",
                 "price" => "fixed:1",
                 "amount" => "300"
               })
    end
  end

  describe "range (fixed)" do
    test "range.create carries the full config" do
      assert {:ok, %FinEvent{data: data}} =
               parse("wasm-rujira-fin/range.create", %{
                 "idx" => "5",
                 "owner" => "thor1owner",
                 "high" => "2.0",
                 "low" => "1.0",
                 "skew" => "-0.1",
                 "spread" => "0.01",
                 "fee" => "0.003",
                 "base" => "1000",
                 "quote" => "2000"
               })

      assert %RangeCreate{idx: 5, owner: "thor1owner", range: %RangeCreate.Fixed{} = range} = data
      assert range.base == 1000
      assert range.quote == 2000
      assert Decimal.equal?(range.skew, Decimal.new("-0.1"))
      assert Decimal.equal?(range.high, Decimal.new("2.0"))
    end

    test "range.deposit" do
      assert {:ok,
              %FinEvent{
                data: %RangeDeposit{
                  idx: 3,
                  owner: "thor1x",
                  range: %RangeDeposit.Fixed{base: 10, quote: 20}
                }
              }} =
               parse("wasm-rujira-fin/range.deposit", %{
                 "idx" => "3",
                 "owner" => "thor1x",
                 "base" => "10",
                 "quote" => "20"
               })
    end

    test "range.withdraw" do
      assert {:ok, %FinEvent{data: data}} =
               parse("wasm-rujira-fin/range.withdraw", %{
                 "idx" => "7",
                 "owner" => "thor1y",
                 "amount" => "0.5",
                 "base" => "100",
                 "quote" => "200"
               })

      assert %RangeWithdraw{idx: 7, owner: "thor1y", range: %RangeWithdraw.Fixed{} = range} = data
      assert range.base == 100
      assert range.quote == 200
      assert Decimal.equal?(range.amount, Decimal.new("0.5"))
    end

    test "range.close" do
      assert {:ok,
              %FinEvent{
                data: %RangeClose{
                  idx: 1,
                  owner: "thor1z",
                  range: %RangeClose.Fixed{base: 5, quote: 6, fee_base: 1, fee_quote: 2}
                }
              }} =
               parse("wasm-rujira-fin/range.close", %{
                 "idx" => "1",
                 "owner" => "thor1z",
                 "base" => "5",
                 "quote" => "6",
                 "fee_base" => "1",
                 "fee_quote" => "2"
               })
    end

    test "range.claim" do
      assert {:ok,
              %FinEvent{
                data: %RangeClaim{
                  idx: 2,
                  owner: "thor1w",
                  range: %RangeClaim.Fixed{base: 7, quote: 8}
                }
              }} =
               parse("wasm-rujira-fin/range.claim", %{
                 "idx" => "2",
                 "owner" => "thor1w",
                 "base" => "7",
                 "quote" => "8"
               })
    end

    test "range.transfer" do
      assert {:ok,
              %FinEvent{
                data: %RangeTransfer{
                  idx: 4,
                  from: "thor1a",
                  to: "thor1b",
                  range: %RangeTransfer.Fixed{}
                }
              }} =
               parse("wasm-rujira-fin/range.transfer", %{
                 "idx" => "4",
                 "from" => "thor1a",
                 "to" => "thor1b"
               })
    end

    test "range.fee carries base/quote and no idx" do
      assert {:ok, %FinEvent{data: %RangeFee{base: 5, quote: 6}}} =
               parse("wasm-rujira-fin/range.fee", %{"base" => "5", "quote" => "6"})
    end
  end

  describe "range (dynamic)" do
    test "range.create carries the strategy params" do
      assert {:ok, %FinEvent{data: data}} =
               parse("wasm-rujira-fin/range.create", %{
                 "range_type" => "dynamic",
                 "idx" => "9",
                 "owner" => "thor1owner",
                 "min_profit" => "0.01",
                 "claimable_share" => "0.5",
                 "bid_depth" => "0.1",
                 "ask_depth" => "0.2",
                 "skew" => "1.5",
                 "reanchor_aep_on_sellout" => "true",
                 "base" => "1000",
                 "quote" => "2000",
                 "aep" => "100"
               })

      assert %RangeCreate{idx: 9, owner: "thor1owner", range: %RangeCreate.Dynamic{} = range} =
               data

      assert range.base == 1000
      assert range.quote == 2000
      assert Decimal.equal?(range.aep, Decimal.new("100"))

      assert %Params{reanchor_aep_on_sellout: true} = range.params
      assert Decimal.equal?(range.params.min_profit, Decimal.new("0.01"))
      assert Decimal.equal?(range.params.claimable_share, Decimal.new("0.5"))
      assert Decimal.equal?(range.params.bid_depth, Decimal.new("0.1"))
      assert Decimal.equal?(range.params.ask_depth, Decimal.new("0.2"))
      assert Decimal.equal?(range.params.skew, Decimal.new("1.5"))
    end

    test "range.deposit reports the resulting aep" do
      assert {:ok, %FinEvent{data: data}} =
               parse("wasm-rujira-fin/range.deposit", %{
                 "range_type" => "dynamic",
                 "idx" => "3",
                 "owner" => "thor1x",
                 "base" => "10",
                 "quote" => "20",
                 "aep" => "1.25"
               })

      assert %RangeDeposit{idx: 3, owner: "thor1x", range: %RangeDeposit.Dynamic{} = range} = data
      assert range.base == 10
      assert range.quote == 20
      assert Decimal.equal?(range.aep, Decimal.new("1.25"))
    end

    test "range.withdraw has no amount" do
      assert {:ok, %FinEvent{data: data}} =
               parse("wasm-rujira-fin/range.withdraw", %{
                 "range_type" => "dynamic",
                 "idx" => "7",
                 "owner" => "thor1y",
                 "base" => "100",
                 "quote" => "200",
                 "aep" => "2"
               })

      assert %RangeWithdraw{idx: 7, owner: "thor1y", range: %RangeWithdraw.Dynamic{} = range} =
               data

      assert range.base == 100
      assert range.quote == 200
      assert Decimal.equal?(range.aep, Decimal.new("2"))
    end

    test "range.close returns floored claimable balances" do
      assert {:ok,
              %FinEvent{
                data: %RangeClose{
                  idx: 1,
                  owner: "thor1z",
                  range: %RangeClose.Dynamic{
                    base: 5,
                    quote: 6,
                    claimable_base: 1,
                    claimable_quote: 2
                  }
                }
              }} =
               parse("wasm-rujira-fin/range.close", %{
                 "range_type" => "dynamic",
                 "idx" => "1",
                 "owner" => "thor1z",
                 "base" => "5",
                 "quote" => "6",
                 "claimable_base" => "1",
                 "claimable_quote" => "2"
               })
    end

    test "range.claim carries the oracle valuation" do
      assert {:ok, %FinEvent{data: data}} =
               parse("wasm-rujira-fin/range.claim", %{
                 "range_type" => "dynamic",
                 "idx" => "2",
                 "owner" => "thor1w",
                 "base" => "7",
                 "quote" => "8",
                 "oracle" => "100",
                 "quote_value" => "708",
                 "claimable_base" => "1.5",
                 "claimable_quote" => "2.25"
               })

      assert %RangeClaim{idx: 2, owner: "thor1w", range: %RangeClaim.Dynamic{} = range} = data
      assert range.base == 7
      assert range.quote == 8
      assert Decimal.equal?(range.oracle, Decimal.new("100"))
      assert Decimal.equal?(range.quote_value, Decimal.new("708"))

      # unlike range.close, these keep the contract's full precision
      assert Decimal.equal?(range.claimable_base, Decimal.new("1.5"))
      assert Decimal.equal?(range.claimable_quote, Decimal.new("2.25"))
    end

    test "range.claim with no oracle available" do
      assert {:ok, %FinEvent{data: data}} =
               parse("wasm-rujira-fin/range.claim", %{
                 "range_type" => "dynamic",
                 "idx" => "2",
                 "owner" => "thor1w",
                 "base" => "7",
                 "quote" => "8",
                 "oracle" => "",
                 "quote_value" => "",
                 "claimable_base" => "0",
                 "claimable_quote" => "0"
               })

      assert %RangeClaim{range: %RangeClaim.Dynamic{oracle: nil, quote_value: nil}} = data
    end

    test "range.transfer" do
      assert {:ok,
              %FinEvent{
                data: %RangeTransfer{
                  idx: 4,
                  from: "thor1a",
                  to: "thor1b",
                  range: %RangeTransfer.Dynamic{}
                }
              }} =
               parse("wasm-rujira-fin/range.transfer", %{
                 "range_type" => "dynamic",
                 "idx" => "4",
                 "from" => "thor1a",
                 "to" => "thor1b"
               })
    end

    test "a malformed dynamic event is an error, not a passthrough" do
      assert {:error, :invalid_attrs} =
               parse("wasm-rujira-fin/range.create", %{
                 "range_type" => "dynamic",
                 "idx" => "5",
                 "owner" => "thor1owner",
                 "base" => "1000",
                 "quote" => "2000"
                 # no aep, no params
               })
    end

    test "an unrecognised range_type falls back to the raw event" do
      assert {:ok, %FinEvent{address: "thor1abc", data: %Event{type: type}}} =
               parse("wasm-rujira-fin/range.create", %{
                 "range_type" => "something_new",
                 "idx" => "5",
                 "owner" => "thor1owner"
               })

      assert type == "wasm-rujira-fin/range.create"
    end
  end

  describe "arb" do
    test "arb" do
      assert {:ok, %FinEvent{data: %Arb{base: 100, quote: 200}}} =
               parse("wasm-rujira-fin/arb", %{"base" => "100", "quote" => "200"})
    end
  end

  describe "fallbacks" do
    test "wraps unknown FIN sub-type in envelope" do
      assert {:ok, %FinEvent{address: "thor1abc", data: %Event{}}} =
               parse("wasm-rujira-fin/unknown_action", %{})
    end

    test "returns default event for non-FIN unknown type" do
      e = Event.new("wasm-other/something", %{})

      assert {:ok, %FinEvent{address: nil, data: %Event{type: "wasm-other/something"}}} =
               Events.parse(e)
    end
  end
end
