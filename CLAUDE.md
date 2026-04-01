# Rujira Core

Follow the conventions and architecture documented in:
- `guides/conventions.md` — coding style, naming, return values, numeric parsing
- `guides/architecture.md` — protocol structure, event pipeline, data construction, how to add a new protocol

## Verification

All must pass before any commit:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix credo --strict
```
