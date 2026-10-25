---
description: Build one slice of the approved SPEC through the full role chain.
argument-hint: "<slice number or name from SPEC.md>"
---

Build slice: $ARGUMENTS

1. Refuse to start unless `SPEC.md` contains `Status: approved`. Say so plainly and point to `/spec`.
2. Restate the slice and its acceptance criteria to the human in plain words. If the outcome is unclear, ask and end the turn with the exact line `GATE PAUSED - awaiting your answer`.
3. Run the chain with the Task tool, in this exact order, passing each role the slice and the previous role's real output:
   1. `implementer`: builds the slice.
   2. `verifier`: runs checks and walks the acceptance criteria. On FAIL, return to step 1 with its numbered list.
   3. `reviewer`: independent review. On gaps, return to step 1. For auth, payments, deletion, or migrations, run the `adversarial-review` workflow as well.
   4. `closer`: re-runs gates, writes the evidence and PR summary.
   5. `retro`: records rule or memory improvements.
   The revision budget is 2 cycles; then stop and report.
4. Finish with a receipt block that begins `GATE RECEIPT` and has non-empty `Understand:`, `Implement:`, `Verify:`, `Review:`, `Close:`, `Retro:` lines. Plain language, no code or file names for the human-facing lines.
5. Do not commit or push unless asked. List any human-only steps the slice created (production migration, secret, dashboard setting).
