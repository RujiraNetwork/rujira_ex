defmodule Rujira.Cache.StoreTest do
  @moduledoc """
  The stores' memory bounds: the exact store's retention, the frontier's row
  cap, and the sweep that drops what the head has invalidated.

  The tables are global, so this case runs sync.
  """
  use ExUnit.Case, async: false

  alias Rujira.Cache
  alias Rujira.Cache.Markers
  alias Rujira.Cache.Store
  alias Rujira.Cache.Tables
  alias Rujira.Node
  alias Rujira.Thorchain.Block
  alias Thorchain.Types.BlockEvent
  alias Thorchain.Types.BlockResponseHeader
  alias Thorchain.Types.EventKeyValuePair
  alias Thorchain.Types.QueryBlockResponse

  setup do
    Cache.reset!()
    on_exit(&Rujira.Test.CacheCase.reset!/0)
    :ok
  end

  describe "the exact store" do
    test "it holds retention distinct heights and drops the least recently inserted" do
      configure(retention: 3)
      gen = Tables.gen()

      for height <- [10, 11, 12] do
        assert :ok = Store.exact_put(gen, :key, height, {:at, height})
      end

      assert :ok = Store.exact_put(gen, :key, 13, {:at, 13})

      assert Store.exact_lookup(gen, :key, 10) == :miss
      assert {:ok, {:at, 11}} = Store.exact_lookup(gen, :key, 11)
      assert {:ok, {:at, 13}} = Store.exact_lookup(gen, :key, 13)
    end

    test "the height being inserted is never the one evicted" do
      configure(retention: 1)
      gen = Tables.gen()

      assert :ok = Store.exact_put(gen, :key, 10, :a)
      assert :ok = Store.exact_put(gen, :other, 10, :b)

      assert {:ok, :a} = Store.exact_lookup(gen, :key, 10)
      assert {:ok, :b} = Store.exact_lookup(gen, :other, 10)
    end

    test "a re-read height is not evicted by the heights that came before it" do
      configure(retention: 2)
      gen = Tables.gen()

      assert :ok = Store.exact_put(gen, :key, 10, :a)
      assert :ok = Store.exact_put(gen, :key, 11, :b)
      assert :ok = Store.exact_put(gen, :key, 10, :a)
      assert :ok = Store.exact_put(gen, :key, 12, :c)

      assert {:ok, :a} = Store.exact_lookup(gen, :key, 10)
      assert Store.exact_lookup(gen, :key, 11) == :miss
    end

    test "every row of an evicted height goes, and no other" do
      configure(retention: 1)
      gen = Tables.gen()

      assert :ok = Store.exact_put(gen, :a, 10, :a)
      assert :ok = Store.exact_put(gen, :b, 10, :b)
      assert :ok = Store.exact_put(gen, :c, 11, :c)

      assert :ets.info(Tables.exact(), :size) == 1
      assert {:ok, :c} = Store.exact_lookup(gen, :c, 11)
    end
  end

  describe "the sweep" do
    test "it drops rows the head has invalidated" do
      configure(sweep_per_block: 100)

      assert :ok = Node.advance(100)
      assert :ok = Store.frontier_put(Tables.gen(), :key, 100, [{:contract, "thor1pair"}], :v)
      assert :ok = Store.frontier_put(Tables.gen(), :other, 100, [{:contract, "thor1b"}], :v)
      assert :ets.info(Tables.frontier(), :size) == 2

      assert :ok =
               Node.advance(block(101, [event("wasm", %{"_contract_address" => "thor1pair"})]))

      assert :ets.info(Tables.frontier(), :size) == 1
      assert {:ok, :v} = Store.frontier_lookup(Tables.gen(), :other, 101, 101)
    end

    test "it evicts by oldest as_of once the frontier is over its cap" do
      configure(frontier_max_rows: 1, sweep_per_block: 100)
      gen = Tables.gen()

      assert :ok = Node.advance(100)
      assert :ok = Store.frontier_put(gen, :old, 98, [], :old)
      assert :ok = Store.frontier_put(gen, :middle, 99, [], :middle)
      assert :ok = Store.frontier_put(gen, :new, 100, [], :new)

      assert :ok = Node.advance(block(101))

      assert :ets.info(Tables.frontier(), :size) == 1
      assert {:ok, :new} = Store.frontier_lookup(gen, :new, 101, 101)
    end

    test "it collapses the marker table once it is over its cap" do
      configure(max_markers: 2, sweep_per_block: 100)

      assert :ok = Node.advance(100)

      assert :ok =
               Node.advance(
                 block(101, [
                   event("coin_spent", %{"spender" => "thor1a", "amount" => "1rune"}),
                   event("coin_spent", %{"spender" => "thor1b", "amount" => "1rune"}),
                   event("coin_spent", %{"spender" => "thor1c", "amount" => "1rune"})
                 ])
               )

      assert :ets.info(Tables.markers(), :size) == 0
      assert Markers.marker({:balance, "thor1a"}) == 0
    end

    test "a marker above the frontier's oldest as_of survives the collapse" do
      configure(max_markers: 1, sweep_per_block: 100)
      gen = Tables.gen()

      assert :ok = Node.advance(100)
      assert :ok = Store.frontier_put(gen, :key, 100, [], :v)

      assert :ok =
               Node.advance(
                 block(101, [event("coin_spent", %{"spender" => "thor1a", "amount" => "1rune"})])
               )

      assert Markers.marker({:balance, "thor1a"}) == 101
    end
  end

  describe "the marker floor" do
    test "a row filed below the floor is never served over a collapsed marker" do
      configure(max_markers: 1, sweep_per_block: 100)
      gen = Tables.gen()

      assert :ok = Node.advance(100)

      # The contract changes at 101 and the marker table collapses with it: the
      # frontier is empty, so the floor is the head.
      assert :ok =
               Node.advance(block(101, [event("wasm", %{"_contract_address" => "thor1pair"})]))

      assert Markers.marker({:contract, "thor1pair"}) == 0
      assert Tables.marker_floor() == 101

      # A read that left at head 100 files as of 100. A writer that read the
      # floor before the collapse gets as far as the insert, so the row is put
      # in behind `frontier_put/5`'s refusal.
      :ets.insert(Tables.frontier(), {{gen, :key}, 100, [{:contract, "thor1pair"}], :at_100})

      assert Store.frontier_lookup(gen, :key, 101, 101) == :miss

      assert {:ok, :at_101} =
               Cache.fetch(:key, [{:contract, "thor1pair"}], [], fn 101 -> {:ok, :at_101} end)
    end

    test "a row below the floor is refused rather than stored" do
      configure(max_markers: 1, sweep_per_block: 100)
      gen = Tables.gen()

      assert :ok = Node.advance(100)

      assert :ok =
               Node.advance(block(101, [event("wasm", %{"_contract_address" => "thor1pair"})]))

      assert :ok = Store.frontier_put(gen, :key, 100, [{:contract, "thor1pair"}], :at_100)

      assert :ets.lookup(Tables.frontier(), {gen, :key}) == []
    end

    test "a row at or above the floor is untouched by the collapse" do
      configure(max_markers: 1, sweep_per_block: 100)
      gen = Tables.gen()

      assert :ok = Node.advance(100)

      assert :ok =
               Node.advance(block(101, [event("wasm", %{"_contract_address" => "thor1pair"})]))

      assert :ok = Store.frontier_put(gen, :key, 101, [{:contract, "thor1pair"}], :at_101)

      assert {:ok, :at_101} = Store.frontier_lookup(gen, :key, 101, 101)
    end

    test "a floor that would not move is not collapsed again" do
      configure(max_markers: 1, sweep_per_block: 100)

      assert :ok = Node.advance(100)

      assert :ok =
               Node.advance(
                 block(101, [event("coin_spent", %{"spender" => "thor1a", "amount" => "1rune"})])
               )

      assert Tables.marker_floor() == 101

      # A row as of 101 holds the frontier's oldest `as_of` there, so the next
      # block's collapse would not raise the floor - and a collapse that frees
      # nothing is skipped, leaving the markers above it where they are.
      assert :ok = Store.frontier_put(Tables.gen(), :key, 101, [], :v)

      assert :ok =
               Node.advance(
                 block(102, [event("coin_spent", %{"spender" => "thor1b", "amount" => "1rune"})])
               )

      assert Tables.marker_floor() == 101
      assert Markers.marker({:balance, "thor1b"}) == 102
    end
  end

  # --- Fixtures ---

  defp configure(opts) do
    original = Application.get_env(:rujira_ex, Cache)
    Application.put_env(:rujira_ex, Cache, opts)

    on_exit(fn ->
      case original do
        nil -> Application.delete_env(:rujira_ex, Cache)
        config -> Application.put_env(:rujira_ex, Cache, config)
      end
    end)
  end

  defp block(height, events \\ []) do
    {:ok, block} =
      Block.new(%QueryBlockResponse{
        header: %BlockResponseHeader{height: height, chain_id: "thorchain-1", time: ""},
        begin_block_events: events,
        end_block_events: [],
        finalize_block_events: [],
        txs: []
      })

    block
  end

  defp event(type, attrs) do
    pairs = Enum.map(attrs, fn {key, value} -> %EventKeyValuePair{key: key, value: value} end)
    %BlockEvent{event_kv_pair: [%EventKeyValuePair{key: "type", value: type} | pairs]}
  end
end
