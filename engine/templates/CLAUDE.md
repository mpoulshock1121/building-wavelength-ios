# <App name> — project reference

Read this first. Keep it under 100 lines. Details go in `CONTEXT.md`.

## What this app is
<One paragraph, plain language.>

## Stack
<Fill from the real repo: Expo + React Native, backend, auth, storage, state, data fetching. One line each.>

## Commands (the only ones that count)
- Type-check: `<command>`
- Lint: `<command>`
- Test: `<command>`
- Build: `<command>`
These are the same commands CI runs.

## How work happens
1. `/spec` produces `SPEC.md`. A human approves it.
2. `/build <slice>` runs implementer, verifier, reviewer, closer, retro, in that order. The hook in `.claude/hooks/gate.sh` blocks the turn until all five ran in order and the receipt is complete.
3. `/ship-prep <version>` runs the release gates in parallel. A human does production database changes and store submission.

## Rules
Before editing a file, run the checklist in `.claude/rules/INDEX.md` and read every matching rule.
Add a rule (and an index row) after any incident. `bash scripts/check-rules-index.sh` must pass.

## Human-only
Store review and submission, store credentials, production secrets, production database changes, auth dashboard settings, spending money.

## Non-negotiables
- Every table has row-level security in the migration that creates it.
- No secret in the client bundle.
- Guards before side effects; every guard states fail-open or fail-closed.
- Dates are formatted from local year/month/day, never from a UTC string.
