# docs/

Proposals and working notes. **Nothing in this directory is published or
normative.** It is excluded from the Hex package (see the `files:` list in
`mix.exs`) and is not built into the ex_doc output.

Documents here describe things that may not exist. A proposal that sketches a
module tree, a mix task, or a service is describing what *could* be built, not
what is there — check the code before relying on any of it. Documents are dated
and carry a status; treat anything marked `Draft` as one person's thinking,
not as a decision the project has made.

Normative documentation lives in [`guides/`](../guides): coding conventions,
architecture, and the event pipeline walkthrough. Those ship with the package,
are linked from the published docs, and are expected to be correct against the
current tree.

## Proposals

Numbered, one file each, never renumbered. A superseded proposal keeps its
number and says in its header what replaced it.

| # | Title | Status |
| --- | --- | --- |
| [0001](proposals/0001-onchain-parity-testing.md) | On-chain ↔ Elixir parity for Rujira CosmWasm contracts | Draft |
