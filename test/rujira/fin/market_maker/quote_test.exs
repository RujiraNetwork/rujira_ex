defmodule Rujira.Fin.MarketMaker.QuoteTest do
  @moduledoc """
  A quote is read through `Rujira.Cache`, whose stores and head are global, so
  this case runs sync and starts from an empty cache.
  """
  use Rujira.Test.CacheCase, async: false

  alias Rujira.Assets
  alias Rujira.Fin.MarketMaker.Quote
  alias Rujira.Test.MockNode

  @height 500
  @metadata %{"x-cosmos-block-height" => "500"}

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

    test "returns not_found for a null response (nothing to quote)", %{btc: btc, rune: rune} do
      assert {:error, :not_found} =
               Quote.new(%{address: "thor1mm", offer: btc, ask: rune}, nil)
    end
  end

  describe "query/5" do
    test "queries with a null min_price when none is given", %{btc: btc, rune: rune} do
      MockNode.expect(fn
        %{"quote" => %{"min_price" => nil, "offer_denom" => "btc-btc", "ask_denom" => "rune"}} ->
          MockNode.ok(%{"price" => "1.5", "size" => "1000000", "data" => nil})
      end)

      assert {:ok, %Quote{price: price, size: size}} = Quote.query("thor1mm", btc, rune)

      assert Decimal.equal?(price, Decimal.new("1.5"))
      assert size.amount == 1_000_000
    end

    test "returns not_found when the market maker responds null", %{btc: btc, rune: rune} do
      MockNode.expect(fn %{"quote" => _} -> MockNode.ok(nil) end)

      assert {:error, :not_found} = Quote.query("thor1mm", btc, rune)
    end

    test "serializes a decimal min_price on the wire", %{btc: btc, rune: rune} do
      MockNode.expect(fn
        %{"quote" => %{"min_price" => "1.5"}} ->
          MockNode.ok(%{"price" => "1.6", "size" => "500", "data" => nil})
      end)

      assert {:ok, %Quote{}} = Quote.query("thor1mm", btc, rune, Decimal.new("1.5"))
    end

    test "normalizes min_price so equal decimals share one cache key", %{btc: btc, rune: rune} do
      MockNode.expect(fn _ -> MockNode.ok(%{"price" => "1.5", "size" => "1", "data" => nil}) end)

      assert {:ok, _} = Quote.query("thor1mm", btc, rune, Decimal.new("1.50"), height: @height)
      assert {:ok, _} = Quote.query("thor1mm", btc, rune, Decimal.new("1.5"), height: @height)

      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end

    test "a height read carries the block-height metadata into the quote query", %{
      btc: btc,
      rune: rune
    } do
      MockNode.expect(fn _ -> MockNode.ok(%{"price" => "1.5", "size" => "1", "data" => nil}) end)

      assert {:ok, %Quote{}} = Quote.query("thor1mm", btc, rune, nil, height: @height)
      assert_received {:mock_node, _request, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "a quote is only the quote of its own height", %{btc: btc, rune: rune} do
      MockNode.expect(fn _ -> MockNode.ok(%{"price" => "1.5", "size" => "1", "data" => nil}) end)

      assert {:ok, %Quote{}} = Quote.query("thor1mm", btc, rune, nil, height: @height)
      assert {:ok, %Quote{}} = Quote.query("thor1mm", btc, rune, nil, height: @height - 1)

      assert_received {:mock_node, _, _}
      assert_received {:mock_node, _, _}
    end

    test "nothing to quote is a fact, cached like any other", %{btc: btc, rune: rune} do
      MockNode.expect(fn %{"quote" => _} -> MockNode.ok(nil) end)

      assert {:error, :not_found} = Quote.query("thor1mm", btc, rune, nil, height: @height)
      assert {:error, :not_found} = Quote.query("thor1mm", btc, rune, nil, height: @height)

      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end

    test "an error is never cached, so the next read retries it", %{btc: btc, rune: rune} do
      MockNode.expect(fn _ -> {:error, %GRPC.RPCError{status: 13, message: "boom"}} end)

      assert {:error, %GRPC.RPCError{}} =
               Quote.query("thor1mm", btc, rune, nil, height: @height)

      MockNode.expect(fn _ -> MockNode.ok(%{"price" => "1.5", "size" => "1", "data" => nil}) end)

      assert {:ok, %Quote{}} = Quote.query("thor1mm", btc, rune, nil, height: @height)
    end

    test "a heightless read is at the head, and has none before the first advance", %{
      btc: btc,
      rune: rune
    } do
      MockNode.expect(fn _ -> MockNode.ok(%{"price" => "1.5", "size" => "1", "data" => nil}) end)

      assert {:ok, %Quote{}} = Quote.query("thor1mm", btc, rune)

      reset_cache()
      assert {:error, :no_head} = Quote.query("thor1mm", btc, rune)
    end
  end
end
