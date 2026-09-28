defmodule Rujira.Cache.Tables do
  @moduledoc """
  Passive owner of the cache's ETS tables and of its `:atomics` array.

  The process holds the tables and nothing else - it has no calls, no casts
  and no state beyond the atomics reference it publishes. Every read and write
  happens in the caller's process, directly against the public tables.

  ## Tables

  | Table | Type | Holds |
  |---|---|---|
  | `frontier` | `set` | `{{gen, query_key}, as_of, sources, value}` - state as of the head |
  | `frontier_index` | `ordered_set` | `{{as_of, gen, query_key}}` - the frontier ordered by age, for the sweep and the row cap |
  | `exact` | `ordered_set` | `{{height, gen, query_key}, value}` - immutable facts at a height |
  | `exact_heights` | `set` | `{height, seq}` - the exact store's heights, by insertion order |
  | `identity` | `set` | `{{gen, query_key}, value}` - height-independent facts |
  | `flight` | `set` | `{flight_key, :running, pid}` - the in-flight fetches |
  | `waiters` | `duplicate_bag` | `{flight_key, alias_ref}` - who to notify when one finishes |
  | `markers` | `set` | `{source, height}` - the last height a source changed at |
  | `lock` | `set` | `{:lock, pid, acquired_at_ms}` - the `advance/1` lock |
  | `meta` | `set` | the sweep cursor, block failures, the blocks a consumer pushed |

  ## Atomics

  `head`, `target`, `gen`, the `:all` marker and the marker floor live in one
  `:atomics` array rather than in ETS: they are read on every single cache
  lookup, and an atomics read is about an order of magnitude cheaper than an
  ETS lookup. `:atomics` also gives `compare_exchange/4`, which is what makes
  the CAS-max write of `head` - the rule that lets a stale `advance/1` holder
  be taken over without ever lowering the head - a single instruction rather
  than a lock. The marker floor is written the same way, and the exact store's
  insertion sequence is an `add_get/3`.

  `0` means "unset": heights start at 1, so a head of `0` is "no block has
  been advanced yet".

  The reference is published once in `:persistent_term`, never re-put: each
  put triggers a global scan.
  """

  use GenServer

  @atomics_key {__MODULE__, :atomics}

  @head 1
  @target 2
  @gen 3
  @all 4
  @floor 5
  @seq 6
  @size 6

  @frontier :rujira_cache_frontier
  @frontier_index :rujira_cache_frontier_index
  @exact :rujira_cache_exact
  @exact_heights :rujira_cache_exact_heights
  @identity :rujira_cache_identity
  @flight :rujira_cache_flight
  @waiters :rujira_cache_waiters
  @markers :rujira_cache_markers
  @lock :rujira_cache_lock
  @meta :rujira_cache_meta

  # --- Tables ---

  @doc "The frontier table: state as of the head, carried over between blocks."
  @spec frontier() :: atom()
  def frontier, do: @frontier

  @doc "The frontier's age index, ordered by `as_of`."
  @spec frontier_index() :: atom()
  def frontier_index, do: @frontier_index

  @doc "The exact table: immutable facts keyed by height."
  @spec exact() :: atom()
  def exact, do: @exact

  @doc "The exact store's heights, each with the sequence number of its last insert."
  @spec exact_heights() :: atom()
  def exact_heights, do: @exact_heights

  @doc "The identity table: height-independent facts."
  @spec identity() :: atom()
  def identity, do: @identity

  @doc "The in-flight table."
  @spec flight() :: atom()
  def flight, do: @flight

  @doc "The in-flight waiters."
  @spec waiters() :: atom()
  def waiters, do: @waiters

  @doc "The source markers."
  @spec markers() :: atom()
  def markers, do: @markers

  @doc "The `advance/1` lock."
  @spec lock() :: atom()
  def lock, do: @lock

  @doc "Bookkeeping for the stores and `advance/1`."
  @spec meta() :: atom()
  def meta, do: @meta

  @doc "Every table, in creation order."
  @spec all() :: [atom()]
  def all do
    [
      @frontier,
      @frontier_index,
      @exact,
      @exact_heights,
      @identity,
      @flight,
      @waiters,
      @markers,
      @lock,
      @meta
    ]
  end

  # --- Counters ---

  @doc "The head, or `nil` before the first `Rujira.Node.advance/1`."
  @spec head() :: pos_integer() | nil
  def head do
    case get(@head) do
      0 -> nil
      head -> head
    end
  end

  @doc "The head as an integer, `0` before the first `Rujira.Node.advance/1`."
  @spec head_at() :: non_neg_integer()
  def head_at, do: get(@head)

  @doc "The highest height any caller has asked `advance/1` to reach."
  @spec target() :: non_neg_integer()
  def target, do: get(@target)

  @doc "The current generation. Every frontier, exact and identity key carries it."
  @spec gen() :: non_neg_integer()
  def gen, do: get(@gen)

  @doc "The height the `:all` source last changed at."
  @spec all_marker() :: non_neg_integer()
  def all_marker, do: get(@all)

  @doc """
  The marker floor: the height every source is treated as having changed at.

  Raised whenever `Rujira.Cache.Markers` collapses the marker table, so a
  source whose marker was dropped still invalidates every row below it.
  """
  @spec marker_floor() :: non_neg_integer()
  def marker_floor, do: get(@floor)

  @doc "Raises the head to `height`, never lowering it. Returns the resulting head."
  @spec raise_head(non_neg_integer()) :: non_neg_integer()
  def raise_head(height), do: raise_max(@head, height)

  @doc "Raises the target to `height`, never lowering it."
  @spec raise_target(non_neg_integer()) :: non_neg_integer()
  def raise_target(height), do: raise_max(@target, height)

  @doc "Raises the `:all` marker to `height`, never lowering it."
  @spec raise_all(non_neg_integer()) :: non_neg_integer()
  def raise_all(height), do: raise_max(@all, height)

  @doc "Raises the marker floor to `height`, never lowering it."
  @spec raise_marker_floor(non_neg_integer()) :: non_neg_integer()
  def raise_marker_floor(height), do: raise_max(@floor, height)

  @doc "The next insertion sequence number. Strictly increasing, never reused."
  @spec next_seq() :: pos_integer()
  def next_seq, do: :atomics.add_get(ref(), @seq, 1)

  @doc "Bumps the generation, making every stored row unreachable. Returns the new one."
  @spec bump_gen() :: non_neg_integer()
  def bump_gen, do: :atomics.add_get(ref(), @gen, 1)

  # --- Lifecycle ---

  @doc false
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    Enum.each(all(), &create/1)
    :persistent_term.put(@atomics_key, :atomics.new(@size, signed: true))
    {:ok, :ok}
  end

  @doc false
  @spec reset!() :: :ok
  def reset! do
    Enum.each(all(), &:ets.delete_all_objects/1)
    Enum.each(1..@size, &:atomics.put(ref(), &1, 0))
  end

  # --- Private ---

  defp create(@frontier_index), do: :ets.new(@frontier_index, [:ordered_set | concurrency()])
  defp create(@exact), do: :ets.new(@exact, [:ordered_set | concurrency()])
  defp create(@waiters), do: :ets.new(@waiters, [:duplicate_bag | concurrency()])
  defp create(name), do: :ets.new(name, [:set | concurrency()])

  defp concurrency,
    do: [:named_table, :public, read_concurrency: true, write_concurrency: true]

  defp ref, do: :persistent_term.get(@atomics_key)

  defp get(index), do: :atomics.get(ref(), index)

  defp raise_max(index, value) do
    ref = ref()
    raise_max(ref, index, value, :atomics.get(ref, index))
  end

  defp raise_max(_ref, _index, value, current) when value <= current, do: current

  defp raise_max(ref, index, value, current) do
    case :atomics.compare_exchange(ref, index, current, value) do
      :ok -> value
      actual -> raise_max(ref, index, value, actual)
    end
  end
end
