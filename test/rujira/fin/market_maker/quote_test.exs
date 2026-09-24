defmodule Rujira.Fin.MarketMaker.QuoteTest do
  use ExUnit.Case, async: true

  alias Rujira.Assets
  alias Rujira.Fin.MarketMaker.Quote
  alias Rujira.Test.MockNode

  setup do
    {:ok, btc} = Assets.from_denom("btc-btc")
    {:ok, rune} = Assets.from_denom("rune")
    %{btc: btc, rune: rune}
  end

  describe "new/2" do
    test "parses a quote response, dropping data", %{btc: btc, rune: rune} do
      assert {:ok,
              %Quote{
                address: "thor1mm",
                offer: ^btc,
                ask: ^rune,
                price: price,
                size: size
              }} =
               Quote.new(
                 %{address: "thor1mm", offer: btc, ask: rune},
                 %{"price" => "1.5", "size" => "1000000", "data" => "aGVsbG8="}
               )

      assert Decimal.equal?(price, Decimal.new("1.5"))
      assert size.asset == rune
      assert size.amount == 1_000_000
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = Quote.new(%{}, %{})
    end
  end

  describe "query/4" do
    setup do
      Memoize.invalidate(Quote)
      on_exit(fn -> Memoize.invalidate(Quote) end)
      :ok
    end

    test "queries with a null min_price when none is given", %{btc: btc, rune: rune} do
      MockNode.expect(fn
        %{"quote" => %{"min_price" => nil, "offer_denom" => "btc-btc", "ask_denom" => "rune"}} ->
          MockNode.ok(%{"price" => "1.5", "size" => "1000000", "data" => nil})
      end)

      assert {:ok, %Quote{price: price, size: size}} = Quote.query("thor1mm", btc, rune)

      assert Decimal.equal?(price, Decimal.new("1.5"))
      assert size.amount == 1_000_000
    end

    test "serializes a decimal min_price on the wire", %{btc: btc, rune: rune} do
      MockNode.expect(fn
        %{"quote" => %{"min_price" => "1.5"}} ->
          MockNode.ok(%{"price" => "1.6", "size" => "500", "data" => nil})
      end)

      assert {:ok, %Quote{}} = Quote.query("thor1mm", btc, rune, Decimal.new("1.5"))
    end

    test "normalizes min_price so equal decimals share a memoized cache key", %{
      btc: btc,
      rune: rune
    } do
      test_pid = self()

      MockNode.expect(fn query ->
        send(test_pid, {:queried, query})
        MockNode.ok(%{"price" => "1.5", "size" => "1", "data" => nil})
      end)

      assert {:ok, _} = Quote.query("thor1mm", btc, rune, Decimal.new("1.50"))
      assert {:ok, _} = Quote.query("thor1mm", btc, rune, Decimal.new("1.5"))

      assert_received {:queried, _}
      refute_received {:queried, _}
    end

    test "the documented Memoize.invalidate/3 call actually invalidates the cache", %{
      btc: btc,
      rune: rune
    } do
      MockNode.expect(fn _ ->
        MockNode.ok(%{"price" => "1.5", "size" => "1", "data" => nil})
      end)

      assert {:ok, %Quote{price: price}} = Quote.query("thor1mm", btc, rune, Decimal.new("1.5"))

      assert Decimal.equal?(price, Decimal.new("1.5"))

      MockNode.expect(fn _ ->
        MockNode.ok(%{"price" => "2.5", "size" => "1", "data" => nil})
      end)

      assert {:ok, %Quote{price: price}} = Quote.query("thor1mm", btc, rune, Decimal.new("1.5"))

      assert Decimal.equal?(price, Decimal.new("1.5"))

      Memoize.invalidate(Quote, :do_query, [
        "thor1mm",
        btc,
        rune,
        Decimal.normalize(Decimal.new("1.5"))
      ])

      assert {:ok, %Quote{price: price}} = Quote.query("thor1mm", btc, rune, Decimal.new("1.5"))

      assert Decimal.equal?(price, Decimal.new("2.5"))
    end
  end
end
