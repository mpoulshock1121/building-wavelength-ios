# 06. Failure catalog

Each entry is an incident, generalized. The fix lives in `engine/.claude/rules/` where one exists.

| # | What went wrong | Root cause | Rule / fix |
| --- | --- | --- | --- |
| 1 | A release build was about to ship from a branch missing the commit that fixed a prior store rejection | Branch looked fine; nobody compared to `main` | `branch-freshness.md`; also a preflight gate and a CI step |
| 2 | Sign-in emails stopped arriving for everyone except the account owner | Sender address secret still held the provider's sandbox address; secrets can't be read back | `secrets-are-write-only.md`: hash-compare; add a code guard and flag the secret |
| 3 | A migration call hung; a retry risked a half-applied schema | Tool bridge hung on policy/trigger drops | `migrations-and-mcp.md`: read state, then chunk |
| 4 | A function was deployed with a stale shared helper | Files copied from the live bundle, not the repo | `deploy-parity.md`: bundle repo files, compare bytes after |
| 5 | Correct sign-in codes reported as expired | Link and code shared one single-use secret; scanners consumed it | `auth-email-code-only.md` |
| 6 | Security checks reported green while checking nothing | CI gates skipped silently when secrets were absent | Fail loudly on missing secrets; BLOCKED = FAIL |
| 7 | A rule-matching file pointed at a rule that did not exist | An index with no checker; a doc that listed only some rules | Indexed checklist + `check-rules-index.sh` in CI |
| 8 | Two docs gave the review/verify order in opposite directions | Prose, hook, and rules written at different times | One order everywhere; hook enforces it |
| 9 | Scheduled reports silently stopped | The scheduler was an app on a laptop that was asleep | Hosted scheduler for anything you depend on |
| 10 | A guide described automation that was never built | Plan written as if it were status | Mark aspirational docs deprecated; verify schedules against the live system |
| 11 | Gate state leaked between turns and sessions | One shared state file | State keyed by project and session, cleared each prompt, stored outside the repo |
| 12 | Lists of "what's live" drifted from reality | Docs updated by memory | Verify against the live system before relying on a status table |
| 13 | A feature with a recording clock drifted from audio | Work on the UI thread; two clocks | Lesson lives in the app's own notes (one start clock, heavy work off the main thread). App-specific, so not shipped as an engine rule |
| 14 | A "history" screen with nothing behind it | Read surface built before the write path | Data-source precondition: build storage and write path in the same slice |

## How to add one
Retro writes a rule from `templates/RULE.md` (Rule / Why / How to apply), adds a row to `INDEX.md`, and runs `scripts/check-rules-index.sh`. If an incident taught nothing reusable, it is not a rule.
