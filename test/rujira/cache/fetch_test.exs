defmodule Rujira.Cache.FetchTest do
  @moduledoc """
  The read path: which store serves a read, when a value carries over, and
  when it stops being valid.

  The tables are global, so this case runs sync.
  """
  use ExUnit.Case, async: false

  alias Rujira.Cache
  alias Rujira.Cache.Store
  alias Rujira.Cache.Tables
  alias Rujira.Node
  alias Rujira.Thorchain.Block
  alias Thorchain.Types.BlockEvent
  alias Thorchain.Types.BlockResponseHeader
  alias Thorchain.Types.EventKeyValuePair
  alias Thorchain.Types.QueryBlockResponse

  @contract [{:contract, "thor1pair"}]

  setup do
    Cache.reset!()
    on_exit(&Rujira.Test.CacheCase.reset!/0)
    :ok
  end

  describe "scope/1" do
    test "a heightless read before the first advance has no height to read at" do
      assert Cache.scope([]) == {:error, :no_head}
      assert Cache.head() == nil

      assert {:error, :no_head} =
               Cache.fetch(:key, @contract, [], fn _height -> {:ok, :never} end)
    end

    test "a heightless read is at the head, and a pinned one at its own height" do
      assert :ok = Node.advance(100)

      assert Cache.scope([]) == {:ok, 100}
      assert Cache.scope(height: 42) == {:ok, 42}
      assert Cache.scope(height: nil) == {:ok, 100}
      assert Cache.scope(height: "42") == {:error, :invalid_height}
    end

    test "the resolved height is what the fetch is performed at" do
      assert :ok = Node.advance(100)
      assert {:ok, 100} = Cache.fetch(:key, @contract, [], fn height -> {:ok, height} end)
      assert {:ok, 42} = Cache.fetch(:other, @contract, [height: 42], fn h -> {:ok, h} end)
    end
  end

  describe "pin/1" do
    test "it puts the resolved height back into opts, and is a no-op on pinned opts" do
      assert :ok = Node.advance(100)

      assert {:ok, opts} = Cache.pin(fan_out: [timeout: 10])
      assert Keyword.get(opts, :height) == 100
      assert Keyword.get(opts, :fan_out) == [timeout: 10]

      assert Cache.pin(opts) == {:ok, opts}
      assert Cache.pin(height: 42) == {:ok, [height: 42]}
    end

    test "it fails exactly where scope/1 does" do
      assert Cache.pin([]) == {:error, :no_head}
      assert Cache.pin(height: "42") == {:error, :invalid_height}
    end
  end

  describe "the frontier" do
    test "a value read at the head is served again without a fetch" do
      assert :ok = Node.advance(100)

      counter = :counters.new(1, [])

      assert {:ok, :v} = fetch(:key, @contract, [], counter)
      assert {:ok, :v} = fetch(:key, @contract, [], counter)
      assert :counters.get(counter, 1) == 1
    end

    test "a value carries over to later blocks while its sources are untouched" do
      counter = :counters.new(1, [])

      assert :ok = Node.advance(100)
      assert {:ok, :v} = fetch(:key, @contract, [], counter)

      assert :ok = Node.advance(block(101))
      assert :ok = Node.advance(block(102, [event("coin_spent", %{"spender" => "thor1a"})]))

      assert {:ok, :v} = fetch(:key, @contract, [], counter)
      assert :counters.get(counter, 1) == 1
    end

    test "a value stops being served once one of its sources changes" do
      counter = :counters.new(1, [])

      assert :ok = Node.advance(100)
      assert {:ok, :v} = fetch(:key, @contract, [], counter)

      assert :ok =
               Node.advance(block(101, [event("wasm", %{"_contract_address" => "thor1pair"})]))

      assert {:ok, :v} = fetch(:key, @contract, [], counter)
      assert :counters.get(counter, 1) == 2
    end

    test "an upgrade block invalidates a row whose own sources never changed" do
      counter = :counters.new(1, [])

      assert :ok = Node.advance(100)
      assert {:ok, :v} = fetch(:key, @contract, [], counter)

      assert :ok = Node.advance(block(101, [event("version", %{"version" => "3.10.0"})]))

      assert {:ok, :v} = fetch(:key, @contract, [], counter)
      assert :counters.get(counter, 1) == 2
    end

    test "a row is never valid below its own as_of - that read goes to the exact store" do
      counter = :counters.new(1, [])

      assert :ok = Node.advance(100)
      assert {:ok, :v} = fetch(:key, @contract, [], counter)
      assert {:ok, :v} = fetch(:key, @contract, [height: 99], counter)

      assert :counters.get(counter, 1) == 2
      assert {:ok, :v} = Store.exact_lookup(Tables.gen(), :key, 99)
      assert Store.exact_lookup(Tables.gen(), :key, 100) == :miss
    end

    test "a row is never valid above the head" do
      counter = :counters.new(1, [])

      assert :ok = Node.advance(100)
      assert {:ok, :v} = fetch(:key, @contract, [], counter)
      assert {:ok, :v} = fetch(:key, @contract, [height: 101], counter)

      assert :counters.get(counter, 1) == 2
      assert {:ok, :v} = Store.exact_lookup(Tables.gen(), :key, 101)
    end

    test "a stored row is only replaced by a newer one" do
      assert :ok = Node.advance(100)

      assert :ok = Store.frontier_put(Tables.gen(), :key, 100, [], :new)
      assert :ok = Store.frontier_put(Tables.gen(), :key, 99, [], :old)

      assert {:ok, :new} = Store.frontier_lookup(Tables.gen(), :key, 100, 100)
    end
  end

  describe ":per_block" do
    test "a per-block read is served at its own height only" do
      counter = :counters.new(1, [])

      assert :ok = Node.advance(100)
      assert {:ok, :v} = fetch(:key, [:per_block], [], counter)
      assert {:ok, :v} = fetch(:key, [:per_block], [], counter)
      assert :counters.get(counter, 1) == 1

      assert :ok = Node.advance(block(101))

      assert {:ok, :v} = fetch(:key, [:per_block], [], counter)
      assert :counters.get(counter, 1) == 2
    end

    test "a per-block read never touches the frontier" do
      assert :ok = Node.advance(100)
      assert {:ok, :v} = fetch(:key, [:per_block], [], :counters.new(1, []))

      assert Store.frontier_lookup(Tables.gen(), :key, 100, 100) == :miss
      assert {:ok, :v} = Store.exact_lookup(Tables.gen(), :key, 100)
    end
  end

  describe "identity" do
    test "an identity read has no height and survives the head moving" do
      counter = :counters.new(1, [])

      assert {:ok, nil} = Cache.fetch(:key, :identity, [], &fetcher(&1, counter))
      assert :ok = Node.advance(100)
      assert :ok = Node.advance(block(101, [event("version", %{"version" => "3.10.0"})]))
      assert {:ok, nil} = Cache.fetch(:key, :identity, [], &fetcher(&1, counter))

      assert :counters.get(counter, 1) == 1
    end
  end

  describe "sources as a function of the value" do
    test "a list's members are read off the result" do
      sources = fn value -> Enum.map(value, &{:contract, &1}) end

      assert :ok = Node.advance(100)

      assert {:ok, _} =
               Cache.fetch(:list, sources, [], fn _h -> {:ok, ["thor1a", "thor1b"]} end)

      assert {:ok, [_, _]} = Store.frontier_lookup(Tables.gen(), :list, 100, 100)

      assert :ok = Node.advance(block(101, [event("wasm", %{"_contract_address" => "thor1b"})]))
      assert Store.frontier_lookup(Tables.gen(), :list, 101, 101) == :miss
    end
  end

  describe "errors" do
    test "an error is returned and never stored" do
      counter = :counters.new(1, [])

      assert :ok = Node.advance(100)

      failing = fn _height ->
        :counters.add(counter, 1, 1)
        {:error, :boom}
      end

      assert {:error, :boom} = Cache.fetch(:key, @contract, [], failing)
      assert {:error, :boom} = Cache.fetch(:key, @contract, [], failing)
      assert :counters.get(counter, 1) == 2
    end
  end

  describe "generations" do
    test "invalidate_all makes every stored row unreachable" do
      counter = :counters.new(1, [])

      assert :ok = Node.advance(100)
      assert {:ok, :v} = fetch(:frontier_key, @contract, [], counter)
      assert {:ok, :v} = fetch(:exact_key, @contract, [height: 90], counter)
      assert {:ok, nil} = Cache.fetch(:identity_key, :identity, [], &fetcher(&1, counter))
      assert :counters.get(counter, 1) == 3

      assert :ok = Cache.invalidate_all()

      assert {:ok, :v} = fetch(:frontier_key, @contract, [], counter)
      assert {:ok, :v} = fetch(:exact_key, @contract, [height: 90], counter)
      assert {:ok, nil} = Cache.fetch(:identity_key, :identity, [], &fetcher(&1, counter))
      assert :counters.get(counter, 1) == 6
    end
  end

  describe "a fetch that finishes after the head has moved" do
    test "its value is filed at the height it was read at, and never served at the new head" do
      test = self()

      assert :ok = Node.advance(100)

      slow = fn height ->
        send(test, {:reading, height})

        receive do
          :release -> {:ok, :at_100}
        end
      end

      reader = Task.async(fn -> Cache.fetch(:key, @contract, [], slow) end)
      assert_receive {:reading, 100}

      # The head moves, and the contract changes with it, while the read is out.
      assert :ok =
               Node.advance(block(101, [event("wasm", %{"_contract_address" => "thor1pair"})]))

      send(reader.pid, :release)
      assert {:ok, :at_100} = Task.await(reader)

      # It is filed as of 100, the height it was read at - not as of the head.
      assert [{_key, 100, _sources, :at_100}] =
               :ets.lookup(Tables.frontier(), {Tables.gen(), :key})

      # A reader at 101 is never handed it: its source changed at 101.
      assert {:ok, :at_101} = Cache.fetch(:key, @contract, [], fn 101 -> {:ok, :at_101} end)
    end
  end

  describe "a composite read" do
    test "every item of a fan-out reads at the one pinned height, as the head moves" do
      assert :ok = Node.advance(100)
      assert {:ok, 100} = Cache.scope([])

      # What a composite read does: resolve the height once, put it back into
      # opts, and fan out. `max_concurrency: 1` sequences the items, so the
      # head provably moves between the first and the rest.
      opts = [height: 100, fan_out: [max_concurrency: 1]]

      read = fn key ->
        if key == :a, do: assert(:ok = Node.advance(block(101)))
        Cache.fetch({:item, key}, [:per_block], opts, fn height -> {:ok, height} end)
      end

      assert {:ok, [100, 100, 100]} =
               Rujira.Enum.reduce_async_while_ok([:a, :b, :c], read, opts)

      assert Cache.head() == 101

      # Nothing was filed at the new head: every item was read at 100.
      assert {:ok, 100} = Store.exact_lookup(Tables.gen(), {:item, :c}, 100)
      assert Store.exact_lookup(Tables.gen(), {:item, :c}, 101) == :miss
    end
  end

  # --- Fixtures ---

  defp fetch(key, sources, opts, counter) do
    Cache.fetch(key, sources, opts, fn _height ->
      :counters.add(counter, 1, 1)
      {:ok, :v}
    end)
  end

  defp fetcher(height, counter) do
    :counters.add(counter, 1, 1)
    {:ok, height}
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
