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
  alias Rujira.Fin.Events.Price
  alias Rujira.Fin.Events.RangeClaim
  alias Rujira.Fin.Events.RangeClose
  alias Rujira.Fin.Events.RangeCreate
  alias Rujira.Fin.Events.RangeDeposit
  alias Rujira.Fin.Events.RangeFee
  alias Rujira.Fin.Events.RangeTransfer
  alias Rujira.Fin.Events.RangeWithdraw
  alias Rujira.Fin.Events.Trade
  alias Rujira.Fin.Events.TradeRange

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
                 "ranges" => "0:100:50:10:9::1,1:200:75:20:18:2:"
               })

      assert %Price.Ccl{rate: rate} = data.price
      assert Decimal.equal?(rate, Decimal.new("0.95"))
      assert [base_fill, quote_fill] = data.ranges
      assert %TradeRange{idx: 0, side: :base} = base_fill
      assert Decimal.equal?(base_fill.fee, Decimal.new("1"))
      assert %TradeRange{idx: 1, side: :quote} = quote_fill
      assert Decimal.equal?(quote_fill.fee, Decimal.new("2"))
    end
  end

  describe "order" do
    test "order.create" do
      assert {:ok,
              %FinEvent{
                data: %OrderCreate{
                  owner: "thor1owner",
                  side: :quote,
                  price: %Price.Fixed{},
                  offer: 1000
                }
              }} =
               parse("wasm-rujira-fin/order.create", %{
                 "owner" => "thor1owner",
                 "side" => "Quote",
                 "price" => "fixed:500",
                 "offer" => "1000"
               })
    end

    test "order.withdraw" do
      assert {:ok,
              %FinEvent{
                data: %OrderWithdraw{owner: "thor1owner", side: :base, amount: 250}
              }} =
               parse("wasm-rujira-fin/order.withdraw", %{
                 "owner" => "thor1owner",
                 "side" => "Base",
                 "price" => "oracle:0",
                 "amount" => "250"
               })
    end

    test "order.increase" do
      assert {:ok, %FinEvent{data: %OrderIncrease{amount: 500}}} =
               parse("wasm-rujira-fin/order.increase", %{
                 "owner" => "thor1owner",
                 "side" => "Base",
                 "price" => "fixed:1",
                 "amount" => "500"
               })
    end

    test "order.retract" do
      assert {:ok, %FinEvent{data: %OrderRetract{amount: 300}}} =
               parse("wasm-rujira-fin/order.retract", %{
                 "owner" => "thor1owner",
                 "side" => "Quote",
                 "price" => "fixed:1",
                 "amount" => "300"
               })
    end
  end

  describe "range" do
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

      assert %RangeCreate{idx: 5, owner: "thor1owner", base: 1000, quote: 2000} = data
      assert Decimal.equal?(data.skew, Decimal.new("-0.1"))
      assert Decimal.equal?(data.high, Decimal.new("2.0"))
    end

    test "range.deposit" do
      assert {:ok, %FinEvent{data: %RangeDeposit{idx: 3, owner: "thor1x", base: 10, quote: 20}}} =
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

      assert %RangeWithdraw{idx: 7, owner: "thor1y", base: 100, quote: 200} = data
      assert Decimal.equal?(data.amount, Decimal.new("0.5"))
    end

    test "range.close" do
      assert {:ok,
              %FinEvent{
                data: %RangeClose{
                  idx: 1,
                  owner: "thor1z",
                  base: 5,
                  quote: 6,
                  fee_base: 1,
                  fee_quote: 2
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
      assert {:ok, %FinEvent{data: %RangeClaim{idx: 2, owner: "thor1w", base: 7, quote: 8}}} =
               parse("wasm-rujira-fin/range.claim", %{
                 "idx" => "2",
                 "owner" => "thor1w",
                 "base" => "7",
                 "quote" => "8"
               })
    end

    test "range.transfer" do
      assert {:ok, %FinEvent{data: %RangeTransfer{idx: 4, from: "thor1a", to: "thor1b"}}} =
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
