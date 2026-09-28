defmodule Rujira.Fin.BookTest do
  @moduledoc """
  A book is read through `Rujira.Cache`, whose stores and head are global, so
  this case runs sync and starts from an empty cache.
  """
  use Rujira.Test.CacheCase, async: false

  alias Rujira.Fin.Book
  alias Rujira.Fin.Pair
  alias Rujira.Test.MockNode

  @height 500
  @metadata %{"x-cosmos-block-height" => "500"}

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
    test "queries the address in the id, without reading the pair's config" do
      MockNode.expect(fn
        %{"config" => _} -> flunk("the pair's config was read to resolve a book id")
        %{"book" => _} -> MockNode.ok(levels(2))
      end)

      assert {:ok, %Book{id: "thor1bookid", bids: [_, _], asks: [_, _]}} =
               Book.from_id("thor1bookid")
    end
  end

  describe "query/2" do
    test "a height read carries the block-height metadata into the book query" do
      MockNode.expect(fn %{"book" => _} -> MockNode.ok(levels(1)) end)

      assert {:ok, _} = Book.query("thor1pair", height: @height)
      assert_received {:mock_node, _request, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "a second read at the same height is served from the cache" do
      MockNode.expect(fn %{"book" => _} -> MockNode.ok(levels(1)) end)

      assert {:ok, _} = Book.query("thor1pair", height: @height)
      assert {:ok, _} = Book.query("thor1pair", height: @height)

      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end

    test "a book is only the book of its own height, so another height reads again" do
      MockNode.expect(fn %{"book" => _} -> MockNode.ok(levels(1)) end)

      assert {:ok, _} = Book.query("thor1pair", height: @height)
      assert {:ok, _} = Book.query("thor1pair", height: @height - 1)

      assert_received {:mock_node, _, _}
      assert_received {:mock_node, _, _}
    end

    test "an error is never cached, so the next read retries it" do
      MockNode.expect(fn %{"book" => _} -> {:error, vm_error()} end)

      assert {:error, %GRPC.RPCError{}} = Book.query("thor1pair", height: @height)

      MockNode.expect(fn %{"book" => _} -> MockNode.ok(levels(1)) end)

      assert {:ok, _} = Book.query("thor1pair", height: @height)
    end

    test "a heightless read is at the head, and has none before the first advance" do
      MockNode.expect(fn %{"book" => _} -> MockNode.ok(levels(1)) end)

      assert {:ok, _} = Book.query("thor1pair")

      reset_cache()
      assert {:error, :no_head} = Book.query("thor1pair")
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
