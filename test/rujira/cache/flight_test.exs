defmodule Rujira.Cache.FlightTest do
  @moduledoc """
  Single-flight: one fetch per key and height, one shared error, and nothing
  left in anyone's mailbox.

  The tables are global, so this case runs sync.
  """
  use ExUnit.Case, async: false

  alias Rujira.Cache
  alias Rujira.Cache.Tables

  @contract [{:contract, "thor1pair"}]
  @sync_timeout 2_000

  setup do
    Cache.reset!()
    :ok
  end

  test "concurrent readers of the same key at the same height share one fetch" do
    counter = :counters.new(1, [])
    test = self()

    fun = fn _height ->
      :counters.add(counter, 1, 1)
      send(test, :reading)

      receive do
        :release -> {:ok, :v}
      end
    end

    runner = Task.async(fn -> Cache.fetch(:key, @contract, [height: 10], fun) end)
    assert_receive :reading

    waiter = Task.async(fn -> Cache.fetch(:key, @contract, [height: 10], fun) end)
    await_waiters(1)

    send(runner.pid, :release)

    assert {:ok, :v} = Task.await(runner)
    assert {:ok, :v} = Task.await(waiter)
    assert :counters.get(counter, 1) == 1
  end

  test "a reader at another height never joins a flight at this one" do
    counter = :counters.new(1, [])
    test = self()

    fun = fn height ->
      :counters.add(counter, 1, 1)
      send(test, {:reading, height})

      receive do
        :release -> {:ok, height}
      end
    end

    runner = Task.async(fn -> Cache.fetch(:key, @contract, [height: 10], fun) end)
    assert_receive {:reading, 10}

    other = Task.async(fn -> Cache.fetch(:key, @contract, [height: 11], fun) end)
    assert_receive {:reading, 11}

    send(runner.pid, :release)
    send(other.pid, :release)

    assert {:ok, 10} = Task.await(runner)
    assert {:ok, 11} = Task.await(other)
    assert :counters.get(counter, 1) == 2
  end

  test "an error reaches every waiter, and is stored nowhere" do
    counter = :counters.new(1, [])
    test = self()

    fun = fn _height ->
      :counters.add(counter, 1, 1)
      send(test, :reading)

      receive do
        :release -> {:error, :boom}
      end
    end

    runner = Task.async(fn -> Cache.fetch(:key, @contract, [height: 10], fun) end)
    assert_receive :reading

    waiters =
      Enum.map(1..3, fn _ ->
        Task.async(fn -> Cache.fetch(:key, @contract, [height: 10], fun) end)
      end)

    await_waiters(3)
    send(runner.pid, :release)

    assert {:error, :boom} = Task.await(runner)
    assert Enum.all?(waiters, &(Task.await(&1) == {:error, :boom}))

    # One fetch for four callers, and nothing kept: the next caller fetches.
    assert :counters.get(counter, 1) == 1
    assert Cache.fetch(:key, @contract, [height: 10], fn _h -> {:ok, :v} end) == {:ok, :v}
  end

  test "a waiter takes over when the runner is killed" do
    counter = :counters.new(1, [])
    test = self()

    fun = fn _height ->
      case :counters.get(counter, 1) do
        0 ->
          :counters.add(counter, 1, 1)
          send(test, :reading)
          Process.sleep(:infinity)

        _ ->
          {:ok, :second}
      end
    end

    # Unlinked: the kill must not reach the test process.
    runner = spawn(fn -> Cache.fetch(:key, @contract, [height: 10], fun) end)
    assert_receive :reading

    Process.exit(runner, :kill)

    assert {:ok, :second} = Cache.fetch(:key, @contract, [height: 10], fun)
  end

  test "a waiter leaves nothing in its own mailbox" do
    test = self()

    fun = fn _height ->
      send(test, :reading)

      receive do
        :release -> {:ok, :v}
      end
    end

    runner = Task.async(fn -> Cache.fetch(:key, @contract, [height: 10], fun) end)
    assert_receive :reading

    waiter =
      Task.async(fn ->
        result = Cache.fetch(:key, @contract, [height: 10], fun)
        {result, Process.info(self(), :messages)}
      end)

    await_waiters(1)
    send(runner.pid, :release)

    assert {:ok, :v} = Task.await(runner)
    assert {{:ok, :v}, {:messages, []}} = Task.await(waiter)
  end

  test "a waiter that gives up leaves nothing behind either" do
    test = self()

    fun = fn _height ->
      send(test, :reading)

      receive do
        :release -> {:ok, :v}
      end
    end

    runner = Task.async(fn -> Cache.fetch(:key, @contract, [height: 10], fun) end)
    assert_receive :reading

    assert {:error, :timeout} =
             Cache.fetch(:key, @contract, [height: 10, timeout: 60], fn _h -> {:ok, :never} end)

    send(runner.pid, :release)
    assert {:ok, :v} = Task.await(runner)

    assert {:messages, messages} = Process.info(self(), :messages)
    assert Enum.reject(messages, &match?(:reading, &1)) == []
  end

  @tag :capture_log
  test "a runner that raises frees the key and tells its waiters" do
    test = self()

    fun = fn _height ->
      send(test, :reading)

      receive do
        :release -> raise "boom"
      end
    end

    runner = spawn(fn -> Cache.fetch(:key, @contract, [height: 10], fun) end)
    assert_receive :reading

    waiter = Task.async(fn -> Cache.fetch(:key, @contract, [height: 10], fun) end)
    await_waiters(1)

    send(runner, :release)

    assert {:error, :flight_crashed} = Task.await(waiter)
    assert :ets.lookup(Tables.flight(), {Tables.gen(), :key, 10}) == []
  end

  # --- Fixtures ---

  # Waiting on an ETS row rather than on a sleep: the test fails on the bound
  # rather than racing past it.
  defp await_waiters(count, deadline \\ nil)

  defp await_waiters(count, nil) do
    await_waiters(count, System.monotonic_time(:millisecond) + @sync_timeout)
  end

  defp await_waiters(count, deadline) do
    case :ets.info(Tables.waiters(), :size) do
      ^count ->
        :ok

      size ->
        assert System.monotonic_time(:millisecond) < deadline,
               "expected #{count} waiters, found #{size}"

        receive do
        after
          1 -> await_waiters(count, deadline)
        end
    end
  end
end
