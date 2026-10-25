# Match the task to its shape before defaulting to a serial chain

**Rule:** Check the task type below before choosing how to run it.

| Task | Shape | Why |
| --- | --- | --- |
| Build a slice | Serial chain: implementer, verifier, reviewer, closer, retro | Each role needs the previous role's real output. |
| Release preflight | Parallel gates (`release-preflight` workflow) | Gates read nothing from each other. |
| High-risk review (auth, payments, deletion, migrations) | Parallel lenses (`adversarial-review` workflow) | One pass's blind spot is expensive here. |
| Scheduled discovery report | Loop until two consecutive passes find nothing new | Scope unknown up front; dedupe against everything ever seen, including rejected items. |
| Error triage | Phases in order; check independent hypotheses in parallel inside a phase | Root cause depends on observation. |
| Branch sync | Detect, resolve, verify, loop | Verification can send you back. |

**Test:** does step B need anything step A produces? No: run them together. Yes: keep them serial.

**Why:** Independent work run serially wastes wall-clock time; a genuine pipeline forced into parallel just breaks the handoff.
