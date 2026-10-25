---
description: Produce SPEC.md from IDEA.md and stop for human sign-off. Nothing is built from an unsigned spec.
---

1. If `IDEA.md` is missing, tell the human to run `/new-app` first and stop.
2. Delegate to the `spec-writer` subagent. It fills `SPEC.md` from `templates/SPEC.md` and asks the human any outcome questions it needs.
3. When it returns, present, in plain language: what will be built, the slice list in build order, what is out of scope, and the steps only a human can do.
4. Ask for sign-off. Approval means the human edits `SPEC.md` to `Status: approved` with a date, or tells you to do it after they say "approved" in their own message. Do not approve on their behalf.
5. If they request changes, revise `SPEC.md` and ask again. Each substantive revision resets the status to `draft`.
