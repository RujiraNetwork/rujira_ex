# Contributing to rujira_ex

Thanks for working on the Rujira domain library. This document covers setup, conventions, verification, and the release flow.

## Repository

- Source: <https://github.com/RujiraNetwork/rujira_ex>
- Hex package: `rujira_ex`
- License: MIT

## Setup

```sh
mix deps.get
mix compile
```

Requires Elixir `~> 1.18` (built-in `JSON`) and Erlang/OTP 26+.

## Conventions

Two documents are required reading before sending a PR:

- [`guides/conventions.md`](guides/conventions.md) — naming, return values, error atoms, numeric parsing, struct defaults
- [`guides/architecture.md`](guides/architecture.md) — protocol module shape, event pipeline, adding a new protocol

## Branches and commits

Commit messages follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):

- Format: `type(scope): description` on a single line. Use `type(scope)!: …` for breaking changes.
- Allowed `type`s: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`.
- `scope` is **required** in this project (the spec makes it optional) and names the area being changed: `core`, `deps`, `fin`, `thorchain`, `events`, etc.

Branch names mirror the commit shape: `type/scope-short-desc` (e.g. `feat/fin-range-pricing`, `fix/contracts-spec`).

## Verification — all five must pass

Run before opening or updating a PR:

```sh
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix credo --strict
mix dialyzer
```

CI runs the same five on every pull request and on every push to `main`
(`.github/workflows/ci.yml`). A failure on any of them blocks merge.

On top of the five, CI also runs a few checks that need no local discipline:

| Check | Why |
| --- | --- |
| `mix deps.unlock --check-unused` | Catches `mix.lock` entries left behind by a removed dependency. |
| `mix hex.audit` | Flags retired packages and security advisories — this library is published to Hex. Non-blocking while #10 is open. |
| `mix docs` | Build check only; a hard failure here would break a release. |

> **Note:** `mix hex.audit` only reports security advisories on Hex 2.5 and
> later. On older Hex it checks retired packages alone and prints
> `No retired packages found` — a false all-clear. Trust the CI run, not a
> local audit, unless you have checked your Hex version with `mix hex --version`.

## Test coverage

Coverage is measured by [`excoveralls`](https://hex.pm/packages/excoveralls).
All tasks run under `MIX_ENV=test` automatically — `preferred_cli_env` is
already wired in `mix.exs`.

```sh
# Plain summary in the terminal
mix coveralls

# Per-line breakdown for a single module (or partial match)
mix coveralls.detail --filter Rujira.Fin.Events

# Full HTML report — writes to ./cover/excoveralls.html
mix coveralls.html
# then open the file in a browser:
xdg-open cover/excoveralls.html       # Linux
open cover/excoveralls.html           # macOS

# Machine-readable JSON (useful for CI artifacts / diffing)
mix coveralls.json
```

The `cover/` directory is gitignored. Re-run the report any time after
`mix test` — coverage data is regenerated from the same compiled test
binaries.

CI generates the same report on every run. The total percentage and a
per-module breakdown appear in the run's **summary** page, and the full HTML
report is attached to the run as the **`coverage-html`** artifact (retained 14
days) — download it from the bottom of the workflow run page.

### The coverage floor

`coveralls.json` sets a `minimum_coverage` floor. Drop below it and `mix
coveralls` fails:

```
FAILED: Expected minimum coverage of 36%, got 34.1%.
```

This is a **ratchet**. If your PR trips it, add tests — do not lower the floor.
If your PR *raises* coverage, raise the floor to match in the same PR, so the
gain cannot be lost later.

`coveralls.json` at the repo root configures the report. It currently skips
the generated protobuf modules (`lib/cosmos/`, `lib/cosmwasm/`,
`lib/tendermint/`, `lib/thorchain/`) and test support files, so the report
lists only hand-written `lib/rujira/` code. Add a `coverage_options` block
there to set a minimum coverage threshold — see the
[excoveralls README](https://github.com/parroty/excoveralls#configuration)
for the schema.

## Pull requests

- One PR per concern. Splitting is cheap; bundled refactors are expensive to review.
- Title follows the commit format (`type(scope): description`).
- Body explains the **why**. The diff already shows the what.
- Tests cover both the happy path and the error tuple.
- Update `guides/` if you change a documented convention.

## Versioning and releases

The package follows **Semantic Versioning** (<https://semver.org>):

- `MAJOR` — breaking public-API change
- `MINOR` — backwards-compatible feature
- `PATCH` — backwards-compatible fix

The library is in `0.x.y` while the public surface stabilizes. In that range, treat `MINOR` bumps as potentially breaking and pin to `~> 0.x` accordingly.

### Cutting a release

1. Land all PRs targeting the release on `main`.
2. Bump `@version` in `mix.exs`.
3. Update `README.md` and any docs that reference the version.
4. Verify locally:
   ```sh
   mix format --check-formatted
   mix compile --warnings-as-errors
   mix test
   mix credo --strict
   mix dialyzer
   mix hex.build       # confirms the package builds cleanly
   ```
5. Commit: `chore(release): vX.Y.Z`.
6. Tag the commit: `git tag vX.Y.Z && git push origin vX.Y.Z`. The tag must match `@version` in `mix.exs`.
7. Publish to Hex: `mix hex.publish` (requires an authenticated maintainer).
8. Cut a GitHub release from the tag with a short changelog.

Only tagged commits get published. Do not publish from a dirty working tree.

## Adding a dependency

- Justify it in the PR description. "Easier than writing it" is not enough — the runtime cost of every dep is real.
- Prefer single-purpose libraries over kitchen-sink frameworks.
- Pin with `~> MAJOR.MINOR` for stable libs and `~> 0.MINOR` for pre-1.0.
- Dev-only tools (`credo`, `dialyxir`, `ex_doc`) must have `only: [:dev, :test], runtime: false`.

## Reporting bugs

Open a GitHub issue with:

- rujira_ex version
- Elixir / OTP version
- Minimal reproduction (a failing test is ideal)
- Expected vs. actual behavior

## Migration status — consumers

`Rujira.Contracts.get/1` currently supports two protocol-module shapes:

- New: `module.new/1` taking a single `map()` with `"address"` merged in
- Legacy: `module.from_config(address, config)` — fallback for incremental migrators

The legacy path is **temporary** and will be removed once the in-house consumers finish migrating. New code MUST implement `new/1`. The fallback is marked with a `TODO` in `lib/rujira/contracts.ex`.
