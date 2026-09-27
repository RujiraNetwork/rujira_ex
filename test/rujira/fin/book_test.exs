defmodule Rujira.Fin.BookTest do
  use ExUnit.Case, async: true

  alias Rujira.Fin.Book
  alias Rujira.Fin.Pair
  alias Rujira.Test.MockNode

  describe "new/2" do
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

      assert {:ok, %Book{} = book} = Book.new("thor1pair", data)
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

    test "an empty side leaves no centre and no spread" do
      data = %{"base" => [], "quote" => []}

      assert {:ok, %Book{asks: [], bids: [], center: nil, spread: nil}} =
               Book.new("thor1pair", data)
    end

    test "one empty side leaves no centre either" do
      data = %{"base" => [%{"price" => "1.5", "total" => "1000"}], "quote" => []}
      assert {:ok, %Book{center: nil, spread: nil}} = Book.new("thor1pair", data)
    end
  end

  describe "load/3" do
    setup do
      # `query` is memoized on the contract address.
      Memoize.invalidate(Rujira.Fin.Book)
      on_exit(fn -> Memoize.invalidate(Rujira.Fin.Book) end)
      :ok
    end

    test "a book that cannot be read is an error, not an empty book" do
      MockNode.expect(fn %{"book" => _} -> {:error, vm_error()} end)

      assert {:error, %GRPC.RPCError{status: 2}} = Book.load(pair())
    end

    test "the default limit keeps every level the contract returned" do
      MockNode.expect(fn %{"book" => _} -> MockNode.ok(levels(3)) end)

      assert {:ok, %Pair{book: %Book{bids: bids, asks: asks}}} = Book.load(pair())
      assert length(bids) == 3
      assert length(asks) == 3
    end

    test "a limit caps each side" do
      MockNode.expect(fn %{"book" => _} -> MockNode.ok(levels(3)) end)

      assert {:ok, %Pair{book: %Book{bids: [_], asks: [_]}}} = Book.load(pair(), 1)
    end
  end

  describe "from_id/2" do
    setup do
      Memoize.invalidate(Rujira.Fin.Book)
      on_exit(fn -> Memoize.invalidate(Rujira.Fin.Book) end)
      :ok
    end

    test "queries the address in the id, without reading the pair's config" do
      MockNode.expect(fn
        %{"config" => _} -> flunk("the pair's config was read to resolve a book id")
        %{"book" => _} -> MockNode.ok(levels(2))
      end)

      assert {:ok, %Book{id: "thor1bookid", bids: [_, _], asks: [_, _]}} =
               Book.from_id("thor1bookid")
    end
  end

  describe "depth/3" do
    test "returns 0 for empty side" do
      {:ok, book} = Book.new("thor1pair", %{"base" => [], "quote" => []})
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

      {:ok, book} = Book.new("thor1pair", data)

      # With 2% deviation from best bid (1.4), lower bound = 1.372
      # Only first bid (1.4) is within range
      assert Book.depth(book, :bid, 0.02) == 1000

      # With 50% deviation, both bids should be included
      assert Book.depth(book, :bid, 0.5) == 6000
    end
  end

  # --- Fixtures ---

  defp pair, do: %Pair{id: "thor1pair", address: "thor1pair"}

  defp vm_error do
    %GRPC.RPCError{
      status: 2,
      message: "codespace wasm code 29: wasmvm error: Error calling the VM"
    }
  end

  defp levels(n) do
    %{
      "base" => for(i <- 1..n, do: %{"price" => "1.#{4 + i}", "total" => "1000"}),
      "quote" => for(i <- 1..n, do: %{"price" => "1.#{4 - i}", "total" => "1000"})
    }
  end
end
