defmodule Rujira.Cache.AdvanceTest do
  @moduledoc """
  `Rujira.Node.advance/1`: the head, the gap fill, and the two resets.

  The cache's tables are global, so this case runs sync and every test uses a
  height range of its own - the block cache is memoized per height.
  """
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Rujira.Cache
  alias Rujira.Cache.Markers
  alias Rujira.Cache.Tables
  alias Rujira.Node
  alias Rujira.Test.MockNode
  alias Rujira.Thorchain.Block
  alias Thorchain.Types.BlockEvent
  alias Thorchain.Types.BlockResponseHeader
  alias Thorchain.Types.EventKeyValuePair
  alias Thorchain.Types.QueryBlockRequest
  alias Thorchain.Types.QueryBlockResponse

  @error %GRPC.RPCError{status: 2, message: "boom"}

  setup do
    Cache.reset!()
    on_exit(&Rujira.Test.CacheCase.reset!/0)
    :ok
  end

  describe "the head" do
    test "the first advance sets the head and fetches nothing" do
      counter = count_blocks()

      assert :ok = Node.advance(1000)
      assert Cache.head() == 1000
      assert :counters.get(counter, 1) == 0
    end

    test "a height at or below the head is a no-op" do
      assert :ok = Node.advance(1100)
      assert :ok = Node.advance(1100)
      assert :ok = Node.advance(1)
      assert Cache.head() == 1100
    end

    test "an unusable height never touches the head" do
      assert :ok = Node.advance(1200)

      for height <- [0, -1, 9_223_372_036_854_775_808, "1201", nil] do
        assert {:error, :invalid_height} = Node.advance(height)
      end

      assert Cache.head() == 1200
    end
  end

  describe "gap filling" do
    test "the blocks between the head and the target are fetched in order" do
      counter = count_blocks()

      assert :ok = Node.advance(1300)
      assert :ok = Node.advance(1303)

      assert Cache.head() == 1303
      assert :counters.get(counter, 1) == 3
    end

    test "a pushed block is used for its own height, and not refetched" do
      counter = count_blocks()

      assert :ok = Node.advance(1400)
      assert :ok = Node.advance(block(1401))

      assert Cache.head() == 1401
      assert :counters.get(counter, 1) == 0
    end

    test "a pushed block ahead of the head is used once the gap is filled" do
      counter = count_blocks()

      assert :ok = Node.advance(1500)
      assert :ok = Node.advance(block(1502))

      assert Cache.head() == 1502
      assert :counters.get(counter, 1) == 1
    end

    test "a failed fetch is returned, leaves the head alone, and is retried" do
      counter = count_blocks(fn 1601 -> {:error, @error} end)

      assert :ok = Node.advance(1600)
      assert {:error, @error} = Node.advance(1601)
      assert Cache.head() == 1600
      assert {:error, @error} = Node.advance(1601)
      assert :counters.get(counter, 1) == 2
    end
  end

  describe "invalidation" do
    test "every source of the applied block is marked at its height" do
      assert :ok = Node.advance(1700)

      assert :ok =
               Node.advance(
                 block(1701, [
                   event("wasm", %{"_contract_address" => "thor1pair"}),
                   event("coin_spent", %{"spender" => "thor1a", "amount" => "100rune"}),
                   event("store_code")
                 ])
               )

      assert Markers.marker({:contract, "thor1pair"}) == 1701
      assert Markers.marker({:balance, "thor1a"}) == 1701
      assert Markers.marker({:denom_transfers, "rune"}) == 1701
      assert Markers.marker(:contract_registry) == 1701
      assert Markers.marker(:per_block) == 1701
    end

    test "a marker is raised, never lowered" do
      assert :ok = Node.advance(1800)
      assert :ok = Node.advance(block(1801, [event("store_code")]))
      assert :ok = Node.advance(block(1802))

      assert Markers.marker(:contract_registry) == 1801
    end

    test "an upgrade block marks everything" do
      assert :ok = Node.advance(1900)
      assert :ok = Node.advance(block(1901, [event("version", %{"version" => "3.10.0"})]))

      assert Tables.all_marker() == 1901
    end
  end

  describe "resets" do
    test "a target further than max_catchup away resets instead of filling" do
      configure(max_catchup: 2)
      counter = count_blocks()
      gen = Tables.gen()

      assert :ok = Node.advance(2000)
      assert :ok = Node.advance(2010)

      assert Cache.head() == 2010
      assert Tables.all_marker() == 2010
      assert Tables.gen() == gen + 1
      assert :counters.get(counter, 1) == 0
    end

    test "a block that keeps failing resets rather than holding the head" do
      configure(max_block_failures: 2)
      count_blocks(fn 2101 -> {:error, @error} end)

      assert :ok = Node.advance(2100)
      assert {:error, @error} = Node.advance(2101)
      assert Cache.head() == 2100

      log = capture_log(fn -> assert :ok = Node.advance(2101) end)

      assert Cache.head() == 2101
      assert Tables.all_marker() == 2101
      assert log =~ "block 2101 failed 2 times"
    end

    test "a success clears the failure count, so one failure does not linger" do
      configure(max_block_failures: 2)
      attempts = :counters.new(1, [])
      gen = Tables.gen()

      count_blocks(fn 2201 ->
        case :counters.get(attempts, 1) do
          0 ->
            :counters.add(attempts, 1, 1)
            {:error, @error}

          _ ->
            :ok
        end
      end)

      assert :ok = Node.advance(2200)
      assert {:error, @error} = Node.advance(2201)
      assert Cache.head() == 2200
      assert :ok = Node.advance(2201)

      assert Cache.head() == 2201
      assert Tables.gen() == gen
    end

    test "invalidate_all bumps the generation without moving the head" do
      gen = Tables.gen()

      assert :ok = Node.advance(2400)
      assert :ok = Cache.invalidate_all()

      assert Tables.gen() == gen + 1
      assert Cache.head() == 2400
    end
  end

  describe "the lock" do
    test "a losing caller returns :ok and the head still reaches its target" do
      stall(2701)

      assert :ok = Node.advance(2700)

      holder = Task.async(fn -> Node.advance(2701) end)
      assert_receive {:fetching, 2701, fetch}, 5_000

      # The lock is provably held: this caller can only raise the target.
      loser = Task.async(fn -> Node.advance(2703) end)

      assert :ok = Task.await(loser)
      assert Cache.head() == 2700

      send(fetch, :release)

      assert :ok = Task.await(holder)
      assert Cache.head() == 2703
    end

    test "a target raised while the holder is finishing is not left behind" do
      stall(2801)

      assert :ok = Node.advance(2800)

      holder = Task.async(fn -> Node.advance(2801) end)
      assert_receive {:fetching, 2801, fetch}, 5_000

      # The holder is applying the last block of its own target, so it has to
      # re-read the target before it lets the lock go - in the fill loop, or in
      # the recheck after the release.
      assert :ok = Task.await(Task.async(fn -> Node.advance(2802) end))

      send(fetch, :release)

      assert :ok = Task.await(holder)
      assert Cache.head() == 2802
    end

    test "a lock older than lock_timeout is taken over" do
      configure(lock_timeout: 10)
      holder = idle()

      :ets.insert(Tables.lock(), {:lock, holder, System.monotonic_time(:millisecond) - 1_000})

      assert :ok = Node.advance(2900)

      assert Cache.head() == 2900
      assert :ets.lookup(Tables.lock(), :lock) == []
    end

    test "a lock that is neither stale nor dead is left where it is" do
      configure(lock_timeout: 60_000)
      row = {:lock, idle(), System.monotonic_time(:millisecond)}
      :ets.insert(Tables.lock(), row)

      assert :ok = Node.advance(3000)
      assert Cache.head() == nil
      assert Tables.target() == 3000

      :ets.delete_object(Tables.lock(), row)

      assert :ok = Node.advance(3000)
      assert Cache.head() == 3000
    end

    test "concurrent callers converge on the highest target" do
      count_blocks()

      assert :ok = Node.advance(3100)

      results =
        3101..3110
        |> Enum.map(fn height -> Task.async(fn -> Node.advance(height) end) end)
        |> Enum.map(&Task.await(&1, 10_000))

      assert Enum.all?(results, &(&1 == :ok))
      assert Cache.head() == 3110
    end
  end

  describe "pushed blocks" do
    test "a block pushed at or below the head is discarded, not left behind" do
      assert :ok = Node.advance(3200)
      assert :ok = Node.advance(block(3200))
      assert :ok = Node.advance(block(3199))

      assert :ets.select_count(Tables.meta(), [{{{:pushed, :_}, :_}, [], [true]}]) == 0
    end

    test "blocks pushed at different heights do not overwrite each other" do
      configure(lock_timeout: 60_000)
      counter = count_blocks()

      assert :ok = Node.advance(3300)

      # Both are pushed before either can be applied: the lock is held.
      row = {:lock, idle(), System.monotonic_time(:millisecond)}
      :ets.insert(Tables.lock(), row)

      assert :ok = Node.advance(block(3301))
      assert :ok = Node.advance(block(3302))
      assert Cache.head() == 3300

      :ets.delete_object(Tables.lock(), row)

      assert :ok = Node.advance(3302)

      assert Cache.head() == 3302
      assert :counters.get(counter, 1) == 0
      assert :ets.select_count(Tables.meta(), [{{{:pushed, :_}, :_}, [], [true]}]) == 0
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

  # Block fetches happen inside a task, so they are counted rather than
  # asserted on the test process's mailbox.
  defp count_blocks(script \\ fn _height -> :ok end) do
    counter = :counters.new(1, [])

    MockNode.expect(fn %QueryBlockRequest{height: height} ->
      :counters.add(counter, 1, 1)
      height = String.to_integer(height)

      case script.(height) do
        {:error, _} = error -> error
        _ -> {:ok, response(height)}
      end
    end)

    counter
  end

  # A process that stays alive, and takes no part in anything.
  defp idle do
    pid = spawn(fn -> Process.sleep(:infinity) end)
    on_exit(fn -> Process.exit(pid, :kill) end)
    pid
  end

  # Scripts the fetch of one height to block until the test releases it, so the
  # lock is provably held while another caller runs.
  defp stall(height) do
    test = self()

    MockNode.expect(fn %QueryBlockRequest{height: fetched} ->
      fetched = String.to_integer(fetched)

      if fetched == height do
        send(test, {:fetching, fetched, self()})

        receive do
          :release -> :ok
        end
      end

      {:ok, response(fetched)}
    end)
  end

  defp block(height, events \\ []) do
    {:ok, block} = Block.new(response(height, events))
    block
  end

  defp response(height, events \\ []) do
    %QueryBlockResponse{
      header: %BlockResponseHeader{height: height, chain_id: "thorchain-1", time: ""},
      begin_block_events: events,
      end_block_events: [],
      finalize_block_events: [],
      txs: []
    }
  end

  defp event(type, attrs \\ %{}) do
    pairs = Enum.map(attrs, fn {key, value} -> %EventKeyValuePair{key: key, value: value} end)
    %BlockEvent{event_kv_pair: [%EventKeyValuePair{key: "type", value: type} | pairs]}
  end
end
