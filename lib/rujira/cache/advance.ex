defmodule Rujira.Cache.Advance do
  @moduledoc """
  Moves the head, and invalidates on the way.

  The consumer calls `Rujira.Node.advance/1` on every new height. There is no
  process behind it: the work runs in the caller's own process, under an ETS
  lock, so the library owns no poller and no supervision tree beyond the
  table owner.

  ## The lock and the target

  Every caller raises the target to its own height, then races for the lock.
  The winner applies `head + 1`, `head + 2`, ... until the head reaches the
  target; the losers return `:ok` at once. **A loser's `:ok` means scheduled,
  not applied** - the head may still be behind when it returns, which is why an
  indexer calls `advance/1` and then reads with `height:` pinned rather than
  heightless.

  After releasing the lock the holder re-reads the target and reacquires if it
  moved, so a caller that raised the target and lost the race in the window
  before the release cannot leave the head parked.

  A lock whose holder is dead, or that is older than `lock_timeout`, is taken
  over. That can leave two writers at once, which is safe because every write
  is a max: the head moves by `compare_exchange` and can never go down, markers
  are raised and never lowered, and applying a block twice is idempotent.

  ## Applying a block

  For `y == head + 1`: derive the changed sources, raise each marker to `y`,
  then set the head to `y`. **The head is written last**, so a reader that
  reads the head first, then the generation, then a row, then its markers,
  cannot see a head that is ahead of the invalidations that came with it.

  The block is the one the consumer pushed when it is that height; otherwise it
  is fetched with `Rujira.Thorchain.Block.get/1` inside a task with a deadline,
  because a fetch that blocks forever would freeze the head with no error.
  Blocks are not stored: `advance/1` needs their events, not their text.

  A pushed block is deposited under its own height, and only if that height is
  still ahead of the head, so two consumers pushing different blocks at once
  cannot overwrite each other and a block that arrived too late is dropped
  rather than left to linger. Every deposit at or below the head goes when the
  head reaches it, whether it was applied, skipped or reset past.

  ## Resets

  A reset writes the generation bump and `:all` first and the head last, in
  that order, and is always sound - it only makes the cache colder. Three
  things trigger one:

    * the head is more than `max_catchup` blocks behind the target, where
      filling one block at a time would cost more than starting over;
    * the same block has failed `max_block_failures` times in a row, which
      would otherwise hold the head - and every heightless read - at a stale
      height until `max_catchup` rescued it;
    * `Rujira.Cache.invalidate_all/0`.

  A height at or below the head is a no-op, and the first `advance/1` of all
  simply sets the head: there is nothing cached yet to invalidate.
  """

  alias Rujira.Cache.Config
  alias Rujira.Cache.Invalidator
  alias Rujira.Cache.Markers
  alias Rujira.Cache.Store
  alias Rujira.Cache.Tables
  alias Rujira.Logger
  alias Rujira.Thorchain.Block

  @min_height 1
  @max_height 9_223_372_036_854_775_807
  @fetch_timeout 15_000

  @doc """
  Advances the head to `height`, or to a block the consumer already holds.

  Returns `:ok`, or `{:error, reason}` when this caller's own block fetch
  failed. A caller that did not win the lock always returns `:ok`.
  """
  @spec advance(pos_integer() | Block.t()) :: :ok | {:error, term()}
  def advance(%Block{height: height} = block)
      when is_integer(height) and height >= @min_height and height <= @max_height do
    schedule(height, block)
  end

  def advance(height)
      when is_integer(height) and height >= @min_height and height <= @max_height do
    schedule(height, nil)
  end

  def advance(_height), do: {:error, :invalid_height}

  @doc "Bumps the generation and marks `:all`, making every stored row unreachable."
  @spec invalidate_all() :: :ok
  def invalidate_all do
    Tables.bump_gen()
    Tables.raise_all(Tables.head_at())
    :ets.delete_all_objects(Tables.identity())
    :ok
  end

  # --- Private: scheduling ---

  defp schedule(height, block) do
    deposit(block, Tables.head_at())
    Tables.raise_target(height)
    take_lock()
  end

  defp take_lock do
    case lock() do
      {:ok, token} -> drive(token)
      :busy -> :ok
    end
  end

  defp drive(token) do
    result = fill()
    unlock(token)
    settle(result)
  end

  defp settle(:ok), do: recheck()
  defp settle({:error, _reason} = error), do: error

  defp recheck do
    case Tables.target() > Tables.head_at() do
      true -> take_lock()
      false -> :ok
    end
  end

  # --- Private: the fill loop ---

  defp fill, do: fill(Tables.head_at(), Tables.target())

  defp fill(head, target) when target <= head, do: :ok

  defp fill(0, target) do
    Tables.raise_head(target)
    :ok
  end

  defp fill(head, target) when target - head > 0 do
    case target - head > Config.max_catchup() do
      true -> reset(target)
      false -> step(head + 1)
    end
  end

  defp step(y) do
    case apply_block(y) do
      :ok -> fill()
      {:error, _reason} = error -> error
    end
  end

  defp apply_block(y) do
    case block(y) do
      {:ok, block} -> commit(block, y)
      {:error, reason} -> failed(y, reason)
    end
  end

  defp commit(block, y) do
    block
    |> Invalidator.sources()
    |> Enum.each(&Markers.raise_source(&1, y))

    clear_failures()
    Tables.raise_head(y)
    drop_pushed(Tables.head_at())
    Store.sweep(Tables.head_at(), Tables.gen())
    :ok
  end

  defp reset(target) do
    Tables.bump_gen()
    Tables.raise_all(target)
    Tables.raise_head(target)
    drop_pushed(Tables.head_at())
    clear_failures()
    :ok
  end

  # --- Private: blocks ---

  defp block(y) do
    case pushed(y) do
      {:ok, _block} = ok -> ok
      :none -> fetch(y)
    end
  end

  defp deposit(nil, _head), do: :ok

  defp deposit(%Block{height: height}, head) when height <= head, do: :ok

  defp deposit(%Block{height: height} = block, _head) do
    :ets.insert(Tables.meta(), {{:pushed, height}, block})
    :ok
  end

  defp pushed(y) do
    case :ets.lookup(Tables.meta(), {:pushed, y}) do
      [{{:pushed, ^y}, block} = row] -> consume(row, block)
      _ -> :none
    end
  end

  defp drop_pushed(head) do
    match = [{{{:pushed, :"$1"}, :_}, [{:"=<", :"$1", head}], [true]}]
    :ets.select_delete(Tables.meta(), match)
    :ok
  end

  defp consume(row, block) do
    :ets.delete_object(Tables.meta(), row)
    {:ok, block}
  end

  defp fetch(y) do
    task = Task.async(fn -> Block.fetch_uncached(y) end)

    case Task.yield(task, @fetch_timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> result
      {:exit, reason} -> {:error, reason}
      nil -> {:error, {:timeout, __MODULE__}}
    end
  end

  # --- Private: failures ---

  defp failed(y, reason) do
    count = bump_failures(y)

    case count >= Config.max_block_failures() do
      true -> give_up(y, count, reason)
      false -> {:error, reason}
    end
  end

  defp give_up(y, count, reason) do
    Logger.error(
      __MODULE__,
      "block #{y} failed #{count} times (#{inspect(reason)}); resetting to the target"
    )

    reset(Tables.target())
  end

  defp bump_failures(y) do
    count = failures(y) + 1
    :ets.insert(Tables.meta(), {:failures, y, count})
    count
  end

  defp failures(y) do
    case :ets.lookup(Tables.meta(), :failures) do
      [{:failures, ^y, count}] -> count
      _ -> 0
    end
  end

  defp clear_failures do
    :ets.delete(Tables.meta(), :failures)
    :ok
  end

  # --- Private: the lock ---

  defp lock do
    at = System.monotonic_time(:millisecond)

    case :ets.insert_new(Tables.lock(), {:lock, self(), at}) do
      true -> {:ok, at}
      false -> takeover(at)
    end
  end

  defp takeover(at) do
    case :ets.lookup(Tables.lock(), :lock) do
      [{:lock, pid, held} = row] -> maybe_take(row, stale?(pid, held, at), at)
      _ -> retake(at)
    end
  end

  defp maybe_take(row, true, at) do
    :ets.delete_object(Tables.lock(), row)
    retake(at)
  end

  defp maybe_take(_row, false, _at), do: :busy

  defp retake(at) do
    case :ets.insert_new(Tables.lock(), {:lock, self(), at}) do
      true -> {:ok, at}
      false -> :busy
    end
  end

  defp stale?(pid, held, at),
    do: not Process.alive?(pid) or at - held > Config.lock_timeout()

  defp unlock(token) do
    :ets.delete_object(Tables.lock(), {:lock, self(), token})
    :ok
  end
end
