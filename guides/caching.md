# Caching

## Model

Every read has a height. There is no read at "whatever the node currently
has" — a read without `height:` is served at the library's own head, and a
read with `height:` is served at that exact height. The library owns the
head; the consumer only tells it when a new height exists.

Four stores back this:

- **Head** — the highest height the library has applied. Reads without
  `height:` resolve to it once per request.
- **Frontier** — state as of the head. An entry carries over across blocks
  until one of its sources changes, so a block that touches nothing a read
  depends on costs that read nothing.
- **Exact** — immutable facts keyed by height, pruned from the least-recently-inserted height
  once `retention` distinct heights are held.
- **Identity** — height-independent, cached forever (e.g. denom metadata).

There are no TTLs and no library-owned live processes. A TTL is a guess at
how long a value stays valid; this library instead tracks exactly which
on-chain sources changed a value, so entries expire on a real event, not a
timer. The ETS tables are owned by a passive table-owner process started by
`rujira_ex`'s own application; `advance/1` itself runs in the caller's
process, not in a library-owned worker.

## `Rujira.Node.advance/1`

Called with an integer height or a already-fetched block struct on every new
height (polling, websocket, or indexer):

```elixir
Rujira.Node.advance(height)
Rujira.Node.advance(%Rujira.Thorchain.Block{} = block)  # no refetch
```

- **Gap fill.** If the new height is more than one past the current head, the
  library fetches and applies every intervening block in order, oldest
  first, before the head moves past them.
- **Catch-up reset.** If the gap exceeds `max_catchup`, filling block by
  block is abandoned: the library resets instead — bumps the generation,
  invalidates everything, and jumps the head straight to the target.
- **Stuck-block reset.** If the same block fails to apply `max_block_failures`
  times in a row, the library gives up on filling it and resets to the
  target the same way a catch-up does, logging the failure.
- **Upgrade.** A THORChain `version` event in a block's `BeginBlock`
  invalidates everything as of that block, since an upgrade can change how
  any source is interpreted.
- **No-op.** A height at or below the current head is a no-op. The head
  never moves backwards.
- **Concurrent callers.** Multiple processes may call `advance/1` at once
  (this matters once more than one BEAM node runs against the same chain —
  see below). One caller does the work; the rest wait for it. Either way,
  `:ok` means the head has reached the height that call asked for, so a
  consumer may read heightless straight afterwards and be served the block it
  just pushed. A waiting caller monitors the one doing the work — so a crash
  is taken over at once — and otherwise re-reads the head on a short bounded
  backoff; the caller doing the work publishes nothing, which is what keeps
  the fill path free of a waiter list.
- **Timeout.** A caller that never gets the lock, and whose height the head
  never reaches, gives up with `{:error, :timeout}` after `lock_timeout`. The
  advance itself is not abandoned: the target still holds the height, and
  whoever has the lock is still filling towards it. Because `lock_timeout` is
  also when a lock becomes takeable, reaching this needs a lock that was taken
  no earlier than the wait began — one that only goes stale after the waiter's
  deadline — whether its holder keeps reacquiring through a long catch-up or
  won the race a moment ahead and is slow to finish.

## Reads

A read for a query key depends on a fixed set of sources (a contract
address, a balance, the oracle, …). Whether it refreshes every block or
carries over depends on what it depends on:

| Depends on | Refreshes |
|---|---|
| A specific contract, balance, denom, or the contract registry | Only when that source's last-changed height passes the read's height — otherwise the frontier entry carries over. |
| A denom's metadata not existing (`{:denom_metadata, denom}`) | Only when a block creates that denom — see below. |
| Anything market-, pool-, oracle-, or THORChain-module-derived (`:per_block` sources) | Every block. These go straight to the exact store at the requested height; a frontier entry would never be valid past the block it was read in. |
| Denom metadata when found, `code_info` when found, `build_address` (identity) | Never — cached forever, independent of height. |

### Denom metadata

The two answers have two lifetimes, so they are cached differently.

Metadata the node **holds** is identity: `x/denom`'s `MsgCreateDenom` is the
only message on a running chain that writes bank denom metadata, and it
refuses a denom that already has some. Metadata is written once and never
rewritten, so it is cached forever.

The node holding **none** is a fact only until the denom is created. It is
cached against `{:denom_metadata, denom}`, which
`Rujira.Cache.Invalidator` raises on any `create_denom` event, from any block
stage, matching `new_token_denom` against the denom by plain string equality —
the event's value is the bank store's own key, byte for byte. So
`{:error, :not_found}` is served from cache until, and exactly until, a block
creates the denom.

Denom metadata is read at the node's latest and a caller's `:height` is
ignored, so the absence is anchored at the head rather than at the caller's
height. That is sound because creation is monotonic: a denom the node's latest
does not know was not created at or before the head either. Before the first
`advance/1` there is no head to anchor it to, so the absence is not cached at
all — the lookup still answers, it just re-reads the node.

> **Latent risk.** `rujira-rs` defines `/thorchain.denom.v1.MsgSetMetadata`,
> which THORChain does not register today, so nothing can send it. If
> THORChain ever adds it, it becomes a second write path — one that also
> changes metadata that already exists — and its event has to join this rule,
> with metadata-when-found moving off identity.

## Errors

A failed fetch is never stored. It is handed to every caller waiting on that
read, and the next read tries again — a transient node error does not become
a permanent cached failure. A domain `:not_found` is different: it is a fact
about chain state, not a failure of the read, so it is cached like any other
value (subject to the same source-tracked invalidation as a successful
read).

## Configuration

```elixir
config :rujira_ex, Rujira.Cache,
  retention: 100,
  max_catchup: 100,
  frontier_max_rows: 100_000,
  max_markers: 100_000,
  sweep_per_block: 1_000,
  lock_timeout: 30_000,
  max_block_failures: 3
```

| Key | Default | Meaning |
|---|---|---|
| `retention` | `100` | Distinct heights kept in the exact store; the least-recently-inserted height is dropped when this limit is reached. |
| `max_catchup` | `100` | Largest gap `advance/1` will fill block by block before resetting instead. |
| `frontier_max_rows` | `100_000` | Frontier rows kept before the sweep evicts by oldest `as_of`. |
| `max_markers` | `100_000` | Marker-table rows kept before the sweep collapses the table to the frontier's oldest `as_of`. |
| `sweep_per_block` | `1_000` | Bound on how many frontier rows `advance/1` sweeps per block it applies. |
| `lock_timeout` | `30_000` | How long, in ms, an `advance/1` lock may be held before another caller may take it over. |
| `max_block_failures` | `3` | Consecutive failures to apply the same block before `advance/1` resets to the target. |

## Telemetry

`rujira_ex` emits four `:telemetry` events. Attach to them with
`Rujira.Cache.Telemetry.events/0`, or to one at a time:

```elixir
:telemetry.attach_many(
  "rujira-cache",
  Rujira.Cache.Telemetry.events(),
  &MyApp.Metrics.handle/4,
  nil
)
```

Every `duration` is in `System.monotonic_time/0`'s native unit — pass it
through `System.convert_time_unit(duration, :native, :millisecond)`.

| Event | Measurements | Metadata |
|---|---|---|
| `[:rujira, :cache, :fetch]` | `duration` — serving the read, store lookup included | `store` (`:frontier`/`:exact`/`:identity`), `result` (`:hit`/`:miss`/`:bypass`/`:error`), `module` and `function` of the query key |
| `[:rujira, :cache, :advance]` | `from`, `to` — the head either side of the fill; `blocks` applied; `duration` | none |
| `[:rujira, :cache, :reset]` | `from`, `to` | `reason` (`:catchup`/`:stuck_block`/`:upgrade`/`:invalidate_all`) |
| `[:rujira, :cache, :sweep]` | `invalid`, `frontier_cap`, `marker_pin`, `markers_dropped`, `exact_heights_pruned` — rows evicted, by cause; `frontier_rows`, `exact_rows`, `identity_rows`, `markers_rows` — sizes after the sweep; `duration` | `head`, `gen` |

- A **fetch** is emitted once per `Rujira.Cache.fetch/4`, under the store that
  actually served it: a read at a height the frontier cannot serve is reported
  under `:exact`, not twice. `result: :miss` covers joining a node read already
  in flight as well as running one; `result: :bypass` is a node read whose
  value was served without being stored. The query key's *arguments* are
  deliberately not in the metadata — they carry addresses and denoms, which
  would give the metric the cardinality of the chain.
- An **advance** is emitted by the caller that took the lock and filled. A
  caller that waited on another emits nothing of its own; the fill it waited
  for emits.
- A **reset** is emitted wherever everything is invalidated at once, alongside
  a `Logger.warning`. `from` and `to` are equal for `invalidate_all/0`, which
  does not move the head.
- A **sweep** is emitted once per `Rujira.Cache.Store.sweep/2` run — once per
  block `advance/1` applies. `exact_heights_pruned` counts the exact store's
  own insert-time pruning, which runs off the sweep's cadence: it is held in a
  counter and read (and reset) by the next sweep, rather than emitted on every
  insert.

## Testing against the cache

A heightless read is `{:error, :no_head}` until something calls `advance/1`, so
a consumer's own tests have to put a head in place. `Rujira.Cache.Testing` is
the supported way — the tables themselves are an implementation detail:

```elixir
defmodule MyApp.SomeTest do
  # The head and the stores are global.
  use ExUnit.Case, async: false

  setup do
    Rujira.Cache.Testing.reset!()
    Rujira.Cache.Testing.set_head(1_000_000)
    on_exit(&Rujira.Cache.Testing.reset!/0)
  end
end
```

- `set_head/1` moves the head with no node fetch, by advancing an empty block
  at that height. Only that one height is handed over, so jumping more than one
  block above the current head still fetches the ones in between — set the head
  from an empty cache, or one height at a time.
- `reset!/0` empties every store and leaves no head at all, which is also what
  a test asserting `{:error, :no_head}` needs.

## Multiple BEAM nodes

The cache is per-node ETS, not shared. Each BEAM node in a cluster needs its
own caller driving `advance/1` — there is no cross-node propagation of the
head or its invalidations.

## `Rujira.Cache.invalidate_all/0`

Drops every cached entry by bumping the generation, same as a catch-up or
stuck-block reset. It exists as an escape hatch for cases `advance/1`'s
source tracking cannot see (a config change, a manual data fix on the node
side) — reach for it only when nothing else applies; ordinary invalidation
is `advance/1`'s job.

## `Rujira.Cache.pin/1`

Every public, `opts`-taking entry point — a facade function and a resource
module alike — resolves its height once with `Rujira.Cache.pin/1`:

```elixir
def list_pairs(opts \\ []) do
  with {:ok, opts} <- Rujira.Cache.pin(opts) do
    # every nested read below here receives `opts` with `height:` already set
  end
end
```

`pin/1` returns `{:ok, opts_with_height}` — `opts` with `height: h` put back
in, `h` being whatever `opts` already carried or, absent that, the head — or
`{:error, :no_head | :invalid_height}`. The pinned `opts` then travels down
through every nested call, including a `Rujira.Enum` fan-out, so a whole
composite read is served at one height even if the head moves underneath it
mid-request. Pinning `opts` that already carry a height is a no-op, so a
nested entry point may call `pin/1` again without changing the height in
flight.

Library authors: call `pin/1` at the top of every function that accepts
`opts` and performs a cached read, before any nested call, rather than
threading `opts[:height]` by hand or resolving the head more than once.

### Fan-out concurrency

`opts[:fan_out]` bounds one fan-out's own `max_concurrency` - see
`Rujira.Enum`. It does not bound the total number of reads in flight at once:
a fan-out nested inside another multiplies, since the outer's `opts` (and
whatever `:fan_out` it carries) is what the inner fan-out reads too. `Fin`'s
`Range.list_all/2`, for instance, fans out over pairs and, per pair, over
that pair's own ranges - `max_concurrency` pairs at once, each running its own
`max_concurrency`-wide read.

The library places no ceiling above that. A consumer that wants one, across
every fan-out and every direct read together, sizes it at the edges it
controls: the `Rujira.Node`/gRPC connection pool a query ultimately runs
through, and, per call, `opts[:fan_out][:max_concurrency]`.

## Absent entities

Whether a domain "not found" is cached as a fact or returned as an
uncached error depends on whether the entity has an empty form:

- A **staking account for a never-bonded owner** is an empty account
  (`bonded: 0`, `pending_revenue: 0`), not `{:error, :not_found}` — the
  staking contract never removes accounts, so a missing row means the same
  as a fully unbonded one. This is chain semantics, not a cache default.
- **Credit accounts, orders, and ranges** stay `{:error, :not_found}`: they
  are identified by address or key and have no empty form. They are cached
  as facts (see [Model](#model)) until their contract's event invalidates
  them.

## Why these reads carry over

| Read | Source | Evidence |
|---|---|---|
| Staking account `pending_revenue` | `{:contract, staking}` | Computed from stored `POOL_ACCOUNTS` (rujira-rs `account_pool.rs:63`) using `(sum - account.sum_snapshot) x amount`; only the staking `status` query reads the bank balance and also carries `{:balance, pool}`. |
| FIN dynamic ranges | `{:contract, fin}` | Range query handlers take only storage with no env or oracle (rujira-fin `ranges/query.rs` on the dynamic-range branch); the struct exposes only the stored `aep`. |
| Revenue `status` | `{:contract, revenue}` | Reads `Action::last(deps.storage)` (rujira-revenue `src/contract.rs:201-203`). |
| ThorchainSwap `markets` / `vaults` | `{:contract, thorchain-swap}` | Storage ranges over `MARKETS` / `VAULTS` (rujira-thorchain-swap `src/contract.rs:257-273`); only `quote` reads the vault through the querier and is refreshed every block. |

Each of these reads depends on a single contract; the `{:contract, address}` source is complete — no oracle, environment, or per-block dependency lies hidden in its implementation.

## Why configs are not reused across backfilled heights

With blocks pushed in order, the frontier already carries every config forward until an event from its contract changes it. Keying a config by code id would be wrong, because an `update_config` execute changes the config without changing its code. Heights read outside the pushed sequence (backfill) have no change history, so they are cached per exact height only.
