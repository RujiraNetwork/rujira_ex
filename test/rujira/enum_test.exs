defmodule Rujira.EnumTest do
  use ExUnit.Case, async: true

  describe "reduce_while_ok/3" do
    test "collects every ok value in order" do
      assert {:ok, [2, 4, 6]} =
               Rujira.Enum.reduce_while_ok([1, 2, 3], fn x -> {:ok, x * 2} end)
    end

    test "omits skipped elements but keeps the rest" do
      result =
        Rujira.Enum.reduce_while_ok([1, 2, 3, 4], fn
          x when rem(x, 2) == 0 -> :skip
          x -> {:ok, x}
        end)

      assert {:ok, [1, 3]} = result
    end

    test "halts on the first error and returns its reason" do
      assert {:error, :boom} =
               Rujira.Enum.reduce_while_ok([1, 2, 3], fn
                 2 -> {:error, :boom}
                 x -> {:ok, x}
               end)
    end

    test "stops calling the function after an error" do
      # Tracks how many elements were visited: the walk must halt at 2 rather
      # than running to the end of the list.
      {:ok, counter} = Agent.start_link(fn -> 0 end)

      Rujira.Enum.reduce_while_ok([1, 2, 3, 4, 5], fn x ->
        Agent.update(counter, &(&1 + 1))
        if x == 2, do: {:error, :halt_here}, else: {:ok, x}
      end)

      assert Agent.get(counter, & &1) == 2
    end

    test "accepts a seed accumulator, which precedes the collected values reversed" do
      assert {:ok, [:seed, 1]} =
               Rujira.Enum.reduce_while_ok([1], [:seed], fn x -> {:ok, x} end)
    end

    test "returns the empty list for an empty enumerable" do
      assert {:ok, []} = Rujira.Enum.reduce_while_ok([], fn x -> {:ok, x} end)
    end

    test "returns the empty list when everything is skipped" do
      assert {:ok, []} = Rujira.Enum.reduce_while_ok([1, 2], fn _ -> :skip end)
    end
  end

  describe "uniq/1" do
    test "removes duplicates while preserving first-seen order" do
      assert Rujira.Enum.uniq([3, 1, 3, 2, 1]) == [3, 1, 2]
    end

    test "leaves an already-unique list untouched" do
      assert Rujira.Enum.uniq([1, 2, 3]) == [1, 2, 3]
    end

    test "handles an empty enumerable" do
      assert Rujira.Enum.uniq([]) == []
    end

    test "works on mixed types" do
      assert Rujira.Enum.uniq([:a, "a", :a, 1, 1]) == [:a, "a", 1]
    end

    test "accepts a non-list enumerable" do
      assert Rujira.Enum.uniq(1..3) == [1, 2, 3]
    end
  end

  describe "reduce_async_while_ok/3" do
    test "collects ok values, preserving input order" do
      assert {:ok, [2, 4, 6]} =
               Rujira.Enum.reduce_async_while_ok([1, 2, 3], fn x -> {:ok, x * 2} end)
    end

    test "wraps bare return values as ok" do
      assert {:ok, [1, 2]} = Rujira.Enum.reduce_async_while_ok([1, 2], fn x -> x end)
    end

    test "propagates an error returned by the function" do
      assert {:error, :boom} =
               Rujira.Enum.reduce_async_while_ok([1, 2, 3], fn
                 2 -> {:error, :boom}
                 x -> {:ok, x}
               end)
    end

    test "omits skipped elements" do
      result =
        Rujira.Enum.reduce_async_while_ok([1, 2, 3], fn
          2 -> :skip
          x -> {:ok, x}
        end)

      assert {:ok, [1, 3]} = result
    end

    # Documents current behaviour rather than desired behaviour. `Task.async_stream`
    # links its tasks to the caller, so a task that exits abnormally brings the
    # caller down instead of being reported as `{:error, reason}` — the
    # `{:exit, reason}` clause in `handle_async_result/1` is only reachable via the
    # timeout path below. See #13 before "fixing" this test.
    @tag :capture_log
    test "a crashing task propagates the exit to the caller instead of returning an error" do
      Process.flag(:trap_exit, true)
      parent = self()

      pid =
        spawn_link(fn ->
          send(
            parent,
            {:result, Rujira.Enum.reduce_async_while_ok([1], fn _ -> exit(:killed) end)}
          )
        end)

      assert_receive {:EXIT, ^pid, :killed}, 1_000
      refute_receive {:result, _}, 50
    end

    test "surfaces a timeout as an error" do
      assert {:error, :timeout} =
               Rujira.Enum.reduce_async_while_ok([1], fn _ -> Process.sleep(50) end, timeout: 1)
    end

    test "handles an empty enumerable" do
      assert {:ok, []} = Rujira.Enum.reduce_async_while_ok([], fn x -> {:ok, x} end)
    end
  end
end
