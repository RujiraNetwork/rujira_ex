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
  see below). One caller does the work; the rest return `:ok` immediately.
  That `:ok` means "the advance to this height is scheduled", not "applied,"
  so a caller that needs the result to be visible before proceeding — an
  indexer, for instance — must still pass `height:` on its own reads rather
  than assume `advance/1` returning is enough.

## Reads

A read for a query key depends on a fixed set of sources (a contract
address, a balance, the oracle, …). Whether it refreshes every block or
carries over depends on what it depends on:

| Depends on | Refreshes |
|---|---|
| A specific contract, balance, denom, or the contract registry | Only when that source's last-changed height passes the read's height — otherwise the frontier entry carries over. |
| Anything market-, pool-, oracle-, or THORChain-module-derived (`:per_block` sources) | Every block. These go straight to the exact store at the requested height; a frontier entry would never be valid past the block it was read in. |
| Denom metadata, `code_info` when found, `build_address` (identity) | Never — cached forever, independent of height. |

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
