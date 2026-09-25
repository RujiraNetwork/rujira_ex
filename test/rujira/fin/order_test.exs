defmodule Rujira.Fin.OrderTest do
  use ExUnit.Case, async: true

  alias Rujira.Fin.Order
  alias Rujira.Fin.Price

  describe "new/2" do
    test "parses order with fixed price from pair context" do
      pair = %{
        address: "thor1pair",
        fee_maker: "0.0015",
        token_quote: "eth-usdc-0xabc",
        token_base: "gaia-atom"
      }

      attrs = %{
        "owner" => "thor1owner",
        "side" => "base",
        "price" => %{"fixed" => "1000000"},
        "rate" => "1.5",
        "updated_at" => "1700000000000000000",
        "offer" => "100000000",
        "remaining" => "50000000",
        "filled" => "50000000"
      }

      assert {:ok, %Order{} = order} = Order.new(pair, attrs)
      assert order.pair == "thor1pair"
      assert order.owner == "thor1owner"
      assert order.side == :base
      assert order.type == :fixed
      assert %Price.Fixed{value: value} = order.price
      assert Decimal.equal?(value, Decimal.new("1000000"))
      assert order.id == "thor1pair/base/fixed:1000000/thor1owner"
      assert order.rate == Decimal.new("1.5")
      assert order.offer == 100_000_000
      assert order.remaining == 50_000_000
      assert order.filled == 50_000_000
    end

    test "charges filled amount the maker fee, rounded up" do
      pair = %{
        address: "thor1pair",
        fee_maker: "0.0015",
        token_quote: "eth-usdc-0xabc",
        token_base: "gaia-atom"
      }

      attrs = %{
        "owner" => "thor1owner",
        "side" => "base",
        "price" => %{"fixed" => "1000000"},
        "rate" => "1.5",
        "updated_at" => "1700000000000000000",
        "offer" => "100000001",
        "remaining" => "50000000",
        "filled" => "50000001"
      }

      # 50_000_001 * 0.0015 = 75_000.0015 -> ceil 75_001 (floor would be 75_000)
      assert {:ok, %Order{filled_fee: 75_001}} = Order.new(pair, attrs)
    end

    test "ignores the taker fee for filled orders" do
      pair = %{
        address: "thor1pair",
        fee_taker: "0.5",
        fee_maker: "0.001",
        token_quote: "eth-usdc-0xabc",
        token_base: "gaia-atom"
      }

      attrs = %{
        "owner" => "thor1owner",
        "side" => "base",
        "price" => %{"fixed" => "1000000"},
        "rate" => "1.5",
        "updated_at" => "1700000000000000000",
        "offer" => "100000000",
        "remaining" => "50000000",
        "filled" => "50000000"
      }

      assert {:ok, %Order{filled_fee: 50_000}} = Order.new(pair, attrs)
    end

    test "parses order with oracle price" do
      pair = %{
        address: "thor1pair",
        fee_maker: "0.0015",
        token_quote: "eth-usdc-0xabc",
        token_base: "gaia-atom"
      }

      attrs = %{
        "owner" => "thor1owner",
        "side" => "quote",
        "price" => %{"oracle" => 5},
        "rate" => "2.0",
        "updated_at" => "1700000000000000000",
        "offer" => "200000000",
        "remaining" => "200000000",
        "filled" => "0"
      }

      assert {:ok, %Order{type: :oracle, deviation: 5, price: %Price.Oracle{deviation: 5}}} =
               Order.new(pair, attrs)
    end
  end
end
