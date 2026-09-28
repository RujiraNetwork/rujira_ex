defmodule Rujira.Cache.Markers do
  @moduledoc """
  The last height each source changed at.

  A marker is raised with `max`, never written flat, so two `advance/1` writers
  - a holder and a zombie it took the lock from - can never lower one. A source
  that has never been seen reads as `0`, which is below every height, so a row
  that depends on it is valid until the source actually changes.

  `:all` is not held here but in `:atomics`: it is an implicit source of every
  frontier row, so it is read on every lookup.

  ## Bound and the floor

  The table grows by one row per address that ever sent or received coins, so
  it is capped at `max_markers`. Over the cap, every marker at or below a
  `floor` is dropped - but dropping a marker on its own would lose what it
  records, so the collapse first raises the *marker floor*, a CAS-max height in
  `:atomics`, to that floor. Every source is then read as having changed at
  `max(marker, floor)`, so a row whose `as_of` is below the floor is invalid
  whatever the dropped marker said.

  The floor is raised before a single marker is dropped, and it is read *after*
  the markers on the lookup path: a reader that misses a dropped marker reads
  the floor that was raised before the drop, and never serves the row. The
  frontier's oldest `as_of` is the floor the sweep passes, because everything at
  or below it is dead anyway; a read still in flight from an earlier head may
  file below it, and that row is refused by `Rujira.Cache.Store` and invalid
  here.

  A collapse that would not raise the floor is skipped: everything at or below
  the current floor has already gone, and a marker is only ever raised to the
  height being applied, which is above the head and so above the floor.

  A single old but still-valid frontier row - one that never had a source
  change - pins the frontier's oldest `as_of` forever, so the floor the sweep
  passes never rises past it and the collapse frees nothing, block after
  block. `prune/2` reports this back as `{true, dropped}`: still over the cap
  after the attempt, however many markers `dropped` came with it.
  `Rujira.Cache.Store` responds by evicting the frontier's oldest row - always
  safe, since the evicted entry is just refetched on its next read - which
  frees the pin and lets the next sweep's floor climb past whatever the stuck
  collapse could not reach.
  """

  alias Rujira.Cache.Tables

  @type source :: term()

  @doc "Raises `source`'s marker to `height`, never lowering it."
  @spec raise_source(source(), pos_integer()) :: :ok
  def raise_source(:all, height) do
    Tables.raise_all(height)
    :ok
  end

  def raise_source(source, height) do
    case :ets.insert_new(Tables.markers(), {source, height}) do
      true -> :ok
      false -> replace(source, height)
    end
  end

  @doc "The height `source` last changed at, or `0` if it never has."
  @spec marker(source()) :: non_neg_integer()
  def marker(source) do
    case :ets.lookup(Tables.markers(), source) do
      [{^source, height}] -> height
      _ -> 0
    end
  end

  @doc """
  Whether any of `sources`, or `:all`, changed after `as_of`.

  This is the frontier's validity test. `:all` is read first: it is an atomics
  read and it invalidates everything. The marker floor is read last, so a
  reader that raced a collapse and found no marker still sees the floor that
  was raised before that marker was dropped.
  """
  @spec changed_after?([source()], non_neg_integer()) :: boolean()
  def changed_after?(sources, as_of) do
    Tables.all_marker() > as_of or Enum.any?(sources, &(marker(&1) > as_of)) or
      collapsed_after?(sources, as_of)
  end

  @doc """
  Collapses the marker table to `floor` once it is over `max_markers`.

  The floor is raised first and the markers at or below it are dropped after -
  see the moduledoc. A floor that would not move frees nothing, so it is not
  rescanned. Returns whether the table is still over `max_markers` once the
  attempt is done - so the caller can evict a frontier row to unstick a floor
  that a still-valid old row is pinning - together with how many markers the
  collapse actually dropped.
  """
  @spec prune(non_neg_integer(), pos_integer()) :: {boolean(), non_neg_integer()}
  def prune(floor, max_markers) do
    case over_cap?(max_markers) do
      true ->
        dropped = maybe_collapse(floor)
        {over_cap?(max_markers), dropped}

      false ->
        {false, 0}
    end
  end

  # --- Private ---

  defp collapsed_after?([], _as_of), do: false
  defp collapsed_after?(_sources, as_of), do: Tables.marker_floor() > as_of

  defp over_cap?(max_markers) do
    case :ets.info(Tables.markers(), :size) do
      size when is_integer(size) -> size > max_markers
      _ -> false
    end
  end

  defp maybe_collapse(floor) do
    case floor > Tables.marker_floor() do
      true -> collapse(floor)
      false -> 0
    end
  end

  defp collapse(floor) do
    Tables.raise_marker_floor(floor)
    drop_to(floor)
  end

  defp replace(source, height) do
    :ets.select_replace(Tables.markers(), [
      {{source, :"$1"}, [{:<, :"$1", height}], [{:const, {source, height}}]}
    ])

    :ok
  end

  defp drop_to(floor) do
    :ets.select_delete(Tables.markers(), [{{:_, :"$1"}, [{:"=<", :"$1", floor}], [true]}])
  end
end
