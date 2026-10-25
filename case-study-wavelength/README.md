# Case study: Wavelength

Wavelength is a social music app for iOS: each week you pick one song, and your people see it. It was built by one non-engineer product manager working with Claude Code. This is what the process actually looked like, including what did not work. (Numbers are approximate and taken from the repository history; identifiers are removed.)

## By the numbers
| | |
| --- | --- |
| Time from first commit in the repository history to latest | about 3 months (mid-July to mid-October 2026) |
| Commits | about 115 |
| App versions shipped through TestFlight / store review | 1.0, 1.0.2, 1.1.0, 1.2.0, 1.3.1 (1.3.0 was replaced before public release) |
| Database migrations | about 66 files, forward-only |
| Server functions | about 35 |
| Unit tests at the September audit | 604 passing, 42 suites |
| Recurring report types | 9 scheduled routines; 18 dated reports in the repo |
| Written incident rules | 4 (plus the parallel/serial decision guide) |

## Timeline
| When | What happened |
| --- | --- |
| Mid-July | Core app, auth with a second factor, row-level-security model, notifications, first store submission prep. Many small feature docs written as spec-like notes per feature. |
| Late July | First store review; an early build was rejected for a store policy gap. Fixed on `main`; a rule about building only from a fresh branch followed. Error monitoring, a sign-in email incident, and the first operating-loop reports. |
| Early August | v1.0 approved; review-only access closed per a teardown doc. 1.0.2 and 1.1.0 (a post-summaries feature). Harness gate bug fixes (state leaking across turns). |
| September | A full code audit turned into a ranked release proposal for 1.2.0, including findings that production had drifted from the repo. |
| October | 1.2.0 (share your pick as a moving video), 1.3.0 (first-week suggestions, replies, Friday recap, 4K shares), 1.3.1 (video smoothing). Two review-cycle fix commits on the 1.3.0 slice. Rules for tool-bridge deploys added the same week they bit. |

## What the process looked like in practice
1. **Idea to spec was informal.** Each feature had a plain-language markdown note at the repo root (tests and scenarios, product intent). There was no template and no approval gate. This is the weakest stage and the one this engine adds (`method/01-idea-to-spec.md`).
2. **Build** ran through five agents: implementer, verifier, reviewer, closer, retro, enforced by a hook that blocked a turn from ending until they had run. The hook enforced an order the written rules contradicted; the engine fixes that.
3. **Verify** was type-check, lint, unit tests, a timezone matrix (week logic is date-sensitive), and an end-to-end suite that ran on demand.
4. **Backend and security** was row-level-security first, with a CI check on the policy pairs and a security-advisor gate against a reviewed baseline.
5. **Ship** was a human-triggered CI workflow to TestFlight with managed signing; submission stayed manual.
6. **Operate** was a set of scheduled analysis routines plus database cron jobs for product behavior.

## What worked
- **Gates that fail closed.** Once the chain was enforced, "forgot to verify" stopped happening.
- **Rules from incidents.** Each of the four rules maps to a real near-miss. Short (Rule / Why / How to apply) and readable by a non-engineer.
- **Audits turned into ranked proposals.** The September audit compared the repo to production and to product numbers, and ranked fixes against retention rather than taste.
- **Keeping the human on the human steps.** Store credentials, production changes, and submission never moved to an agent.
- **Plain-language receipts** meant the owner could follow what changed without reading code.

## What failed or was thin
- **No spec gate.** Specs were notes, not contracts.
- **A rule index that rotted.** The path-to-rule file pointed to a rule that was never written, and the doc listing rules was stale. Nothing checked it. (Engine fix: indexed checklist plus a script.)
- **Two orders.** The hook enforced implement, verify, review; a rules doc said review, verify. (Engine fix: one order everywhere.)
- **Security checks that skipped silently.** The CI database guards printed a notice and passed when secrets were absent. (Engine fix: fail loudly; explicit opt-out only.)
- **Reports tied to a laptop.** Scheduled routines only ran when the app was open. Operating docs described a more automated system than existed until they were re-verified against the live scheduler. (Engine guidance: hosted scheduler.)
- **Docs that outlived reality.** Two planning docs for automation that was never built stayed in the tree until marked deprecated.
- **Production drift.** The audit found server behavior that existed only in production. Verify live state against the repo before a release.

## Lessons that generalize
1. Write the spec before the code, and make approval an explicit act.
2. Put the same order in the hook and the prose.
3. Make every guard fail loudly.
4. Run what you depend on somewhere that does not sleep.
5. Treat docs as claims to verify.
