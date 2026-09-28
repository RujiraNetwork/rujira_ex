defmodule Rujira.Cache.Store do
  @moduledoc """
  The three stores, and the memory bounds that keep them from growing without
  end.

  ## Frontier

  `{{gen, query_key}, as_of, sources, value}`: the value as it was at height
  `as_of`, carried over to every later height until one of `sources` changes.
  A row is valid at `h` when `as_of <= h <= head` and no source of it - `:all`
  included - changed after `as_of`. A row inserted with `as_of == h` is
  therefore always valid at `h`.

  A row is only ever inserted when it is newer than the one already there, so
  the slot cannot ping-pong between two heights. The insert is
  `insert_new`, then a `select_replace` guarded on the stored `as_of`, so it is
  atomic against a concurrent writer.

  A row below the marker floor is refused rather than stored: the markers that
  would invalidate it have been collapsed, so `Rujira.Cache.Markers` reads it as
  invalid and it would only occupy the table until the sweep reached it.

  ## Exact

  `{{height, gen, query_key}, value}`: an immutable fact at a height. The table
  is an `ordered_set` keyed by height first, and a height's rows are dropped by
  a `select_delete` whose key pattern binds that height, so the delete is a
  range over one height rather than a scan of the table.

  It prunes itself on insert, independently of `advance/1`, once it holds
  `retention` distinct heights - dropping the *least recently inserted* height,
  not the numerically smallest, so a backfill at old heights is not evicted by
  head churn before it can be read. The order is held in `exact_heights`, one
  `{height, seq}` row per height with `seq` from an `:atomics` counter: a
  height is admitted with `insert_new` and re-stamped with a guarded
  `select_replace`, so two concurrent inserts cannot lose a height between a
  read and a write and leave its rows behind for good.

  ## Identity

  `{{gen, query_key}, value}`: height-independent, kept until the generation
  changes.

  ## Sweep

  `advance/1` calls `sweep/2` once per block. It does three bounded jobs:

    * evicts by oldest `as_of` while the frontier is over `frontier_max_rows`;
    * walks `sweep_per_block` rows from a cursor, dropping those that are
      invalid at the head or left behind by an old generation;
    * collapses the marker table when it is over `max_markers`, raising the
      marker floor to the frontier's oldest `as_of` first - and if that
      collapse frees nothing (an old but still-valid frontier row is pinning
      the floor), evicts that oldest frontier row so the next sweep's floor
      can climb past it.

  The first two jobs walk the `frontier_index`, an `ordered_set` of
  `{{as_of, gen, query_key}}` that orders the frontier by age. The cursor is a
  key of that index rather than a `select/3` continuation: `:ets.next/2` on an
  `ordered_set` is well defined across concurrent inserts and deletes, where a
  continuation is only well defined under `safe_fixtable`, which would keep
  deleted objects alive for as long as the sweep is fixed.

  Every delete is guarded on the `as_of` it read, or is an exact-object delete.
  A plain `delete(key)` would drop a fresh row that replaced the stale one
  between the scan and the delete.

  A read that races the owner's restart hits a dead table; `ArgumentError` is
  treated as a miss.
  """

  alias Rujira.Cache.Config
  alias Rujira.Cache.Markers
  alias Rujira.Cache.Tables

  @type query_key :: term()
  @type gen :: non_neg_integer()

  # --- Frontier ---

  @doc "The frontier row for `query_key`, if it is valid at `h`."
  @spec frontier_lookup(gen(), query_key(), pos_integer(), non_neg_integer()) ::
          {:ok, term()} | :miss
  def frontier_lookup(gen, query_key, h, head) do
    safe(:miss, fn ->
      Tables.frontier()
      |> :ets.lookup({gen, query_key})
      |> frontier_valid(h, head)
    end)
  end

  @doc "Stores `value` as of `as_of`, unless a newer row is already there."
  @spec frontier_put(gen(), query_key(), pos_integer(), [Markers.source()], term()) :: :ok
  def frontier_put(gen, query_key, as_of, sources, value) do
    row = {{gen, query_key}, as_of, sources, value}

    safe(:ok, fn ->
      case as_of < Tables.marker_floor() do
        true -> :ok
        false -> insert_row(row, gen, query_key, as_of)
      end
    end)
  end

  # --- Exact ---

  @doc "The stored fact for `query_key` at `h`."
  @spec exact_lookup(gen(), query_key(), pos_integer()) :: {:ok, term()} | :miss
  def exact_lookup(gen, query_key, h) do
    safe(:miss, fn ->
      case :ets.lookup(Tables.exact(), {h, gen, query_key}) do
        [{_key, value}] -> {:ok, value}
        _ -> :miss
      end
    end)
  end

  @doc "Stores `value` as the fact for `query_key` at `h`, pruning the oldest height if needed."
  @spec exact_put(gen(), query_key(), pos_integer(), term()) :: :ok
  def exact_put(gen, query_key, h, value) do
    safe(:ok, fn ->
      :ets.insert(Tables.exact(), {{h, gen, query_key}, value})
      track_height(h)
    end)
  end

  # --- Identity ---

  @doc "The stored identity value for `query_key`."
  @spec identity_lookup(gen(), query_key()) :: {:ok, term()} | :miss
  def identity_lookup(gen, query_key) do
    safe(:miss, fn ->
      case :ets.lookup(Tables.identity(), {gen, query_key}) do
        [{_key, value}] -> {:ok, value}
        _ -> :miss
      end
    end)
  end

  @doc "Stores `value` as the identity value for `query_key`."
  @spec identity_put(gen(), query_key(), term()) :: :ok
  def identity_put(gen, query_key, value) do
    safe(:ok, fn ->
      :ets.insert(Tables.identity(), {{gen, query_key}, value})
      :ok
    end)
  end

  # --- Sweep ---

  @doc "One block's bounded sweep of the frontier and the marker table."
  @spec sweep(non_neg_integer(), gen()) :: :ok
  def sweep(head, gen) do
    safe(:ok, fn ->
      evict(Config.sweep_per_block())
      walk(cursor(), Config.sweep_per_block(), gen)
      prune_markers(head)
    end)
  end

  @doc "The oldest `as_of` any frontier row holds, or `head` if the frontier is empty."
  @spec oldest_as_of(non_neg_integer()) :: non_neg_integer()
  def oldest_as_of(head) do
    case :ets.first(Tables.frontier_index()) do
      {as_of, _gen, _query_key} -> as_of
      _ -> head
    end
  end

  # --- Private: markers ---

  # An old but still-valid frontier row pins `oldest_as_of`, so the collapse
  # can free nothing block after block. When it does, the pinning row is
  # evicted - safe, since it is just refetched - so the next sweep's floor
  # can climb past it.
  defp prune_markers(head) do
    case Markers.prune(oldest_as_of(head), Config.max_markers()) do
      true -> evict_oldest_row()
      false -> :ok
    end
  end

  defp evict_oldest_row do
    case :ets.first(Tables.frontier_index()) do
      {_as_of, _gen, _query_key} = key -> drop(key)
      _ -> :ok
    end
  end

  # --- Private: frontier ---

  defp insert_row(row, gen, query_key, as_of) do
    case :ets.insert_new(Tables.frontier(), row) do
      true -> index_put(gen, query_key, as_of)
      false -> frontier_replace(row, gen, query_key, as_of)
    end
  end

  defp frontier_valid([{_key, as_of, sources, value}], h, head)
       when as_of <= h and h <= head do
    case Markers.changed_after?(sources, as_of) do
      true -> :miss
      false -> {:ok, value}
    end
  end

  defp frontier_valid(_rows, _h, _head), do: :miss

  defp frontier_replace(row, gen, query_key, as_of) do
    stored = stored_as_of(gen, query_key)

    case replace(row, gen, query_key, as_of, stored) do
      true -> reindex(gen, query_key, stored, as_of)
      false -> :ok
    end
  end

  defp replace(_row, _gen, _query_key, as_of, stored) when stored >= as_of, do: false

  defp replace(row, gen, query_key, as_of, _stored) do
    match = [{{{gen, query_key}, :"$1", :_, :_}, [{:<, :"$1", as_of}], [{:const, row}]}]
    :ets.select_replace(Tables.frontier(), match) == 1
  end

  defp stored_as_of(gen, query_key) do
    case :ets.lookup(Tables.frontier(), {gen, query_key}) do
      [{_key, as_of, _sources, _value}] -> as_of
      _ -> 0
    end
  end

  defp reindex(gen, query_key, stored, as_of) do
    :ets.delete(Tables.frontier_index(), {stored, gen, query_key})
    index_put(gen, query_key, as_of)
  end

  defp index_put(gen, query_key, as_of) do
    :ets.insert(Tables.frontier_index(), {{as_of, gen, query_key}})
    :ok
  end

  # --- Private: sweep ---

  defp evict(budget) when budget <= 0, do: :ok

  defp evict(budget) do
    case over_cap?() do
      true -> evict_oldest(budget)
      false -> :ok
    end
  end

  defp evict_oldest(budget) do
    case :ets.first(Tables.frontier_index()) do
      {_as_of, _gen, _query_key} = key ->
        drop(key)
        evict(budget - 1)

      _ ->
        :ok
    end
  end

  defp over_cap? do
    case :ets.info(Tables.frontier(), :size) do
      size when is_integer(size) -> size > Config.frontier_max_rows()
      _ -> false
    end
  end

  defp walk(cursor, 0, _gen), do: put_cursor(cursor)

  defp walk(cursor, budget, gen) do
    case next(cursor) do
      {_as_of, _gen, _query_key} = key ->
        visit(key, gen)
        walk(key, budget - 1, gen)

      _ ->
        put_cursor(nil)
    end
  end

  defp next(nil), do: :ets.first(Tables.frontier_index())
  defp next(cursor), do: :ets.next(Tables.frontier_index(), cursor)

  defp visit({_as_of, gen, _query_key} = key, current) when gen != current, do: drop(key)

  defp visit({as_of, gen, query_key} = key, _current) do
    case :ets.lookup(Tables.frontier(), {gen, query_key}) do
      [{_key, ^as_of, sources, _value}] -> drop_changed(key, sources, as_of)
      _ -> :ets.delete(Tables.frontier_index(), key)
    end
  end

  defp drop_changed(key, sources, as_of) do
    case Markers.changed_after?(sources, as_of) do
      true -> drop(key)
      false -> :ok
    end
  end

  defp drop({as_of, gen, query_key} = key) do
    match = [{{{gen, query_key}, :"$1", :_, :_}, [{:==, :"$1", as_of}], [true]}]
    :ets.select_delete(Tables.frontier(), match)
    :ets.delete(Tables.frontier_index(), key)
    :ok
  end

  defp cursor, do: meta_get(:sweep_cursor, nil)

  defp put_cursor(cursor), do: meta_put(:sweep_cursor, cursor)

  # --- Private: exact retention ---

  defp track_height(h) do
    case :ets.lookup(Tables.exact_heights(), h) do
      [{^h, seq}] -> touch(h, seq)
      _ -> admit(h)
    end
  end

  defp touch(h, seq) do
    match = [{{h, seq}, [], [{:const, {h, Tables.next_seq()}}]}]
    :ets.select_replace(Tables.exact_heights(), match)
    :ok
  end

  # A lost `insert_new` means another writer stamped this height with a newer
  # sequence, which is what `touch/2` would have done.
  defp admit(h) do
    case :ets.insert_new(Tables.exact_heights(), {h, Tables.next_seq()}) do
      true -> prune_heights()
      false -> :ok
    end
  end

  defp prune_heights do
    case :ets.info(Tables.exact_heights(), :size) do
      size when is_integer(size) -> evict_heights(size - Config.retention())
      _ -> :ok
    end
  end

  defp evict_heights(excess) when excess <= 0, do: :ok

  defp evict_heights(excess) do
    case :ets.foldl(&older/2, :none, Tables.exact_heights()) do
      {h, seq} ->
        evict_height(h, seq)
        evict_heights(excess - 1)

      :none ->
        :ok
    end
  end

  defp evict_height(h, seq) do
    case :ets.select_delete(Tables.exact_heights(), [{{h, seq}, [], [true]}]) do
      1 -> drop_height(h)
      _ -> :ok
    end
  end

  defp older(row, :none), do: row
  defp older({_h, seq}, {_oldest, oldest_seq} = oldest) when seq >= oldest_seq, do: oldest
  defp older(row, _oldest), do: row

  # The key pattern binds the height, so an `ordered_set` delete is a range
  # over that height alone.
  defp drop_height(h) do
    :ets.select_delete(Tables.exact(), [{{{h, :_, :_}, :_}, [], [true]}])
    :ok
  end

  # --- Private: meta ---

  defp meta_get(key, default) do
    case :ets.lookup(Tables.meta(), key) do
      [{^key, value}] -> value
      _ -> default
    end
  end

  defp meta_put(key, value) do
    :ets.insert(Tables.meta(), {key, value})
    :ok
  end

  defp safe(default, fun) do
    fun.()
  rescue
    ArgumentError -> default
  end
end
