defmodule Rujira.Fin.PriceTest do
  use ExUnit.Case, async: true

  alias Rujira.Fin.Price

  describe "parse/1" do
    test "fixed" do
      assert {:ok, %Price.Fixed{value: value}} = Price.parse("fixed:1.5")
      assert Decimal.equal?(value, Decimal.new("1.5"))
    end

    test "oracle" do
      assert {:ok, %Price.Oracle{deviation: -25}} = Price.parse("oracle:-25")
    end

    test "ccl" do
      assert {:ok, %Price.Ccl{rate: rate}} = Price.parse("ccl:0.95")
      assert Decimal.equal?(rate, Decimal.new("0.95"))
    end

    test "market maker" do
      assert {:ok, %Price.MarketMaker{address: "thor1mm", rate: rate}} =
               Price.parse("thor1mm:0.97")

      assert Decimal.equal?(rate, Decimal.new("0.97"))
    end

    test "invalid" do
      assert {:error, :invalid_price} = Price.parse(nil)
      assert {:error, :invalid_decimal} = Price.parse("fixed:abc")
    end
  end

  describe "from_query/1" do
    test "fixed accepts string" do
      assert {:ok, %Price.Fixed{value: value}} = Price.from_query(%{"fixed" => "1000000"})
      assert Decimal.equal?(value, Decimal.new("1000000"))
    end

    test "oracle accepts integer" do
      assert {:ok, %Price.Oracle{deviation: 5}} = Price.from_query(%{"oracle" => 5})
    end

    test "invalid" do
      assert {:error, :invalid_price} = Price.from_query(%{"bogus" => 1})
    end
  end

  describe "round-trips" do
    test "to_id/parse_order is stable" do
      assert {:ok, price} = Price.parse_order("fixed:1.5")
      assert Price.to_id(price) == "fixed:1.5"
      assert {:ok, ^price} = Price.parse_order(Price.to_id(price))
    end

    test "to_query serialises decimals in normal notation, never scientific" do
      {:ok, fixed} = Price.from_query(%{"fixed" => "1000000"})
      assert Price.to_query(fixed) == %{fixed: "1000000"}
      assert Price.to_id(fixed) == "fixed:1000000"

      assert Price.to_query(%Price.Oracle{deviation: -25}) == %{oracle: -25}
    end
  end

  describe "canonical cache keys" do
    test "equal prices from different sources are equal terms" do
      assert {:ok, from_event} = Price.parse("fixed:1.50")
      assert {:ok, from_id} = Price.parse_order("fixed:1.5")
      assert {:ok, from_query} = Price.from_query(%{"fixed" => "1.500"})

      assert from_event == from_id
      assert from_id == from_query
    end
  end
end
