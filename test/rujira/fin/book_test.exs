defmodule Rujira.Fin.BookTest do
  use ExUnit.Case, async: true

  alias Rujira.Fin.Book

  describe "from_query/2" do
    test "parses book from contract response" do
      data = %{
        "base" => [
          %{"price" => "1.5", "total" => "1000"},
          %{"price" => "1.6", "total" => "2000"}
        ],
        "quote" => [
          %{"price" => "1.4", "total" => "1500"},
          %{"price" => "1.3", "total" => "3000"}
        ]
      }

      assert {:ok, %Book{} = book} = Book.from_query("thor1pair", data)
      assert book.id == "thor1pair"
      assert length(book.asks) == 2
      assert length(book.bids) == 2

      [ask1, _ask2] = book.asks
      assert ask1.side == :ask
      assert ask1.price == Decimal.new("1.5")
      assert ask1.total == 1000

      [bid1, _bid2] = book.bids
      assert bid1.side == :bid
      assert bid1.price == Decimal.new("1.4")
      assert bid1.total == 1500

      # Center should be average of best ask and best bid
      assert book.center == Decimal.div(Decimal.add(Decimal.new("1.5"), Decimal.new("1.4")), 2)
    end

    test "handles empty book" do
      data = %{"base" => [], "quote" => []}
      assert {:ok, %Book{asks: [], bids: [], center: center}} = Book.from_query("thor1pair", data)
      assert Decimal.eq?(center, Decimal.new(0))
    end
  end

  describe "empty/1" do
    test "creates empty book" do
      book = Book.empty("thor1pair")
      assert book.id == "thor1pair"
      assert book.asks == []
      assert book.bids == []
    end
  end

  describe "depth/3" do
    test "returns 0 for empty side" do
      book = Book.empty("thor1pair")
      assert Book.depth(book, :bid, 0.02) == 0
      assert Book.depth(book, :ask, 0.02) == 0
    end

    test "calculates bid depth within deviation" do
      data = %{
        "base" => [%{"price" => "1.5", "total" => "1000"}],
        "quote" => [
          %{"price" => "1.4", "total" => "1000"},
          %{"price" => "1.0", "total" => "5000"}
        ]
      }

      {:ok, book} = Book.from_query("thor1pair", data)

      # With 2% deviation from best bid (1.4), lower bound = 1.372
      # Only first bid (1.4) is within range
      assert Book.depth(book, :bid, 0.02) == 1000

      # With 50% deviation, both bids should be included
      assert Book.depth(book, :bid, 0.5) == 6000
    end
  end
end
