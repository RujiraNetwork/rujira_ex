defmodule Rujira.Fin.OrderTest do
  @moduledoc """
  Every order read goes through `Rujira.Cache`, whose stores and head are
  global, so this case runs sync and starts from an empty cache.
  """
  use Rujira.Test.CacheCase, async: false

  alias Rujira.Fin.Order
  alias Rujira.Fin.Pair
  alias Rujira.Fin.Price
  alias Rujira.Test.MockNode

  @height 500
  @metadata %{"x-cosmos-block-height" => "500"}
  @fixed %Price.Fixed{value: Decimal.new("1")}
  @oracle %Price.Oracle{deviation: 5}

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

    test "an unrecognised response shape is an error, not a raise" do
      assert {:error, :invalid_attrs} =
               Order.new(%{address: "thor1pair"}, %{"owner" => "thor1owner"})
    end

    test "filled_value on a :base order flips the rate, unlike offer_value" do
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
        "rate" => "1.3",
        "updated_at" => "1700000000000000000",
        "offer" => "100000000",
        "remaining" => "50000000",
        "filled" => "50000001"
      }

      assert {:ok, %Order{} = order} = Order.new(pair, attrs)
      # base offer_value: mul_floor(offer, rate) = floor(100_000_000 * 1.3) = 130_000_000
      assert order.offer_value == 130_000_000
      # filled_value flips to :quote's rule: div_floor(filled, rate) = floor(50_000_001 / 1.3)
      assert order.filled_value == 38_461_539
    end

    test "filled_value on a :quote order flips the rate, unlike offer_value" do
      pair = %{
        address: "thor1pair",
        fee_maker: "0.0015",
        token_quote: "eth-usdc-0xabc",
        token_base: "gaia-atom"
      }

      attrs = %{
        "owner" => "thor1owner",
        "side" => "quote",
        "price" => %{"fixed" => "1000000"},
        "rate" => "1.3",
        "updated_at" => "1700000000000000000",
        "offer" => "100000000",
        "remaining" => "50000000",
        "filled" => "50000001"
      }

      assert {:ok, %Order{} = order} = Order.new(pair, attrs)
      # quote offer_value: div_floor(offer, rate) = floor(100_000_000 / 1.3)
      assert order.offer_value == 76_923_076
      # filled_value flips to :base's rule: mul_floor(filled, rate) = floor(50_000_001 * 1.3)
      assert order.filled_value == 65_000_001
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

  describe "filled_fee/2" do
    test "charges the filled amount the pair's maker fee, rounded up" do
      # 50_000_001 * 0.0015 = 75_000.0015 -> ceil 75_001 (floor would be 75_000)
      order = %Order{filled: 50_000_001}
      pair = %Pair{address: "thor1pair", fee_maker: Decimal.new("0.0015")}

      assert Order.filled_fee(order, pair) == 75_001
    end

    test "ignores the taker fee" do
      order = %Order{filled: 50_000_000}

      pair = %Pair{
        address: "thor1pair",
        fee_maker: Decimal.new("0.001"),
        fee_taker: Decimal.new("0.5")
      }

      assert Order.filled_fee(order, pair) == 50_000
    end
  end

  describe "load/5" do
    test "an order the pair does not hold is :not_found, not a placeholder" do
      MockNode.expect(fn _ -> {:error, not_found()} end)

      assert {:error, :not_found} = Order.load(pair(), :base, @fixed, "thor1owner")
    end

    test "any other failure propagates unchanged" do
      MockNode.expect(fn _ -> {:error, vm_error()} end)

      assert {:error, %GRPC.RPCError{status: 2}} =
               Order.load(pair(), :base, @fixed, "thor1owner")
    end
  end

  describe "query/5" do
    test "a height read carries the block-height metadata into the order query" do
      MockNode.expect(fn %{"order" => _} -> MockNode.ok(order_response()) end)

      assert {:ok, _} = Order.query("thor1pair", "thor1owner", :base, @fixed, height: @height)
      assert_received {:mock_node, _request, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "a second read at the same height is served from the cache" do
      MockNode.expect(fn %{"order" => _} -> MockNode.ok(order_response()) end)

      assert {:ok, _} = Order.query("thor1pair", "thor1owner", :base, @fixed, height: @height)
      assert {:ok, _} = Order.query("thor1pair", "thor1owner", :base, @fixed, height: @height)

      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end

    test "the price is keyed by its wire form, so equal prices are the one read" do
      MockNode.expect(fn %{"order" => _} -> MockNode.ok(order_response()) end)

      {:ok, long} = Price.parse_order("fixed:1.50")
      {:ok, short} = Price.parse_order("fixed:1.5")

      assert {:ok, _} = Order.query("thor1pair", "thor1owner", :base, long, height: @height)
      assert {:ok, _} = Order.query("thor1pair", "thor1owner", :base, short, height: @height)

      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end

    test "an oracle price is read per block, so another height reads again" do
      MockNode.expect(fn %{"order" => _} -> MockNode.ok(oracle_order_response()) end)

      assert {:ok, _} = Order.query("thor1pair", "thor1owner", :base, @oracle, height: @height)
      assert {:ok, _} = Order.query("thor1pair", "thor1owner", :base, @oracle, height: @height)

      assert {:ok, _} =
               Order.query("thor1pair", "thor1owner", :base, @oracle, height: @height - 1)

      assert_received {:mock_node, _, _}
      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end

    test "an error is never cached, so the next read retries it" do
      MockNode.expect(fn %{"order" => _} -> {:error, vm_error()} end)

      assert {:error, %GRPC.RPCError{}} =
               Order.query("thor1pair", "thor1owner", :base, @fixed, height: @height)

      MockNode.expect(fn %{"order" => _} -> MockNode.ok(order_response()) end)

      assert {:ok, _} = Order.query("thor1pair", "thor1owner", :base, @fixed, height: @height)
    end

    test "a heightless read is at the head, and has none before the first advance" do
      MockNode.expect(fn %{"order" => _} -> MockNode.ok(order_response()) end)

      assert {:ok, _} = Order.query("thor1pair", "thor1owner", :base, @fixed)

      reset_cache()
      assert {:error, :no_head} = Order.query("thor1pair", "thor1owner", :base, @fixed)
    end
  end

  describe "query_orders/3" do
    test "a page is read per block, so a second read at the same height is cached" do
      MockNode.expect(fn %{"orders" => _} -> MockNode.ok(%{"orders" => []}) end)

      assert {:ok, []} = Order.query_orders("thor1pair", nil, height: @height)
      assert {:ok, []} = Order.query_orders("thor1pair", nil, height: @height)

      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end

    test "another height is another page" do
      MockNode.expect(fn %{"orders" => _} -> MockNode.ok(%{"orders" => []}) end)

      assert {:ok, []} = Order.query_orders("thor1pair", nil, height: @height)
      assert {:ok, []} = Order.query_orders("thor1pair", nil, height: @height - 1)

      assert_received {:mock_node, _, _}
      assert_received {:mock_node, _, _}
    end
  end

  describe "from_id/2" do
    test "resolves by the address in the id, without reading the pair's config" do
      MockNode.expect(fn
        %{"config" => _} -> flunk("the pair's config was read to resolve an order id")
        %{"order" => ["thor1owner", "base", _]} -> MockNode.ok(order_response())
      end)

      assert {:ok, %Order{id: "thor1ordid/base/fixed:1000000/thor1owner", owner: "thor1owner"}} =
               Order.from_id("thor1ordid/base/fixed:1000000/thor1owner")
    end

    test "a malformed id is invalid" do
      assert {:error, :invalid_id} = Order.from_id("thor1pair/base")
    end
  end

  # --- Fixtures ---

  defp pair, do: %Pair{address: "thor1pair", fee_maker: Decimal.new("0.0015")}

  defp not_found do
    %GRPC.RPCError{status: 2, message: "NotFound: query wasm contract failed"}
  end

  defp vm_error do
    %GRPC.RPCError{
      status: 2,
      message: "codespace wasm code 29: wasmvm error: Error calling the VM"
    }
  end

  defp order_response do
    %{
      "owner" => "thor1owner",
      "side" => "base",
      "price" => %{"fixed" => "1000000"},
      "rate" => "1.5",
      "updated_at" => "1700000000000000000",
      "offer" => "100000000",
      "remaining" => "50000000",
      "filled" => "50000000"
    }
  end

  defp oracle_order_response, do: %{order_response() | "price" => %{"oracle" => 5}}
end
