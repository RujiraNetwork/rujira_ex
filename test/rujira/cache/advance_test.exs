defmodule Rujira.Cache.AdvanceTest do
  @moduledoc """
  `Rujira.Node.advance/1`: the head, the gap fill, and the two resets.

  The cache's tables are global, so this case runs sync and every test uses a
  height range of its own - blocks are cached per height in Rujira.Cache's exact store, and advance fetches them uncached.
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

    test "advance does not store the blocks it fetches" do
      count_blocks()

      assert :ok = Node.advance(1700)
      assert :ok = Node.advance(1701)

      assert exact_row_count({Block, :get, [1701]}) == 0
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
    test "a losing caller returns only once the head has reached its own height" do
      stall(2701)

      assert :ok = Node.advance(2700)

      holder = Task.async(fn -> Node.advance(2701) end)
      assert_receive {:fetching, 2701, fetch}, 5_000

      # The lock is provably held: this caller can only raise the target.
      loser = Task.async(fn -> Node.advance(2703) end)
      await_target(2703)

      # It has raised the target, so it lost the race - and it is still waiting.
      assert Task.yield(loser, 100) == nil
      assert Cache.head() == 2700

      send(fetch, :release)

      assert :ok = Task.await(holder)
      assert :ok = Task.await(loser)
      assert Cache.head() == 2703
    end

    test "a losing caller times out when the head never reaches its height" do
      configure(lock_timeout: 200)
      holder = hold_lock()

      # The lock never goes stale, so this caller can never take it over.
      assert {:error, :timeout} = Node.advance(2750)

      assert Cache.head() == nil
      assert Tables.target() == 2750
      assert [{:lock, ^holder, _at}] = :ets.lookup(Tables.lock(), :lock)
    end

    test "a losing caller takes over when the holder crashes" do
      configure(lock_timeout: 60_000)
      count_blocks()

      assert :ok = Node.advance(2760)

      holder = idle()
      :ets.insert(Tables.lock(), {:lock, holder, System.monotonic_time(:millisecond)})

      loser = Task.async(fn -> Node.advance(2761) end)
      assert Task.yield(loser, 100) == nil
      assert Cache.head() == 2760

      # Far inside lock_timeout: only the monitor can get this caller moving.
      Process.exit(holder, :kill)

      assert :ok = Task.await(loser)
      assert Cache.head() == 2761
    end

    test "a target raised while the holder is finishing is not left behind" do
      stall(2801)

      assert :ok = Node.advance(2800)

      holder = Task.async(fn -> Node.advance(2801) end)
      assert_receive {:fetching, 2801, fetch}, 5_000

      # The holder is applying the last block of its own target, so it has to
      # re-read the target before it lets the lock go - in the fill loop, or in
      # the recheck after the release.
      raiser = Task.async(fn -> Node.advance(2802) end)
      await_target(2802)

      send(fetch, :release)

      assert :ok = Task.await(holder)
      assert :ok = Task.await(raiser)
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
      configure(lock_timeout: 150)
      holder = hold_lock()

      assert {:error, :timeout} = Node.advance(3000)
      assert Cache.head() == nil
      assert [{:lock, ^holder, _at}] = :ets.lookup(Tables.lock(), :lock)

      Process.exit(holder, :kill)
      :ets.delete(Tables.lock(), :lock)

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

      assert pushed_count() == 0
    end

    test "blocks pushed at different heights do not overwrite each other" do
      configure(lock_timeout: 60_000)
      counter = count_blocks()

      assert :ok = Node.advance(3300)

      # Both are pushed before either can be applied: the lock is held. Each
      # pusher now waits for its own height, so both run in a task.
      row = {:lock, idle(), System.monotonic_time(:millisecond)}
      :ets.insert(Tables.lock(), row)

      first = Task.async(fn -> Node.advance(block(3301)) end)
      second = Task.async(fn -> Node.advance(block(3302)) end)

      await_pushed(2)
      assert Cache.head() == 3300

      :ets.delete_object(Tables.lock(), row)

      assert :ok = Task.await(first)
      assert :ok = Task.await(second)

      assert Cache.head() == 3302
      assert :counters.get(counter, 1) == 0
      assert pushed_count() == 0
    end
  end

  describe "the prefetch window" do
    test "fetches run ahead of the head, bounded by catchup_concurrency, and slide" do
      configure(catchup_concurrency: 3)
      gate()

      assert :ok = Node.advance(4000)
      fill = Task.async(fn -> Node.advance(4008) end)

      # Three at once for the three coming heights, and no fourth until one of
      # them has been applied.
      window = collect_fetches(3)
      assert Enum.sort(Map.keys(window)) == [4001, 4002, 4003]
      refute_receive {:fetching, _height, _pid}, 100

      send(window[4001], :release)
      assert_receive {:fetching, 4004, next}, 5_000

      Enum.each([window[4002], window[4003], next], &send(&1, :release))
      assert :ok = drain(fill)
      assert Cache.head() == 4008
    end

    test "blocks are applied in order however their fetches complete" do
      configure(catchup_concurrency: 4)
      attach([:rujira, :cache, :reset])

      # The later the height, the sooner its fetch returns.
      MockNode.expect(fn %QueryBlockRequest{height: height} ->
        height = String.to_integer(height)
        Process.sleep((4105 - height) * 20)
        {:ok, response(height, [event("version", %{"version" => "3.10.0"})])}
      end)

      assert :ok = Node.advance(4100)
      assert :ok = Node.advance(4105)

      # Every block is an upgrade, and an upgrade reports the head it found:
      # the reported sequence is the order the blocks were applied in.
      applied =
        for _y <- 4101..4105 do
          assert_receive {:telemetry, %{from: from, to: to}, %{reason: :upgrade}}
          {from, to}
        end

      assert applied == [{4100, 4101}, {4101, 4102}, {4102, 4103}, {4103, 4104}, {4104, 4105}]
      assert Cache.head() == 4105
    end

    test "a failure in the window is counted once, and only for the height being applied" do
      configure(catchup_concurrency: 4, max_block_failures: 3)

      count_blocks(fn
        4202 -> {:error, @error}
        4203 -> {:error, @error}
        _height -> :ok
      end)

      assert :ok = Node.advance(4200)
      assert {:error, @error} = Node.advance(4205)

      # 4203 failed in flight too, and is not held against it: the count
      # belongs to the height being applied, and moves only when it does.
      assert Cache.head() == 4201
      assert :ets.lookup(Tables.meta(), :failures) == [{:failures, 4202, 1}]

      assert {:error, @error} = Node.advance(4205)
      assert :ets.lookup(Tables.meta(), :failures) == [{:failures, 4202, 2}]
    end

    test "a height already pushed is not fetched, even from inside the window" do
      configure(catchup_concurrency: 4, lock_timeout: 60_000)
      counter = count_blocks()

      assert :ok = Node.advance(4300)

      # The lock is held, so the deposit is provably in before the window that
      # would have fetched 4302 opens.
      row = {:lock, idle(), System.monotonic_time(:millisecond)}
      :ets.insert(Tables.lock(), row)

      pusher = Task.async(fn -> Node.advance(block(4302)) end)
      await_pushed(1)

      filler = Task.async(fn -> Node.advance(4304) end)
      await_target(4304)
      :ets.delete_object(Tables.lock(), row)

      assert :ok = Task.await(pusher, 10_000)
      assert :ok = Task.await(filler, 10_000)

      assert Cache.head() == 4304
      assert :counters.get(counter, 1) == 3
    end

    test "a block pushed after its own fetch started still wins" do
      configure(catchup_concurrency: 4)
      gate()

      assert :ok = Node.advance(4400)
      filler = Task.async(fn -> Node.advance(4403) end)

      window = collect_fetches(3)
      assert Enum.sort(Map.keys(window)) == [4401, 4402, 4403]

      # 4402 is already in flight when its block is deposited on top of it.
      pushed = block(4402, [event("wasm", %{"_contract_address" => "thor1pushed"})])
      pusher = Task.async(fn -> Node.advance(pushed) end)
      await_pushed(1)

      Enum.each(Map.values(window), &send(&1, :release))
      assert :ok = drain(filler)
      assert :ok = Task.await(pusher, 10_000)

      assert Cache.head() == 4403
      assert Markers.marker({:contract, "thor1pushed"}) == 4402
    end

    test "a target raised mid-fill catches up instead, and drops the window" do
      configure(max_catchup: 3, catchup_concurrency: 4)
      gen = Tables.gen()
      links = links()

      # Fetching 4501 is what raises the target, so the fill meets a gap it
      # will not fill block by block the next time round.
      MockNode.expect(fn %QueryBlockRequest{height: height} ->
        height = String.to_integer(height)
        if height == 4501, do: Tables.raise_target(4600)
        {:ok, response(height)}
      end)

      assert :ok = Node.advance(4500)
      assert :ok = Node.advance(4503)

      assert Cache.head() == 4600
      assert Tables.gen() == gen + 1
      assert leaks() == %{monitors: [], task_messages: []}
      assert links() == links
    end

    test "an applied fill leaves no task, monitor or reply behind" do
      configure(catchup_concurrency: 4)
      count_blocks()
      links = links()

      assert :ok = Node.advance(4700)
      assert :ok = Node.advance(4706)

      assert Cache.head() == 4706
      assert leaks() == %{monitors: [], task_messages: []}
      assert links() == links
    end

    test "a failed fill leaves no task, monitor or reply behind" do
      configure(catchup_concurrency: 4)
      links = links()

      count_blocks(fn
        4801 -> {:error, @error}
        _height -> :ok
      end)

      assert :ok = Node.advance(4800)
      assert {:error, @error} = Node.advance(4806)

      assert Cache.head() == 4800
      assert leaks() == %{monitors: [], task_messages: []}
      assert links() == links
    end

    test "an unusable catchup_concurrency fetches one at a time, and nothing behind the head" do
      for {concurrency, base} <- [{0, 5000}, {-3, 5010}, {"4", 5020}, {nil, 5030}, {1.5, 5040}] do
        Cache.reset!()
        configure(catchup_concurrency: concurrency)
        record_blocks()

        assert :ok = Node.advance(base)
        assert :ok = Node.advance(base + 3)

        assert Cache.head() == base + 3
        assert Enum.sort(fetched_heights()) == [base + 1, base + 2, base + 3]
        assert leaks() == %{monitors: [], task_messages: []}
      end
    end

    test "a prefetch that crashes is that height's failure, not the caller's" do
      configure(catchup_concurrency: 4, max_block_failures: 3)

      count_blocks(fn
        5103 -> raise "boom"
        _height -> :ok
      end)

      assert :ok = Node.advance(5100)

      # 5103 is fetched while 5101 is being applied, and crashing there does
      # not take the caller with it: it is 5103's fetch result, once 5103 is
      # the height being applied.
      assert {:error, {:fetch_crashed, :error, %RuntimeError{message: "boom"}}} =
               Node.advance(5106)

      assert Cache.head() == 5102
      assert :ets.lookup(Tables.meta(), :failures) == [{:failures, 5103, 1}]
      assert leaks() == %{monitors: [], task_messages: []}
    end

    test "a prefetch that crashes for a height never applied is never counted" do
      configure(catchup_concurrency: 4, max_block_failures: 3)

      count_blocks(fn
        5202 -> {:error, @error}
        5203 -> raise "boom"
        _height -> :ok
      end)

      assert :ok = Node.advance(5200)
      assert {:error, @error} = Node.advance(5205)

      # The fill stopped at 5202, so the crash of 5203 - in flight beside it -
      # is nobody's failure.
      assert Cache.head() == 5201
      assert :ets.lookup(Tables.meta(), :failures) == [{:failures, 5202, 1}]
      assert leaks() == %{monitors: [], task_messages: []}
    end

    test "a head moved past the window by another writer drops those fetches at once" do
      configure(catchup_concurrency: 4)
      gate()

      assert :ok = Node.advance(5300)
      filler = Task.async(fn -> Node.advance(5305) end)

      window = collect_fetches(4)
      assert Enum.sort(Map.keys(window)) == [5301, 5302, 5303, 5304]

      # A second writer takes the head past three of the four heights in
      # flight, while the first of them is still being fetched.
      Tables.raise_head(5303)
      send(window[5301], :release)

      # 5302 and 5303 are behind the next height to apply, and go as soon as
      # the fill knows what that is, rather than at the end of the fill.
      await_dead(window[5302])
      await_dead(window[5303])
      assert Process.alive?(window[5304])

      send(window[5304], :release)
      assert :ok = drain(filler)
      assert Cache.head() == 5305
    end

    test "a reset fill leaves no task, monitor or reply behind" do
      configure(catchup_concurrency: 4, max_block_failures: 1)
      links = links()

      count_blocks(fn
        4901 -> {:error, @error}
        _height -> :ok
      end)

      assert :ok = Node.advance(4900)
      capture_log(fn -> assert :ok = Node.advance(4906) end)

      assert Cache.head() == 4906
      assert leaks() == %{monitors: [], task_messages: []}
      assert links() == links
    end
  end

  describe "telemetry" do
    test "a fill reports the head it moved and the blocks it applied" do
      count_blocks()
      attach([:rujira, :cache, :advance])

      assert :ok = Node.advance(3600)
      assert_receive {:telemetry, %{from: 0, to: 3600, blocks: 0, duration: duration}, %{}}
      assert duration >= 0

      assert :ok = Node.advance(3603)
      assert_receive {:telemetry, %{from: 3600, to: 3603, blocks: 3}, %{}}
    end

    test "an upgrade, an invalidate_all and a catch-up each report their reason" do
      attach([:rujira, :cache, :reset])

      assert :ok = Node.advance(3700)
      assert :ok = Node.advance(block(3701, [event("version", %{"version" => "3.10.0"})]))
      assert_receive {:telemetry, %{from: 3700, to: 3701}, %{reason: :upgrade}}

      assert :ok = Cache.invalidate_all()
      assert_receive {:telemetry, %{from: 3701, to: 3701}, %{reason: :invalidate_all}}

      configure(max_catchup: 2)

      assert :ok = Node.advance(3710)
      assert_receive {:telemetry, %{from: 3701, to: 3710}, %{reason: :catchup}}
    end

    test "a block that keeps failing reports a stuck-block reset" do
      configure(max_block_failures: 1)
      count_blocks(fn 3801 -> {:error, @error} end)
      attach([:rujira, :cache, :reset])

      assert :ok = Node.advance(3800)
      capture_log(fn -> assert :ok = Node.advance(3801) end)

      assert_receive {:telemetry, %{from: 3800, to: 3801}, %{reason: :stuck_block}}
    end
  end

  # --- Fixtures ---

  @doc false
  def forward(_event, measurements, metadata, test),
    do: send(test, {:telemetry, measurements, metadata})

  # Forwards one event to the test process. The handler is a module function,
  # not a closure: `:telemetry` logs about the performance of a local one every
  # time it is attached.
  defp attach(event) do
    handler = {__MODULE__, event, System.unique_integer()}

    :telemetry.attach(handler, event, &__MODULE__.forward/4, self())
    on_exit(fn -> :telemetry.detach(handler) end)
    :ok
  end

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

  # A process that holds the lock and never goes stale, by construction rather
  # than by reacquiring it often enough: its timestamp is set far enough in
  # the future that no `lock_timeout` in these tests can ever make `at - held`
  # exceed it, however long the holder is descheduled for.
  defp hold_lock do
    pid = idle()
    :ets.insert(Tables.lock(), {:lock, pid, System.monotonic_time(:millisecond) + 3_600_000})
    pid
  end

  defp await_target(target), do: eventually(&Tables.target/0, target)

  defp await_pushed(count), do: eventually(&pushed_count/0, count)

  defp pushed_count,
    do: :ets.select_count(Tables.meta(), [{{{:pushed, :_}, :_}, [], [true]}])

  # Polls `read` until it gives `expected`. Tables.target/0 and the pushed
  # blocks are written by another process before it races for the lock, so
  # there is nothing to receive - only a value to watch.
  defp eventually(read, expected, attempts \\ 200)

  defp eventually(read, expected, 0),
    do: flunk("expected #{inspect(expected)}, got #{inspect(read.())}")

  defp eventually(read, expected, attempts) do
    case read.() do
      ^expected ->
        :ok

      _other ->
        Process.sleep(5)
        eventually(read, expected, attempts - 1)
    end
  end

  # Scripts every fetch to announce itself and wait, so the shape of the
  # prefetch window is observed rather than timed.
  defp gate do
    test = self()

    MockNode.expect(fn %QueryBlockRequest{height: height} ->
      height = String.to_integer(height)
      send(test, {:fetching, height, self()})

      receive do
        :release -> {:ok, response(height)}
      end
    end)
  end

  # Records every height fetched, wherever the fetch ran.
  defp record_blocks do
    test = self()

    MockNode.expect(fn %QueryBlockRequest{height: height} ->
      height = String.to_integer(height)
      send(test, {:fetched, height})
      {:ok, response(height)}
    end)
  end

  defp fetched_heights do
    receive do
      {:fetched, height} -> [height | fetched_heights()]
    after
      0 -> []
    end
  end

  defp await_dead(pid), do: eventually(fn -> Process.alive?(pid) end, false)

  defp collect_fetches(count), do: Map.new(1..count, fn _ -> receive_fetch() end)

  defp receive_fetch do
    receive do
      {:fetching, height, pid} -> {height, pid}
    after
      5_000 -> flunk("no fetch was announced")
    end
  end

  # Releases every gated fetch as it announces itself, until the fill returns.
  defp drain(task, attempts \\ 500)

  defp drain(_task, 0), do: flunk("the fill never finished")

  defp drain(task, attempts) do
    receive do
      {:fetching, _height, pid} ->
        send(pid, :release)
        drain(task, attempts)
    after
      0 -> yield_or_drain(task, attempts)
    end
  end

  defp yield_or_drain(task, attempts) do
    case Task.yield(task, 20) do
      {:ok, result} -> result
      _pending -> drain(task, attempts - 1)
    end
  end

  # The fill runs in this process, so whatever it started has to be gone by
  # the time it returns: no monitor, and no task reply or `:DOWN` waiting.
  defp leaks, do: %{monitors: monitors(), task_messages: task_messages()}

  defp monitors do
    {:monitors, monitors} = Process.info(self(), :monitors)
    monitors
  end

  defp links do
    {:links, links} = Process.info(self(), :links)
    links
  end

  defp task_messages do
    receive do
      {ref, _reply} when is_reference(ref) -> [:reply | task_messages()]
      {:DOWN, ref, :process, _pid, _reason} when is_reference(ref) -> [:down | task_messages()]
      _other -> task_messages()
    after
      0 -> []
    end
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

  defp exact_row_count(query_key) do
    :ets.select_count(Tables.exact(), [
      {{{:_, :_, query_key}, :_}, [], [true]}
    ])
  end

  defp event(type, attrs \\ %{}) do
    pairs = Enum.map(attrs, fn {key, value} -> %EventKeyValuePair{key: key, value: value} end)
    %BlockEvent{event_kv_pair: [%EventKeyValuePair{key: "type", value: type} | pairs]}
  end
end
