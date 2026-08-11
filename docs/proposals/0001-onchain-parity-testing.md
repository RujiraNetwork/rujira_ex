# Proposal 0001 — On-Chain ↔ Elixir Parity for Rujira CosmWasm Contracts

- **Status:** Draft — not adopted, nothing here is implemented
- **Date:** 2026-05-28
- **Scope:** `rujira_ex` test strategy; proposes a separate `rujira_mock_server`
  repository that does not exist
- **Blocked on:** two questions for the contract team, tracked in
  [#17](https://github.com/RujiraNetwork/rujira_ex/issues/17)

> This document describes a system that has not been built. Repository layouts,
> mix tasks, HTTP endpoints and module names below are proposals, not
> descriptions of the current tree.

A plan for keeping `rujira_ex` (event parsers + resource modules) honest against
the actual deployed Fin / Bow / Ghost / … CosmWasm contracts at
[gitlab.com/thorchain/rujira](https://gitlab.com/thorchain/rujira).

## TL;DR

Static mocks rot silently. The only durable defence is to anchor tests to
**evidence captured from a real chain or a real contract build**, refresh
that evidence on a schedule, and fail the build the moment the evidence
diverges from what `rujira_ex` expects.

We layer five independent checks. Each one alone is insufficient; together
they cover schema drift, encoding drift, semantic drift, and deployment
drift:

| Layer | What it catches | Cost | Cadence |
|---|---|---|---|
| 1. Compile-time schema check | Renamed fields, type changes in `cargo schema` JSON | Cheap | Every PR |
| 2. Golden fixtures from real txs | Encoding drift, new attribute keys, new actions | Cheap once captured | Every PR |
| 3. Mock node fed by indexer | Drift over time; query response shapes | Medium | Nightly resync |
| 4. Live smoke tests | End-to-end gRPC + parsing on the real chain | High (flaky) | Pre-release |
| 5. Code-id / checksum guards | Contract migration on mainnet | Cheap | Continuous |

The "mock server that syncs to on-chain" sits at layer 3. The rest of this
document explains exactly what it does, why it isn't sufficient alone, and
how all five layers wire together.

---

## 1. The Risk Model

Before we design anything, we have to name the failure modes. Each row is a
real way `rujira_ex` can go green-on-CI but red-in-prod.

### 1.1 What can drift

| # | Drift | Example | Where it surfaces |
|---|---|---|---|
| D1 | Event type renamed | `wasm-rujira-fin/trade` → `wasm-rujira-fin/v2/trade` | `Rujira.Fin.Events.parse/1` falls into `:pass`, consumers silently lose data |
| D2 | Action renamed | `range.create` → `range.open` | Dispatch table miss in `lib/rujira/fin/events.ex:38` |
| D3 | Attribute key renamed | `side` → `direction` | `Trade.new/1` falls to `def new(_), do: {:error, :invalid_attrs}` |
| D4 | Attribute value encoding | `offer: "100"` → `offer: "100x/uusd"` or JSON | `Amount.new/1` parses wrong values silently |
| D5 | New attribute added | New `protocol_fee` field on `trade` | We drop the field — *bug only if a consumer needs it* |
| D6 | Required attribute removed | `price` no longer emitted on `trade` | Pattern match in head fails, returns `{:error, :invalid_attrs}` |
| D7 | Query response shape | `pair.config` adds/removes a field | `Pair.new/2` crashes or under-populates |
| D8 | New event action added | `wasm-rujira-fin/match` introduced | Falls into `:pass` — *silent gap* |
| D9 | Contract migration | Same address, new `code_id`, new behaviour | None of D1–D8 alone catches this; everything above can flip overnight |
| D10 | Numeric format | `rate: "1.5"` → `rate: "1500000000000000000"` (18-dec int) | `Math.to_decimal/1` silently produces wrong magnitudes |

The three drifts that *static mocks cannot catch* are **D1, D8, and D10**:
the test fixture is whatever the developer typed when they wrote the test,
so the test stays green regardless of what the chain emits.

### 1.2 Two sources of truth

`rujira_ex` is downstream of two artifacts:

1. **The Rust contract source** at gitlab.com/thorchain/rujira. This is the
   *intent* — schemas (`cargo schema`), event names (string literals in
   `contracts/*/src/contract.rs`), the canonical version tag.
2. **The deployed chain state.** This is the *reality* — `code_id`,
   `code_hash`, the contract addresses listed in
   `Thorchain.Types.Query.Stub.contract_infos/2`, the events those addresses
   actually emit per block.

A robust QA strategy validates against both. The Rust source tells us what
*should* be true; the live chain tells us what *is* true. They must agree.

---

## 2. Defence-in-Depth: The Five Layers

### Layer 1 — Compile-time schema verification

**Goal:** catch D3, D5, D7, D10 the moment the Rust schema changes,
before any test runs.

CosmWasm contracts emit JSON Schemas via `cargo schema`. The Rujira contract
CI publishes a `schema/` directory per contract containing
`raw/execute.json`, `raw/query.json`, `raw/response_to_*.json`, etc.

**Mechanism:**

- Add a `mix rujira.schemas.fetch` task that downloads
  the schemas for a pinned `rujira` git ref (commit SHA, not branch) into
  `priv/schemas/<contract>/<ref>/`.
- Add a `mix rujira.schemas.check` compile-time task that asserts every
  field referenced by a `Resource.new/1` / `Resource.new/2` exists in the
  schema, with a compatible JSON type.
- The "compatible" check is structural — string ↔ string, integer ↔
  Decimal-from-string, etc. — implemented as a small pattern-matcher in
  `lib/mix/tasks/rujira/schemas/check.ex`.
- Pin the ref in `config/config.exs`:
  `config :rujira_ex, rujira_schemas_ref: "abc1234"`. PRs that bump the ref
  must show the resulting diff in `priv/schemas/`.

**What this gives us:** when the contract team renames a field, the *next*
schema fetch fails the build with an exact path:
`priv/schemas/fin/9f3a/raw/response_to_config.json: field "tick_size"
missing, used by Rujira.Fin.Pair.new/2`. The contract team has effectively
broadcast their breaking change to us via the schema file.

**What this does *not* catch:** events. CosmWasm's `cargo schema` does not
emit event schemas (events are stringly-typed by convention). So Layer 1
fully covers queries (D7, D10), partially covers execute messages, and is
silent on events. That's what Layer 2 is for.

### Layer 2 — Golden fixtures from real transactions

**Goal:** catch D1, D2, D3, D4, D6 for events; provide reproducible,
byte-exact test inputs.

For each event action the parsers know about, capture a small set of real
`BlockEvent` payloads from mainnet and commit them as fixtures:

```
test/fixtures/events/
├── fin/
│   ├── trade/
│   │   ├── 0001_base_side.json      # tx 5A2F…, height 19_240_112
│   │   ├── 0002_quote_side.json
│   │   └── 0003_partial_fill.json
│   ├── submit/
│   ├── range.create/
│   └── ...
├── thorchain/
│   ├── swap/
│   └── ...
└── _index.json   # provenance: tx_hash → fixture path
```

Each fixture file is the raw cast event (the `%{type, attributes}` map we'd
feed `Rujira.Events.parse/1`), plus a `_meta` block:

```json
{
  "_meta": {
    "tx_hash": "5A2F...",
    "height": 19240112,
    "block_time": "2026-04-12T11:30:00Z",
    "contract_address": "thor1pair...",
    "code_id": 42,
    "code_hash": "sha256:abcd...",
    "captured_at": "2026-04-13T08:00:00Z",
    "captured_by": "mix rujira.fixtures.capture"
  },
  "type": "wasm-rujira-fin/trade",
  "attributes": { "side": "base", "price": "...", ... }
}
```

**Capture tool:** `mix rujira.fixtures.capture --tx <hash>` and
`mix rujira.fixtures.capture --address <addr> --event trade --limit 5`.
Both use the same gRPC path as production (`Rujira.Node.query/3`) so we
exercise the real wire format.

**Test usage:**

```elixir
defmodule Rujira.Fin.EventsGoldenTest do
  use ExUnit.Case, async: true

  for fixture <- Path.wildcard("test/fixtures/events/fin/**/*.json"),
      not String.ends_with?(fixture, "_index.json") do
    @fixture fixture
    test "parses #{Path.relative_to(fixture, "test/fixtures")}" do
      raw = @fixture |> File.read!() |> Jason.decode!()
      assert {:ok, %Rujira.Fin.Events.Event{} = e} =
               Rujira.Events.parse(%{type: raw["type"], attributes: raw["attributes"]})
      # Snapshot-assert the parsed struct — see "snapshot tests" below
      assert_parsed_matches_snapshot(@fixture, e)
    end
  end
end
```

**Snapshot tests** (a la Jest): the test asserts the parsed struct equals a
committed `<fixture>.parsed.exs` file. Re-snapshot with
`mix rujira.fixtures.snapshot --update`. This means **any change to the
parsed struct shape is visible in code review**, not hidden behind
`assert_match`.

**Why this beats hand-written mocks:** the developer cannot make up
attributes that don't exist. The fixture is a recording of reality. If
mainnet starts emitting a new `protocol_fee` attribute, the next refresh
will surface it in the JSON diff in a PR.

**Refresh policy:** weekly via CI cron — `mix rujira.fixtures.refresh`
re-captures the same `tx_hash`es from the chain (they're immutable, so the
raw payload is stable) plus pulls 1–2 fresh examples per action. A PR is
opened automatically; humans review the diff.

The catch: D8 (new event added) is invisible until a human knows to add a
fixture for it. Layer 3 catches that.

### Layer 3 — Mock node fed by a live indexer (the "mock_server")

**Goal:** catch D8 (silent gaps); decouple test reproducibility from chain
freshness; give us a single source of replayable events.

This is the piece you've been discussing. It sits *between* the chain and
the tests:

```
┌───────────────┐  gRPC + Tendermint WS  ┌────────────────┐
│ Thorchain RPC ├───────────────────────►│  mock_server   │
└───────────────┘                        │  (indexer +    │
                                          │   replay API)  │
                                          └──────┬─────────┘
                                                 │ HTTP / gRPC
                                                 ▼
                                          ┌────────────────┐
                                          │  rujira_ex     │
                                          │  test suite    │
                                          └────────────────┘
```

#### 3.1 Responsibilities

The mock_server is a separate service (not a library; not an umbrella
sub-app), because:

- It has a long-running indexer process with persistent state.
- It outlives any single test run.
- It must be runnable in CI and locally with the same image.
- Its correctness has nothing to do with `rujira_ex`'s correctness — it's
  upstream infrastructure that any future Rujira client (Go, TypeScript)
  can also depend on.

It does five things:

1. **Subscribe** to Tendermint `NewBlock` events from one or more configured
   Thorchain RPC endpoints (mainnet, stagenet, devnet).
2. **Filter** events to the contract addresses listed by
   `contract_infos` for known protocols.
3. **Normalize** each `BlockEvent` into the cast `%{type, attributes}` map
   plus provenance metadata (height, tx_hash, block_time, code_id,
   code_hash).
4. **Persist** the normalized records, deduplicated by
   `(height, tx_hash, msg_index, event_index)`.
5. **Replay** records to test clients via a deterministic HTTP API.

#### 3.2 Storage schema

SQLite per environment (mainnet / stagenet / devnet) — simple, file-based,
fast to copy into CI cache. Single table:

```sql
CREATE TABLE recorded_events (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  network      TEXT    NOT NULL,
  height       INTEGER NOT NULL,
  tx_hash      TEXT,                 -- NULL for begin_block / end_block events
  msg_index    INTEGER,
  event_index  INTEGER NOT NULL,
  type         TEXT    NOT NULL,     -- e.g. "wasm-rujira-fin/trade"
  contract     TEXT,                 -- _contract_address
  code_id      INTEGER,
  code_hash    TEXT,
  block_time   TEXT    NOT NULL,     -- ISO8601
  attributes   TEXT    NOT NULL,     -- JSON
  raw_bytes    BLOB,                 -- original BlockEvent proto, for replay
  captured_at  TEXT    NOT NULL,
  UNIQUE (network, height, tx_hash, msg_index, event_index)
);

CREATE INDEX idx_events_type_contract ON recorded_events (network, type, contract);
CREATE INDEX idx_events_code_id ON recorded_events (network, code_id);
```

Storing `raw_bytes` matters: it lets us feed the test suite the *exact*
proto bytes that came off the chain, so we exercise the full
`Rujira.Events.cast/1` decode, not just the post-cast map.

#### 3.3 Replay API

The test client calls into the mock_server over HTTP. Endpoints:

```
GET  /events                       List events with selectors
GET  /events/:id                   Fetch one event by stable id
GET  /events/sample                One example per (network, type)
GET  /coverage                     Which types we have ≥1 sample of
GET  /code-ids                     Current code_id per protocol per network
GET  /health                       Indexer freshness (last seen height vs tip)
POST /admin/resync                 Force re-index from height (auth required)
```

`/events` selectors:

- `network=mainnet`
- `type=wasm-rujira-fin/trade`
- `contract=thor1...`
- `code_id=42`
- `since_height=…` / `until_height=…`
- `limit=…`
- `seed=<int>` — deterministic sample without committing fixture IDs

**Determinism guarantee:** for a fixed `(network, type, code_id, seed,
limit)` tuple, the response is byte-identical across calls. This is the
contract that makes test runs reproducible.

#### 3.4 Sync controller

Two modes:

- **Tail mode** (default): subscribe to `tm.event='NewBlock'` over WS,
  process each block as it arrives, persist.
- **Backfill mode**: range-fetch historical blocks via `blocks_by_height`.
  Used on first boot and to fill gaps detected by the freshness checker.

A small reconciliation loop runs every N blocks: compare the highest stored
height to the chain tip; if the gap exceeds threshold, trigger backfill.

#### 3.5 Drift detector

The mock_server is also the natural place to run automated drift checks:

- **Unknown action detector:** for any event with `type` starting with
  `wasm-rujira-*`, check whether the action suffix appears in the parser's
  dispatch table for that protocol. The mock_server gets this table from
  `rujira_ex` via a generated manifest (`mix rujira.events.manifest > priv/
  manifest.json`). New unrecognised actions raise an alert.
- **Schema drift detector:** for each `(type, code_id)` pair, fingerprint
  the set of attribute keys observed in the last 1k events. When the
  fingerprint changes, emit a webhook / Slack message.
- **Code-id watcher:** alert whenever a known protocol address points at a
  new `code_id` (D9 — contract migration).

These detectors close the loop on D8 and D9: silent gaps stop being silent.

#### 3.6 Test integration

`rujira_ex` ships a `Rujira.Test.MockServer` client (replacing the current
stub `Rujira.Test.MockNode`) used in two patterns:

**Pattern A — pulled into golden fixtures.** `mix rujira.fixtures.capture`
uses the mock_server's HTTP API rather than the live chain, so fixtures are
deterministic and don't depend on which RPC endpoint the dev hits. This is
the everyday path.

**Pattern B — direct in-test replay.** For integration-style tests that
need many events at once (e.g. testing a stateful consumer across 1000
trades), the test pulls a deterministic batch:

```elixir
defmodule Rujira.Fin.OrderbookStateTest do
  use ExUnit.Case
  alias Rujira.Test.MockServer

  @tag :integration
  test "orderbook state under 1000 real trades" do
    events =
      MockServer.events(
        network: "mainnet",
        type: "wasm-rujira-fin/trade",
        code_id: MockServer.current_code_id("rujira-fin"),
        seed: 17,
        limit: 1000
      )

    state =
      events
      |> Enum.map(&Rujira.Events.parse/1)
      |> Enum.reduce(InitialState.new(), &apply_event/2)

    assert state.total_volume > 0
  end
end
```

CI tags: `@tag :integration` tests run only when `MOCK_SERVER_URL` is set
and the server reports `GET /health` ok. Local devs without network can
still run the regular suite — golden fixtures are the floor; the
mock_server is the ceiling.

#### 3.7 What the mock_server is *not*

- It is **not** a CosmWasm VM. We are not executing contracts. If a test
  needs to know "what would the contract return for input X", that's
  Layer 4 territory.
- It is **not** authoritative for write operations. Execute messages aren't
  replayed; we only observe their *effects* (the events they emit).
- It does **not** replace per-module unit tests. `Trade.new/1` still has
  its own minimal-input unit tests with hand-written maps — those tests
  document the parser contract; goldens test the parser-against-reality.

### Layer 4 — Live smoke tests on a real node

**Goal:** catch query response drift (D7) and full-pipeline regressions
that even goldens miss.

A small suite (≤ 20 tests, gated on `MIX_ENV=integration`) talks to a real
Thorchain RPC and exercises every `Resource.get/1` and `Resource.list/0`
that `rujira_ex` exposes. Pass criteria: each call returns `{:ok, %Struct{}}`
with no `nil` required fields. Run nightly + pre-release; failures are
informational the first time and PR-blocking only after a human triages.

This layer is necessarily slower and flakier — that's why it's gated. But
it's the only place we catch a contract migration whose new query response
adds a required field that we don't read.

### Layer 5 — Code-id / checksum guards in production

**Goal:** detect D9 in production *before* it breaks consumers.

The mock_server already tracks `code_id` per protocol. Two additional
pieces close the loop:

- `rujira_ex` exposes the list of `code_id`s it was tested against —
  `Rujira.Deployments.supported_code_ids/1` — generated from the schemas
  fetched in Layer 1.
- `Rujira.Deployments.contract_infos/0` is wrapped (or instrumented via a
  Telemetry handler) so that whenever it resolves a contract whose
  `code_id` is *not* in the supported set, it emits a
  `[:rujira, :deployments, :unsupported_code_id]` event. The application
  decides whether to log, page, or refuse.

This is not a test — it's a runtime safety net. It belongs in this plan
because without it, a contract migration on mainnet is the failure mode
that bypasses every other layer (until Layer 3's nightly detector catches
it, which can be up to 24 hours late).

---

## 3. Mock Server: Concrete Architecture

This section gets specific enough to start writing code.

### 3.1 Language and shape

Write it in Elixir. Reasons:

- Reuses the existing `Rujira.Node` gRPC plumbing, `Thorchain.Types`
  protobuf module, and the cast/parse pipeline. Zero re-implementation of
  the wire format.
- Phoenix gives us the HTTP API + WS subscribe for free.
- `Ecto` + `ecto_sqlite3` for the persistence layer.
- Tests for the mock_server itself can use `rujira_ex` directly to assert
  parseability of every recorded event.

Repo layout:

```
rujira_mock_server/                 # separate repo, separate semver
├── lib/
│   ├── rujira_mock_server/
│   │   ├── indexer/
│   │   │   ├── supervisor.ex
│   │   │   ├── tail.ex             # WS subscriber
│   │   │   ├── backfill.ex         # range backfiller
│   │   │   └── reconciler.ex       # gap detector
│   │   ├── recorder.ex             # normalize + persist
│   │   ├── drift/
│   │   │   ├── unknown_action.ex
│   │   │   ├── schema.ex
│   │   │   └── code_id.ex
│   │   ├── repo.ex
│   │   ├── events/                 # Ecto schemas
│   │   └── application.ex
│   └── rujira_mock_server_web/
│       ├── router.ex
│       ├── controllers/events_controller.ex
│       └── ...
├── priv/
│   ├── repo/migrations/
│   └── manifest/                   # latest rujira_ex event manifest
├── config/
└── test/
```

### 3.2 Sources

For each `network`, the config block names:

```elixir
config :rujira_mock_server, :networks, %{
  "mainnet" => %{
    grpc: "thornode.ninerealms.com:9090",
    tendermint_rpc: "https://rpc.ninerealms.com",
    tendermint_ws: "wss://rpc.ninerealms.com/websocket",
    omit: []
  },
  "stagenet" => %{...}
}
```

The indexer holds independent state per network. SQLite databases are
separate files (`priv/data/mainnet.db`, …) so they can be archived and
shared independently.

### 3.3 Event capture flow

```
NewBlock WS msg
  │
  ▼
fetch block (Tendermint RPC: block_results)
  │
  ▼
extract begin_block_events ++ end_block_events ++ txs[*].events
  │
  ▼
for each event:
  decode → cast to %{type, attributes}
  attach provenance (height, tx_hash, msg_index, event_index, block_time)
  if type matches `wasm-*`, resolve _contract_address → code_id + code_hash
  upsert into recorded_events (idempotent on UNIQUE constraint)
  │
  ▼
fire drift checks asynchronously (Oban / Task.Supervisor)
```

`code_id` resolution is itself cached and refreshed on `MsgInstantiateContract`
/ `MsgMigrateContract` observed in the same block — exactly the
invalidation hook `Rujira.Deployments.invalidate/0` documents.

### 3.4 Determinism guarantees

The replay API's `seed` parameter selects a stable subset:

```elixir
defp deterministic_sample(network, type, code_id, seed, limit) do
  query =
    from e in RecordedEvent,
      where: e.network == ^network and e.type == ^type,
      where: is_nil(^code_id) or e.code_id == ^code_id,
      order_by: [
        # Stable hash that mixes seed with stable event id
        fragment("substr(?, 1, 16)",
          fragment("hex(?)",
            fragment("? || ?", e.height * e.event_index, ^seed)
          )
        )
      ],
      limit: ^limit

  Repo.all(query)
end
```

The actual implementation should use a CRC over `(id, seed)` — the sketch
above just illustrates that the ordering is a pure function of inputs
plus stored ids. Important: never use `RANDOM()` — that defeats the
whole point of the replay API.

### 3.5 Freshness contract

`GET /health` returns:

```json
{
  "networks": {
    "mainnet": {
      "tip_height": 19240500,
      "indexed_height": 19240498,
      "lag_blocks": 2,
      "lag_seconds": 12,
      "last_event_at": "2026-05-28T07:14:55Z",
      "status": "ok"
    }
  }
}
```

CI test runs require `lag_seconds < 600` or fail with a clear error.
Local devs can run with `--stale-ok` to use the cached SQLite without an
indexer pointed at the chain.

### 3.6 Failure modes and what they mean

| Symptom | Likely cause | Action |
|---|---|---|
| `404 /events?type=...` | Action not yet seen on this network | Lower `since_height`, or wait |
| `health.status = stale` | Indexer is behind the tip | Check RPC endpoint, kick the indexer |
| Drift alert: unknown_action | D8 — chain emits new action | Add sub-event module + dispatch line |
| Drift alert: schema | D3/D4/D5 — attribute set changed | Update parser + capture new fixture |
| Drift alert: code_id | D9 — contract migrated | Re-run schema fetch, audit diffs |

Each alert maps to a concrete code change in `rujira_ex`. That mapping is
the whole reason the mock_server exists.

---

## 4. Why the Mock Server Alone Isn't Enough

You called this out and you're right. To make the rationale explicit:

1. **It can't see what isn't emitted.** If a query response field changes
   shape but no event reflects it, the mock_server learns nothing. → Layers
   1 and 4 cover query/execute shapes.
2. **It's eventually-consistent.** A contract migrated 5 minutes ago hasn't
   yet emitted enough events to fingerprint. → Layer 5's code-id guard
   alerts on the migration itself, not on the consequences.
3. **It's a single point of failure for tests.** If the mock_server is
   down, the test suite degrades. → Goldens (Layer 2) are committed to the
   repo and offline-runnable; they're the floor.
4. **Tests of the mock_server need their own validation.** A bug in the
   indexer that drops `protocol_fee` from every event will silently
   green-light the same bug in `rujira_ex`. → Layer 4's live smoke tests
   bypass the mock_server entirely and talk to the chain directly.

Each layer covers a failure mode the others can't.

---

## 5. CI Integration

```
on: pull_request
jobs:
  unit:               # always — ~30s
    - mix test --exclude integration
    - mix rujira.schemas.check
    - mix format --check-formatted
    - mix credo --strict
    - mix dialyzer

  integration:        # if MOCK_SERVER_URL is set — ~3min
    - mix test --only integration --include integration

on: schedule (nightly)
jobs:
  fixture-refresh:
    - mix rujira.fixtures.refresh
    - if diff: open PR
  smoke:
    - MIX_ENV=integration mix test --only smoke
  drift-report:
    - curl $MOCK_SERVER_URL/drift/report > drift.md
    - if non-empty: post to Slack

on: push (rujira gitlab repo, via webhook to GitHub Actions)
jobs:
  upstream-changed:
    - mix rujira.schemas.fetch --ref $NEW_SHA
    - mix rujira.schemas.check
    - if fail: open issue with diff
```

The "upstream-changed" job is the single most valuable piece of automation:
it tells us within minutes of a contract repo merge whether it breaks
`rujira_ex`.

---

## 6. Phased Implementation

A realistic order, each phase usable independently:

### Phase 1 — Foundations (≈ 2 weeks)

- `mix rujira.schemas.fetch` and `mix rujira.schemas.check` (Layer 1).
- Golden fixture harness: directory layout, capture task, snapshot
  assertions (Layer 2, manual capture only).
- Capture 3–5 fixtures per existing FIN action via mainnet RPC.
- Document the pin (`rujira_schemas_ref`) and the capture workflow in
  `CONTRIBUTING.md`.

**Exit criteria:** PR that intentionally renames `side` in a Trade fixture
fails CI with a clear pointer.

### Phase 2 — Mock server MVP (≈ 3 weeks)

- New repo, Phoenix skeleton, `recorded_events` schema.
- Tail-mode indexer for mainnet only.
- `/events`, `/events/sample`, `/health` endpoints.
- Wire `mix rujira.fixtures.capture` and `mix rujira.fixtures.refresh` to
  hit the mock_server instead of the chain directly.

**Exit criteria:** weekly fixture-refresh PR opens automatically and is
mergeable without manual capture steps.

### Phase 3 — Drift detection (≈ 1 week)

- `mix rujira.events.manifest` task in `rujira_ex` to emit the dispatch
  table as JSON.
- `priv/manifest/` consumed by mock_server's unknown-action detector.
- Schema-fingerprint detector.
- Slack webhook + `/drift/report` endpoint.

**Exit criteria:** the day the contract team ships
`wasm-rujira-fin/some_new_action`, we get a Slack message within 24 hours
naming the action, the contract, and one example tx_hash.

### Phase 4 — Live smoke + code-id guards (≈ 1 week)

- `MIX_ENV=integration` smoke suite: `get/list` for every Resource module.
- `Rujira.Deployments.supported_code_ids/1` generated from Layer 1 schemas.
- Telemetry handler in `rujira_ex` for unsupported `code_id`.

**Exit criteria:** the day a Fin contract is migrated on mainnet, the
runtime emits a telemetry event before the mock_server's nightly cycle
catches it.

### Phase 5 — Hardening (ongoing)

- Backfill historical events back to a sensible cutoff (start of mainnet).
- Add stagenet + devnet networks.
- Generalise the mock_server to non-FIN protocols as `rujira_ex` adds them.
- Add a TypeScript / Go client library to the mock_server, so future
  Rujira clients in other languages can share the same fixtures.

---

## 7. Trade-offs and Decisions Required

These need explicit decisions before implementation starts:

| Decision | Options | Recommendation |
|---|---|---|
| Mock server hosting | Internal Kubernetes / Fly.io / a single VM | Single VM + Litestream backup for SQLite. Cheapest, sufficient. |
| Mock server repo | Same monorepo / separate repo / umbrella sub-app | Separate repo. Different release cadence; usable by non-Elixir clients later. |
| RPC provider | NineRealms / self-hosted node | NineRealms for now; revisit when we have ≥ 2 networks. |
| Schema pin granularity | Branch / tag / commit SHA | Commit SHA. Branches move; tags are skipped sometimes. |
| Fixture network | Mainnet only / mainnet + stagenet | Mainnet only initially. Stagenet fixtures often reflect pre-merge state we shouldn't promise to support. |
| Live-test gating | Always run / `MOCK_SERVER_URL` env / explicit tag | Explicit `:integration` tag + env var. Avoids surprising the local dev. |
| Snapshot library | `assert match?` / `mneme` / homegrown | `mneme` — interactive update flow is great in code review. |

---

## 8. Discovering the Event Surface

How do we know which events a contract emits *in the first place* — without
just asking the contract author? Three independent approaches, none
individually complete; the right answer is a combination.

### 8.1 Static analysis of the Rust source

The contract source at gitlab.com/thorchain/rujira is the authoritative
declaration. CosmWasm events are emitted through cosmwasm-std's `Event` /
`add_attribute` APIs:

```rust
use cosmwasm_std::{Event, Response};

let event = Event::new("rujira-fin/trade")
    .add_attribute("side", side.as_str())
    .add_attribute("price", price.to_string())
    .add_attribute("offer", offer.to_string())
    .add_attribute("bid", bid.to_string());

Ok(Response::new().add_event(event))
```

`wasmd` prefixes the event type with `wasm-` when it records the event in
the tx log, producing `wasm-rujira-fin/trade`. So every event the chain
ever emits corresponds to an `Event::new("…")` literal somewhere in the
Rust source. Discovery is, at its core, a grep problem:

```bash
# All event type names declared in the contracts
rg -nP 'Event::new\("([^"]+)"\)' -or '$1' contracts/

# Attribute keys, with surrounding event context
rg -n 'Event::new|\.add_attribute' contracts/

# Old-style attributes attached directly to Response (legacy convention)
rg -nP 'Response::new\(\).*?\.add_attribute\(\s*"([^"]+)"' contracts/
```

The proper, robust version is a `syn`-based Rust source walker rather than
a regex sweep — string-literal arguments to `Event::new` and
`add_attribute` are trivially recoverable from the AST, including across
intermediate `let` bindings and helper functions. A small Rust binary
checked into the contract repo (or `rujira_ex`'s tools dir) can emit a
machine-readable `events.json`:

```json
{
  "rujira-fin/trade": {
    "required": ["side", "price"],
    "optional": ["rate", "offer", "bid", "ranges"],
    "source": ["contracts/fin/src/execute/trade.rs:142"]
  },
  ...
}
```

Wrap this in `mix rujira.upstream.scan`:

1. Fetch the contract repo at the pinned `rujira_schemas_ref` SHA into a
   cache dir.
2. Run the syn-walker, write `priv/upstream/<sha>/events.json`.
3. Diff against the `rujira_ex` manifest (`mix rujira.events.manifest`).
4. Fail CI on:
   - Event in `events.json` not in our dispatch table → **D8 caught
     statically, before mainnet ever emits it.**
   - Event in our dispatch table not in `events.json` → we're parsing
     something the contract no longer emits.

**Strength:** complete — covers cold paths (admin handlers, emergency
exits, error branches) that the empirical approach will never see.

**Weakness:** depends on convention. If the contract uses a custom builder
macro or constructs event names dynamically (`format!("…")`), the static
walker misses it. The Rujira contracts mostly follow plain-literal
conventions, but a custom macro layer would need its own scanner.

The right long-term move: **ask the contract team to ship `events.json` as
a CI artifact** the same way `cargo schema` ships `schema/`. A `build.rs`
that emits event metadata removes the scanner from the consumer side
entirely; we just fetch and diff. This is a small upstream PR with
outsized value.

### 8.2 Empirical replay (what the mock_server already does)

`tx_search` on Tendermint RPC lets us enumerate every tx that touched a
contract:

```
GET /tx_search?query="wasm._contract_address='thor1pair...'"
                  &per_page=100&page=1&order_by=desc
```

For each tx, the events emitted by that contract are in `tx_result.events`.
Sweep across enough history and the union of observed event types is the
*triggered* event surface. The mock_server's tail indexer plus a one-time
backfill is this approach made operational.

**Strength:** captures real wire format including encoding details (D4,
D10) that static analysis cannot infer. Sees exactly what consumers see.

**Weakness:** only sees what has actually fired. A `withdraw_protocol_fees`
action invoked once a quarter by a treasury multisig may never appear in
a 30-day window. **Empirical replay's blind spot is cold paths.**

### 8.3 Bytecode introspection (last resort)

The compiled contract is a Wasm module on-chain. We can pull it and inspect
it directly:

```bash
# Fetch the compiled bytecode for a given code_id
thornoded query wasm code 42 fin.wasm

# Dump readable string literals
wasm-strings fin.wasm | rg '^(rujira-|wasm-)'

# Or disassemble and look for the host-function calls that emit attributes
wasm-objdump -d fin.wasm | rg -i 'event|attr'

# Or use wasm-tools for structured analysis
wasm-tools print fin.wasm | rg '"rujira-'
```

The string literals passed to `Event::new(…)` are embedded in the module's
data section. `wasm-strings` will recover them — along with error
messages, log strings, panic locations, and every other static string.
Distinguishing event names from noise is heuristic (prefix match on
`rujira-`, length bounds, presence of `/` separator).

**Strength:** works even without source access. Anchored to the exact
`code_id` actually deployed — so this is the canonical way to verify D9
(contract migration) is not telling us a lie.

**Weakness:** noisy. Attribute keys are even harder to pin down because
they're not co-located with their parent event in the binary.

In practice we'd only reach for this:

- To verify the on-chain bytecode matches the source we scanned in §8.1
  (defence against a malicious or buggy build pipeline).
- If a `code_id` ever ends up on-chain without a corresponding tag in the
  contract repo.

### 8.4 What about contract state?

A question that comes up often, so making it explicit: **no, contract state
cannot tell you what events a contract emits.**

CosmWasm state holds the contract's data — orderbook, pair config, range
positions, balances. Events are an *output* of execution: wasmd writes
them to the block's tx results and they never touch the contract's own
storage. Queries like `Rujira.Contracts.query_state_smart/2` return what
the contract chose to expose through its `QueryMsg`; events are not part
of that surface.

A related dead-end: `WasmStdQuery::ContractInfo` returns `code_id`, admin,
label, creator. Useful for D9; useless for events.

The chain *does* keep events — but it keeps them in block results
(`block_results` RPC, the `wasm` index in tx logs), not in contract state.
That's the same data §8.2 indexes; it isn't a contract query.

### 8.5 Recommended approach

Combine §8.1 and §8.2; keep §8.3 as a sanity check.

| Source | Role | Frequency |
|---|---|---|
| Static scan (§8.1) | Canonical list of events the contract *can* emit | On every PR + upstream push |
| Empirical replay (§8.2) | Validation that what's emitted matches what's declared | Continuous via mock_server |
| Bytecode (§8.3) | Confirmation that deployed binary matches scanned source | On every observed `code_id` change |

The three alarms this configuration produces map cleanly to three different
problems:

- **In §8.1 but not in §8.2:** dead code, or a path so cold it hasn't fired
  in our backfill window. Confirm with contract team; if intentional,
  consider whether the test goldens should fake it.
- **In §8.2 but not in §8.1:** the static scanner is incomplete (custom
  macro, dynamic name) — fix the scanner. Or, worse, the deployed binary
  is ahead of the source repo we pinned — fix the pin and re-fetch
  schemas.
- **In §8.1 and §8.2 but inconsistent with §8.3:** the bytecode on-chain
  does not match the source we scanned. This is a serious finding —
  someone deployed a build the contract repo doesn't reflect.

This is the only configuration where the three questions we actually care
about all have answers:

1. *Are we parsing everything we should?* — §8.1 ⊆ dispatch table.
2. *Are we parsing things we shouldn't?* — dispatch table ⊆ §8.1.
3. *Is the deployed binary what we think it is?* — §8.1 ≈ §8.3 for every
   live `code_id`.

A test suite that has access to all three sources has no place left for
silent drift to hide.

---

## 9. Open Questions

The first two are blocking for Phase 1 and are tracked as
[#17](https://github.com/RujiraNetwork/rujira_ex/issues/17); answers belong
there, and this section should be updated to match once they land.

- The Rujira contract repo at gitlab.com/thorchain/rujira — does its CI
  already publish `cargo schema` artifacts? If not, Phase 1 needs a small
  upstream PR adding that to the contract CI before our schema-fetch task
  has anything to fetch. Confirm with the contract team.
- Does the contract team tag releases? If yes, we can pin to release tags
  instead of arbitrary SHAs (decision in §7 changes).
- Is there an existing Thorchain indexer (Midgard?) we can read from instead
  of subscribing to the WS firehose? Would offload event filtering. Worth
  investigating before Phase 2 starts.
- What's the existing telemetry / paging story? Layer 5's
  `unsupported_code_id` event needs a destination.
- Do we need execute-message replay for any consumer? If yes, we'd need a
  separate component (a `wasmd`-driven sandbox), which is much larger than
  this plan covers.

---

## 10. Appendix: The Manifest Format

`mix rujira.events.manifest` emits one file the mock_server consumes:

```json
{
  "generated_at": "2026-05-28T08:00:00Z",
  "rujira_ex_version": "0.0.1",
  "protocols": {
    "rujira-fin": {
      "event_prefix": "wasm-rujira-fin/",
      "actions": {
        "trade": {
          "module": "Elixir.Rujira.Fin.Events.Trade",
          "required_attrs": ["side", "price"],
          "optional_attrs": ["rate", "offer", "bid", "ranges"]
        },
        "submit": {...},
        "range.create": {...}
      }
    },
    "rujira-thorchain": {
      "event_types": ["swap", "transfer", "add_liquidity", ...]
    }
  }
}
```

The manifest is generated by walking the dispatch tables in
`Rujira.Fin.Events`, `Rujira.Thorchain.Events`, etc. — these are already
the canonical sources of truth for what `rujira_ex` recognises. The
mock_server's drift detectors diff observed events against this manifest;
that's how D8 stops being silent.
