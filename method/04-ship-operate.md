# 04. Ship and operate

## Release preflight
`/ship-prep <version>` runs six gates in parallel (none reads another's output):

1. **branch-freshness:** the release branch contains every commit on `main`.
2. **version:** version and build number both increase.
3. **tests:** type-check, lint, tests all exit 0.
4. **db-guards:** security advisors vs baseline; row-level-security check.
5. **secrets-present:** every named secret exists in CI and in the build environment.
6. **human-gates:** every human-only step has an owner and a date.

Each gate reports `PASS`, `FAIL`, or `BLOCKED`. **BLOCKED (a missing secret or login) fails the release like FAIL.** The workflow throws on any non-PASS, including a gate that returned nothing.

## Build and TestFlight
A CI workflow, started by a human from the Actions tab, checks freshness, type-checks, tests, then builds on the cloud build service with remote-managed signing and auto-submits to TestFlight. The store API key is stored once in the build service's credentials. Client config comes from the build service's hosted environment, never from committed files.

Install the TestFlight build on a real device before submitting for review. Keep a per-version test plan: what changed, what to tap, what should happen.

## Submission is human
Store review, listing text, privacy answers, export compliance, and release timing are human actions. The agent prepares the checklist and the text; a person presses the button. A review reject is a loop of its own: read the reason, write a rule if it will recur, fix on `main`, rebuild.

## Rollback
- **Client:** there is no instant rollback; ship a new build, keep the previous build number handy.
- **Database:** forward-fix migration only.
- **Functions:** redeploy the previous version from the repo and prove parity.
Write this down before you need it.

## Operating loops
Recurring analysis (growth digest, engineering health, compliance, performance, incident drill) is valuable and easy to get wrong:
- **Where it runs matters.** A scheduled session on a laptop skips when the laptop sleeps. Use a hosted scheduler (CI cron, the platform's scheduler) for anything you rely on, and treat laptop loops as best-effort.
- **Database jobs** (cron inside the database) run regardless of any laptop. Prefer them for product behavior such as reminders.
- **Write reports to files in the repo,** one per run, dated, so the next run can dedupe against them.
- **Verify the schedule against the live scheduler** before trusting a doc that describes it. Docs drift.
- Retire aspirational docs. A guide describing unbuilt automation is worse than none.

## Review rejects and demo doors
If the store needs a reviewer login, give it a dedicated, time-boxed door and a written teardown step. Do not leave it open between reviews.
