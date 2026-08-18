# Rujira

Follow the conventions and architecture documented in:
- `guides/conventions.md` — coding style, naming, return values, numeric parsing
- `guides/architecture.md` — protocol structure, event pipeline, data construction, how to add a new protocol

## Consumers

This library is published to Hex from GitHub (`RujiraNetwork/rujira_ex`), but both
downstream consumers live on GitLab, in two different namespaces:

| Repo | Local clone | Status |
| --- | --- | --- |
| `gitlab.com/team-rujira/analytics` | `../rujira-api-analytics` | **First actual consumer.** The new analytics-api. Exact-pins `rujira_ex` per release on branch `develop`. |
| `gitlab.com/thorchain/rujira-api` | `../rujira-api` | **Not yet a consumer.** Elixir umbrella; migration is prospective. |

**Hex is the release boundary.** Neither consumer can pick up a fix until a version is
cut here and they bump their pin. A fix merged to `main` is not a fix delivered.

**Keep dependency requirements permissive rather than tracking latest.** This library is
consumed from inside umbrellas that pick their own dependency versions. A requirement
that is tighter than necessary here does not protect anyone — it becomes an
`override: true` in their manifest, which silently suppresses Hex's conflict detection
on their side. Prefer widening (`~> 0.9 or ~> 1.0`) over bumping, and keep an upper
bound that excludes the next major.

Before relying on what a consumer requires, check both its declared requirement and its
`mix.lock` — they diverge, and the lock is what actually runs.

> The local clones under `../` are working copies that drift from their remotes.
> `git fetch` before trusting what they show.

## Verification

All must pass before any commit:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix credo --strict
mix dialyzer
```
