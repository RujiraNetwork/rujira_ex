defmodule Rujira.Fin.OrderTest do
  use ExUnit.Case, async: true

  alias Rujira.Fin.Order

  describe "parse_price/1" do
    test "parses fixed price" do
      assert {:fixed, nil, "fixed:1000000"} = Order.parse_price(%{"fixed" => "1000000"})
    end

    test "parses oracle price" do
      assert {:oracle, 5, "oracle:5"} = Order.parse_price(%{"oracle" => 5})
    end
  end

  describe "decode_price/1" do
    test "decodes fixed price" do
      assert %{fixed: "1000000"} = Order.decode_price("fixed:1000000")
    end

    test "decodes oracle price" do
      assert %{oracle: 5} = Order.decode_price("oracle:5")
    end
  end

  describe "encode_price/1" do
    test "encodes fixed price" do
      assert "fixed:1000000" = Order.encode_price(%{fixed: "1000000"})
    end

    test "encodes oracle price" do
      assert "oracle:5" = Order.encode_price(%{oracle: 5})
    end
  end

  describe "new/4" do
    test "creates placeholder order" do
      order = Order.new("thor1pair", "base", "fixed:1000", "thor1owner")
      assert order.id == "thor1pair/base/fixed:1000/thor1owner"
      assert order.pair == "thor1pair"
      assert order.side == :base
      assert order.owner == "thor1owner"
      assert order.offer == 0
      assert order.remaining == 0
    end
  end
end
