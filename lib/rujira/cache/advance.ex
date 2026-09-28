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
  target. **Either way, `:ok` means applied**: a caller that lost the race
  returns only once the head has reached its own height, so a consumer can read
  heightless straight after `advance/1` and be served the height it just
  pushed.

  A loser waits by monitoring the holder and re-reading the head on a bounded
  backoff. It cannot be notified instead: the holder writes the head and
  nothing else, and a holder that had to publish to a waiter list would pay for
  every caller that is not there. The backoff is the cost of keeping the fill
  path free of them.

  The wait ends in `{:error, :timeout}` after `lock_timeout` - the same window
  after which a lock is taken over. A waiter therefore reaches it only when the
  lock it keeps finding was taken no earlier than its own wait began, because
  such a lock goes stale after the waiter's deadline rather than before it -
  whether the holder kept it fresh by reacquiring it, as a long catch-up does,
  or simply won the race a moment ahead and is slow.

  After releasing the lock the holder re-reads the target and reacquires if it
  moved, so a caller that raised the target and then died cannot leave the head
  parked.

  A lock whose holder is dead, or that is older than `lock_timeout`, is taken
  over - by a fresh caller, or by a waiter whose monitor fired. That can leave
  two writers at once, which is safe because every write is a max: the head
  moves by `compare_exchange` and can never go down, markers are raised and
  never lowered, and applying a block twice is idempotent.

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

    * `:catchup` - the head is more than `max_catchup` blocks behind the
      target, where filling one block at a time would cost more than starting
      over;
    * `:stuck_block` - the same block has failed `max_block_failures` times in
      a row, which would otherwise hold the head - and every heightless read -
      at a stale height until `max_catchup` rescued it;
    * `:invalidate_all` - `Rujira.Cache.invalidate_all/0`.

  An `:upgrade` block invalidates everything too, as of its own height, but by
  raising the `:all` marker rather than by bumping the generation: the rows
  below it stay readable at their own heights.

  Each of the four logs a `Logger.warning` and emits
  `[:rujira, :cache, :reset]` with its reason - see `Rujira.Cache`.

  A height at or below the head is a no-op, and the first `advance/1` of all
  simply sets the head: there is nothing cached yet to invalidate.
  """

  alias Rujira.Cache.Config
  alias Rujira.Cache.Invalidator
  alias Rujira.Cache.Markers
  alias Rujira.Cache.Store
  alias Rujira.Cache.Tables
  alias Rujira.Cache.Telemetry
  alias Rujira.Logger
  alias Rujira.Thorchain.Block

  @min_height 1
  @max_height 9_223_372_036_854_775_807
  @fetch_timeout 15_000
  @backoff_min 1
  @backoff_max 50

  @doc """
  Advances the head to `height`, or to a block the consumer already holds.

  Returns `:ok` once the head has reached `height`, whether this caller applied
  the blocks itself or waited for the caller that did.

  `{:error, reason}` is this caller's own block fetch failing, and
  `{:error, :timeout}` is `lock_timeout` passing while another caller held the
  lock without the head reaching `height`.
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
    head = Tables.head_at()
    Tables.bump_gen()
    Tables.raise_all(head)
    :ets.delete_all_objects(Tables.identity())
    announce(:invalidate_all, head, head)
  end

  # --- Private: scheduling ---

  defp schedule(height, block) do
    deposit(block, Tables.head_at())
    Tables.raise_target(height)
    drive(height, deadline(), @backoff_min)
  end

  defp deadline, do: System.monotonic_time(:millisecond) + Config.lock_timeout()

  defp drive(height, deadline, backoff) do
    case lock() do
      {:ok, token} -> hold(token, height, deadline)
      :busy -> await(height, deadline, backoff)
    end
  end

  defp hold(token, height, deadline) do
    from = Tables.head_at()
    start = System.monotonic_time()
    {applied, result} = fill()
    unlock(token)
    Telemetry.advance(from, Tables.head_at(), applied, start)
    settle(result, height, deadline)
  end

  defp settle({:error, _reason} = error, _height, _deadline), do: error

  # The target is at least this caller's own height, so a head that has caught
  # up with it has caught up with `height` too. Where it has not, the target
  # moved under this caller - another one raised it while the lock was being
  # let go - and going round again is what keeps that from parking the head.
  defp settle(:ok, height, deadline) do
    case Tables.target() > Tables.head_at() do
      true -> drive(height, deadline, @backoff_min)
      false -> :ok
    end
  end

  # --- Private: waiting on another caller ---

  defp await(height, deadline, backoff) do
    cond do
      Tables.head_at() >= height -> :ok
      remaining(deadline) == 0 -> {:error, :timeout}
      true -> pause(height, deadline, backoff)
    end
  end

  # The monitor is what makes a crashed holder cheap to notice - the backoff
  # would find it too, a whole sleep later. Trying the lock again afterwards is
  # also how a holder that went stale while this caller waited is taken over.
  defp pause(height, deadline, backoff) do
    linger(holder(), min(backoff, remaining(deadline)))
    drive(height, deadline, next(backoff))
  end

  defp holder do
    case :ets.lookup(Tables.lock(), :lock) do
      [{:lock, pid, _at}] -> {:ok, pid}
      _ -> :none
    end
  end

  defp linger(:none, _timeout), do: :ok

  defp linger({:ok, pid}, timeout) do
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, ^pid, _reason} -> :ok
    after
      timeout -> :ok
    end

    Process.demonitor(ref, [:flush])
    :ok
  end

  defp next(backoff), do: min(backoff * 2, @backoff_max)

  defp remaining(deadline), do: max(deadline - System.monotonic_time(:millisecond), 0)

  # --- Private: the fill loop ---

  defp fill, do: fill(Tables.head_at(), Tables.target(), 0)

  defp fill(head, target, applied) when target <= head, do: {applied, :ok}

  defp fill(0, target, applied) do
    Tables.raise_head(target)
    {applied, :ok}
  end

  defp fill(head, target, applied) when target - head > 0 do
    case target - head > Config.max_catchup() do
      true -> catchup(target, applied)
      false -> step(head + 1, applied)
    end
  end

  defp catchup(target, applied) do
    reset(target, :catchup)
    {applied, :ok}
  end

  defp step(y, applied) do
    case apply_block(y) do
      :applied -> fill(Tables.head_at(), Tables.target(), applied + 1)
      :reset -> {applied, :ok}
      {:error, _reason} = error -> {applied, error}
    end
  end

  defp apply_block(y) do
    case block(y) do
      {:ok, block} -> commit(block, y)
      {:error, reason} -> failed(y, reason)
    end
  end

  defp commit(block, y) do
    sources = Invalidator.sources(block)
    Enum.each(sources, &Markers.raise_source(&1, y))
    upgrade(:all in sources, y)

    clear_failures()
    Tables.raise_head(y)
    drop_pushed(Tables.head_at())
    Store.sweep(Tables.head_at(), Tables.gen())
    :applied
  end

  # The head is written last, so it is still the block before this one.
  defp upgrade(true, y), do: announce(:upgrade, Tables.head_at(), y)
  defp upgrade(false, _y), do: :ok

  defp reset(target, reason) do
    from = Tables.head_at()
    Tables.bump_gen()
    Tables.raise_all(target)
    Tables.raise_head(target)
    drop_pushed(Tables.head_at())
    clear_failures()
    announce(reason, from, target)
  end

  defp announce(reason, from, to) do
    Logger.warning(
      __MODULE__,
      "#{reason}: every cached value invalidated, head #{from} -> #{to}"
    )

    Telemetry.reset(reason, from, to)
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

    reset(Tables.target(), :stuck_block)
    :reset
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
