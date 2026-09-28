defmodule Rujira.Cache do
  @moduledoc """
  The library's cache. Every read has a height, and the library owns the head.

  The consumer implements `Rujira.Node` and calls `Rujira.Node.advance/1` on
  every new height. This module fetches what changed, invalidates it, and moves
  the head. A read without `height:` is served at that head - not at the node's
  tip - and before the first `advance/1` it is `{:error, :no_head}`, so a
  consumer that forgot to wire it up is told, rather than quietly served
  something stale.

  ## Stores

    * **Frontier** - state as of the head. An entry carries over to later
      blocks until one of the sources it was built from changes.
    * **Exact** - immutable facts keyed by height, pruned once `retention`
      distinct heights are held.
    * **Identity** - height-independent facts, kept until the generation
      changes.

  Errors are never stored, and a failed fetch hands its error to every caller
  waiting on it. A domain `:not_found` is a fact, not an error.

  ## Sources

  A read declares what would change its answer. The block's events decide what
  actually did - see `Rujira.Cache.Invalidator`.

  | Source | Changed by |
  |---|---|
  | `{:contract, address}` | any event of that contract |
  | `:contract_registry` | `instantiate`, `migrate`, `store_code` |
  | `{:balance, address}` | that address spending or receiving coins |
  | `{:denom_transfers, denom}` | any transfer of that denom |
  | `:per_block` | every block. State with no event of its own - the oracle, mimir, pools, nodes, the network |
  | `:all` | an upgrade block, a reset, `invalidate_all/0` |

  A `:per_block` read goes straight to the exact store at its height: it is
  valid at that height and no other, so carrying it in the frontier would cost
  one overwrite and one sweep per block for no reuse.

  `sources` may also be a function of the value, for a read whose sources are
  only known from the result - a list's members, say - or `:identity`.

  ## Height

  `pin/1` resolves the height once, at the public entry point, and puts it
  back into `opts` as `height: h`. It travels down through
  `opts` and never through the process dictionary, so a nested read and a
  `Rujira.Enum` fan-out inherit it and the whole composite is read at one
  height, even if the head moves underneath it.

  ## Configuration

      config :rujira_ex, Rujira.Cache,
        retention: 100,
        max_catchup: 100,
        frontier_max_rows: 100_000,
        max_markers: 100_000,
        sweep_per_block: 1_000,
        lock_timeout: 30_000,
        max_block_failures: 3

    * `retention` - how many distinct heights the exact store holds. The
      oldest-inserted height is dropped when a new one arrives over the limit.
    * `max_catchup` - how far behind the target the head may fall before
      `advance/1` resets to the target instead of filling block by block.
      Filling costs one block fetch each; a reset costs nothing and only makes
      the cache colder.
    * `frontier_max_rows` - the frontier's row cap. Over it, the sweep evicts
      by oldest `as_of`. A cold but valid row - a balance read once and never
      touched again - is never invalidated, so without a cap the frontier grows
      with the number of distinct addresses ever queried.
    * `max_markers` - the marker table's row cap. Over it, the marker floor is
      raised to the frontier's oldest `as_of` and every marker at or below it
      is dropped. Nothing that was recorded is lost: every source is read as
      having changed at the floor, so a row older than it is invalid.
    * `sweep_per_block` - how many frontier rows one block's sweep visits.
    * `lock_timeout` - how long, in ms, an `advance/1` lock may be held before
      another caller takes it over. Takeover is safe because the head is
      written with CAS-max and markers are only ever raised.
    * `max_block_failures` - how many consecutive failures of the same block
      `advance/1` accepts before resetting to the target rather than holding
      the head - and every heightless read - at a stale height.

  ## Telemetry

  Three `:telemetry` events, each executed in the calling process. Every
  duration is in `System.monotonic_time/0`'s native unit -
  `System.convert_time_unit/3` turns one into milliseconds. Nothing here can
  raise into a read: see `Rujira.Cache.Telemetry`, whose `events/0` lists all
  three for a consumer attaching to them at once.

  ### `[:rujira, :cache, :fetch]`

  One per `fetch/4`, once it has resolved.

  | | Key | Is |
  |---|---|---|
  | Measurements | `duration` | How long serving the read took, the store lookup included |
  | Metadata | `store` | `:frontier`, `:exact` or `:identity` - which store served it, or would have filed it |
  | | `result` | `:hit` - served from the store; `:miss` - a node read ran, or joined one already in flight; `:error` - it failed, and nothing was stored |
  | | `module`, `function` | The query key's module and function. Its arguments are left out: they carry addresses and denoms, which would give the metric the cardinality of the chain. Both `nil` for a key that is not `{module, function, args}` |

  A read at a height the frontier cannot serve is reported once, under
  `:exact` - the store it is actually served from - not twice.

  ### `[:rujira, :cache, :advance]`

  One per `Rujira.Node.advance/1` that took the lock and filled. A caller that
  waited on another's fill emits nothing; the fill it waited for emits.

  | | Key | Is |
  |---|---|---|
  | Measurements | `from`, `to` | The head before and after the fill |
  | | `blocks` | How many blocks were applied - `0` for a reset, and for the first `advance/1` of all |
  | | `duration` | How long the fill took |
  | Metadata | | None |

  ### `[:rujira, :cache, :reset]`

  One per invalidation of everything, with a `Logger.warning` beside it.

  | | Key | Is |
  |---|---|---|
  | Measurements | `from`, `to` | The head before and after. Equal for `invalidate_all/0`, which does not move it |
  | Metadata | `reason` | `:catchup`, `:stuck_block`, `:upgrade` or `:invalidate_all` - see `Rujira.Cache.Advance` |

  ## Testing

  `Rujira.Cache.Testing` puts a head in place, and takes it away again, for a
  consumer's own test suite.

  ## Generations

  `invalidate_all/0` bumps a generation that is part of every key. Old rows
  become unreachable at once and are swept later. The generation is read
  together with the head at the start of a read and the result is stored under
  that key, so a fetch that overlapped an invalidation cannot file its
  pre-invalidation value under the new generation.
  """

  alias Rujira.Cache.Advance
  alias Rujira.Cache.Flight
  alias Rujira.Cache.Store
  alias Rujira.Cache.Tables
  alias Rujira.Cache.Telemetry
  alias Rujira.Node

  @typedoc "What a cached read depends on."
  @type source ::
          :per_block
          | :all
          | :contract_registry
          | {:contract, String.t()}
          | {:balance, String.t()}
          | {:denom_transfers, String.t()}

  @typedoc """
  A read's sources: a fixed list, a function of the value for a read whose
  sources are only known from the result, or `:identity` for a value that does
  not depend on the chain's height at all.
  """
  @type sources :: :identity | [source()] | (term() -> [source()])

  @typedoc "Whatever identifies one read. It must not embed the height or the clock."
  @type query_key :: term()

  @type result :: {:ok, term()} | {:error, term()}

  # --- Head ---

  @doc "The head: the last height `Rujira.Node.advance/1` reached, or `nil` before the first."
  @spec head() :: pos_integer() | nil
  def head, do: Tables.head()

  @doc """
  Resolves the height of a read, once.

  `height: h` is taken as given. Without it the read is at the head, and
  before the first `Rujira.Node.advance/1` there is none:
  `{:error, :no_head}`. Callers put the result back into `opts` so every
  nested read is pinned to the same height.
  """
  @spec scope(Node.opts()) :: {:ok, pos_integer()} | {:error, :no_head | :invalid_height}
  def scope(opts) do
    case Keyword.get(opts, :height) do
      nil -> at_head(Tables.head())
      height when is_integer(height) and height >= 1 -> {:ok, height}
      _height -> {:error, :invalid_height}
    end
  end

  @doc """
  Resolves `opts`' height once and puts it back as `height: h`.

  The pinned opts travel down through every nested read, so a whole composite
  is read at one height even if the head moves underneath it. Pinning opts that
  already carry a height is a no-op, so a nested entry point may pin again.
  """
  @spec pin(Node.opts()) :: {:ok, Node.opts()} | {:error, :no_head | :invalid_height}
  def pin(opts) do
    with {:ok, h} <- scope(opts), do: {:ok, Keyword.put(opts, :height, h)}
  end

  @doc """
  Advances the head, returning once it has reached `height`.

  See `Rujira.Node.advance/1`.
  """
  @spec advance(pos_integer() | Rujira.Thorchain.Block.t()) :: :ok | {:error, term()}
  defdelegate advance(height), to: Advance

  @doc """
  Makes every cached value unreachable, at every height.

  The operator's lever for a change no block announces - a runtime config
  change, a metadata correction. It bumps the generation and marks `:all`; it
  does not move the head.
  """
  @spec invalidate_all() :: :ok
  defdelegate invalidate_all(), to: Advance

  # --- Reads ---

  @doc """
  Serves `query_key` from the store that suits its sources, or fetches it once.

  `fun` performs the node read at the height it is given - `nil` for an
  identity read, which has none. Its result is stored only if it succeeded.
  Concurrent callers of the same key at the same height share one fetch, and
  one failure.
  """
  @spec fetch(query_key(), sources(), Node.opts(), (pos_integer() | nil -> result())) :: result()
  def fetch(query_key, :identity, opts, fun),
    do: identity(query_key, Tables.gen(), opts, fun)

  def fetch(query_key, sources, opts, fun) do
    with {:ok, h} <- scope(opts) do
      route(query_key, sources, h, opts, fun)
    end
  end

  @doc false
  @spec reset!() :: :ok
  defdelegate reset!(), to: Rujira.Cache.Testing

  # --- Private ---

  defp at_head(nil), do: {:error, :no_head}
  defp at_head(head), do: {:ok, head}

  defp route(query_key, sources, h, opts, fun) do
    head = Tables.head_at()
    gen = Tables.gen()

    case per_block?(sources) do
      true -> exact(query_key, gen, h, opts, fun)
      false -> frontier(query_key, sources, gen, h, head, opts, fun)
    end
  end

  defp per_block?(sources), do: is_list(sources) and :per_block in sources

  defp identity(query_key, gen, opts, fun) do
    lookup = fn -> Store.identity_lookup(gen, query_key) end

    serve(:identity, query_key, lookup, fn ->
      Flight.run(
        {gen, query_key, :identity},
        opts,
        lookup,
        fn -> fun.(nil) end,
        &Store.identity_put(gen, query_key, &1)
      )
    end)
  end

  defp frontier(query_key, sources, gen, h, head, opts, fun) do
    start = System.monotonic_time()

    case Store.frontier_lookup(gen, query_key, h, head) do
      {:ok, value} -> hit(:frontier, query_key, start, value)
      :miss -> frontier_miss(query_key, sources, gen, h, head, opts, fun, start)
    end
  end

  defp frontier_miss(query_key, sources, gen, h, head, opts, fun, start) when h == head do
    ran(
      :frontier,
      query_key,
      start,
      Flight.run(
        {gen, query_key, h},
        opts,
        fn -> Store.frontier_lookup(gen, query_key, h, Tables.head_at()) end,
        fn -> fun.(h) end,
        &Store.frontier_put(gen, query_key, h, resolve(sources, &1), &1)
      )
    )
  end

  defp frontier_miss(query_key, _sources, gen, h, _head, opts, fun, _start),
    do: exact(query_key, gen, h, opts, fun)

  defp exact(query_key, gen, h, opts, fun) do
    lookup = fn -> Store.exact_lookup(gen, query_key, h) end

    serve(:exact, query_key, lookup, fn ->
      Flight.run(
        {gen, query_key, h},
        opts,
        lookup,
        fn -> fun.(h) end,
        &Store.exact_put(gen, query_key, h, &1)
      )
    end)
  end

  defp resolve(sources, value) when is_function(sources, 1), do: sources.(value)
  defp resolve(sources, _value), do: sources

  # --- Private: telemetry ---

  # The store lookup that opens a read decides whether it was a hit, so the
  # exact and identity paths take it before handing the miss to `Flight`,
  # which re-reads the store itself. That is one extra ETS lookup on a miss -
  # about to pay for a node read - and none at all on a hit.
  defp serve(store, query_key, lookup, run) do
    start = System.monotonic_time()

    case lookup.() do
      {:ok, value} -> hit(store, query_key, start, value)
      :miss -> ran(store, query_key, start, run.())
    end
  end

  defp hit(store, query_key, start, value) do
    Telemetry.fetch(store, :hit, query_key, start)
    {:ok, value}
  end

  defp ran(store, query_key, start, result) do
    Telemetry.fetch(store, outcome(result), query_key, start)
    result
  end

  defp outcome({:ok, _value}), do: :miss
  defp outcome({:error, _reason}), do: :error
end
