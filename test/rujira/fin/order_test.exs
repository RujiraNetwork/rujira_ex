defmodule Rujira.Fin.OrderTest do
  use ExUnit.Case, async: true

  alias Rujira.Fin.Order
  alias Rujira.Fin.Pair
  alias Rujira.Fin.Price
  alias Rujira.Test.MockNode

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
    setup do
      # `query` is memoized on (address, owner, side, price).
      Memoize.invalidate(Rujira.Fin.Order)
      on_exit(fn -> Memoize.invalidate(Rujira.Fin.Order) end)
      :ok
    end

    test "an order the pair does not hold is :not_found, not a placeholder" do
      MockNode.expect(fn _ -> {:error, not_found()} end)

      assert {:error, :not_found} =
               Order.load(pair(), :base, %Price.Fixed{value: Decimal.new("1")}, "thor1owner")
    end

    test "any other failure propagates unchanged" do
      MockNode.expect(fn _ -> {:error, vm_error()} end)

      assert {:error, %GRPC.RPCError{status: 2}} =
               Order.load(pair(), :base, %Price.Fixed{value: Decimal.new("1")}, "thor1owner")
    end
  end

  describe "from_id/2" do
    setup do
      Memoize.invalidate(Rujira.Fin.Order)
      on_exit(fn -> Memoize.invalidate(Rujira.Fin.Order) end)
      :ok
    end

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
end
