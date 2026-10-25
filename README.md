# Building Wavelength — iOS

*Building Wavelength — iOS* is how one product manager shipped a real iOS app with AI agents, without writing the code by hand. This repo turns that into a method and an engine you can run on your own app.

**Who it is for:** non-engineers (founders, PMs, designers) and engineers who want a guardrailed way to build an iOS app with [Claude Code](https://claude.com/claude-code). **What you get:** a written [method](method/00-principles.md) and a drop-in [engine](engine/ci/README.md) (agents, hooks, commands, rules, CI) that enforces it.

**Thesis:** agents are fast and unreliable in the same breath. The fix is not a better prompt; it is a process with gates: a signed-off spec, a fixed chain of roles that must each leave evidence, rules learned from incidents, and humans on the steps that cannot be undone.

Worked example: [Wavelength](case-study-wavelength/README.md), a social music app built in about three months by one product manager.

## The method in one page
1. **Idea to spec.** `/new-app` captures the idea and constraints. `/spec` writes `SPEC.md` (slices, acceptance criteria, security per table, human-only steps). **A human approves it.**
2. **Build, per slice.** `/build 1` runs `implementer -> verifier -> reviewer -> closer -> retro`. A hook blocks the turn until all five ran in that order and the receipt is complete.
3. **Backend and security.** Row-level security in every table's migration. Forward-only migrations. Secrets never in the app. Guards before side effects.
4. **Ship.** `/ship-prep 1.0.0` runs six release gates in parallel; a missing secret counts as a failure. **A human** applies production changes and submits to the store.
5. **Operate.** Recurring reports and rollbacks written down. Scheduled work runs somewhere that does not sleep.
6. **Learn.** Every incident becomes a short rule with an index entry, checked by a script.

Read: [principles](method/00-principles.md), [idea to spec](method/01-idea-to-spec.md), [build and verify](method/02-build-verify.md), [backend and security](method/03-backend-security.md), [ship and operate](method/04-ship-operate.md), [human gates](method/05-human-gates.md), [failure catalog](method/06-failure-catalog.md).

## Quickstart (about 60 seconds)
Requires: Node 20+, git, [Claude Code](https://claude.com/claude-code). Later, for shipping: an Expo account, an Apple Developer account, a Supabase project.

```bash
git clone https://github.com/mpoulshock1121/building-wavelength-ios && cd building-wavelength-ios
bash engine/scripts/bootstrap.sh ~/code/my-app --name "My App"
cd ~/code/my-app && npm install
claude          # then:  /new-app "a one-sentence idea"
```

`bootstrap.sh` scaffolds an Expo app, copies in the engine, and runs two self-checks (rules index, role-chain gate). It never overwrites existing files. Use `--no-scaffold` to install into an app you already have.

## What is in the engine
| Piece | Where |
| --- | --- |
| Seven agents (spec-writer, implementer, verifier, reviewer, closer, retro, release-preflight) | `engine/.claude/agents/` |
| Role-chain gate hook | `engine/.claude/hooks/gate.sh` |
| Slash commands `/new-app /spec /build /ship-prep` | `engine/.claude/commands/` |
| Incident rules with an indexed checklist | `engine/.claude/rules/` |
| Workflows: adversarial review, release preflight | `engine/.claude/workflows/` |
| Templates: CLAUDE.md, CONTEXT.md, SPEC.md, RELEASE_CHECKLIST.md, RULE.md | `engine/templates/` |
| CI: checks, database guards that fail loudly, TestFlight | `engine/ci/` |
| Scripts: bootstrap, gate self-test, rules-index check, scrub check | `engine/scripts/` |

## What it does not do
It does not submit to the App Store, create your accounts, set production secrets, or apply production database changes. Those are human steps by design ([why](method/05-human-gates.md)). It does not make the agents' work correct; it makes skipped steps and silent failures hard.

## Verify your install
Run from the `engine/` folder of this repo (bootstrap runs both checks for you on a new app):
```bash
cd engine
bash scripts/test-gate.sh          # proves the gate blocks bad runs and allows good ones
bash scripts/check-rules-index.sh  # proves the rule index points at real files
```

## License
MIT. See [LICENSE](LICENSE). Copyright (c) 2026 Michael Poulshock.
