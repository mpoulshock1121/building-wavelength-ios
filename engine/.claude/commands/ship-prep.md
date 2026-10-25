---
description: Run parallel release gates and produce a TestFlight-ready build plan. A human does the production steps and the store submission.
argument-hint: "<version, e.g. 1.0.0>"
---

Prepare release: $ARGUMENTS

1. Copy `templates/RELEASE_CHECKLIST.md` to `RELEASE_CHECKLIST.md` for this version if it does not exist.
2. Run the `release-preflight` workflow. It runs all gates in parallel: branch-freshness, version, tests, db-guards, secrets-present, human-gates. Any FAIL or BLOCKED fails the whole release; fix or ask the human to supply the missing prerequisite. Do not proceed around a BLOCKED gate.
3. When all gates are PASS, tell the human, in plain language, what is ready and trigger nothing yourself. The build is started by the human running the TestFlight workflow (`ci/testflight.yml`) from the repository's Actions tab.
4. List the steps that stay human: apply production database changes, set production secrets, store listing and review submission, and release timing. Put an owner and date next to each in `RELEASE_CHECKLIST.md`.
5. Never submit to the App Store, change store credentials, or touch production data.
