# 02. Build and verify

## The chain
Per slice: `implementer -> verifier -> reviewer -> closer -> retro`. Each is a separate subagent with a narrow brief and a fresh context. The lead agent coordinates and writes the final receipt.

| Role | Does | Evidence it must produce |
| --- | --- | --- |
| implementer | Builds the slice, runs focused checks while working | Changed files, commands run, assumptions |
| verifier | Re-runs type-check, lint, tests, build; walks the acceptance criteria | Exact commands, exit codes, PASS/FAIL per criterion |
| reviewer | Independent look for security, correctness, drift, reuse | Numbered gaps with file:line, or LGTM with basis |
| closer | Re-runs gates, packages evidence and PR text, lists human steps | Evidence checklist, remaining gaps |
| retro | Turns this run's friction into a rule or a note | New rule + index row, or "none" with basis |

Why verify before review: a reviewer's attention is expensive; spend it on code that already compiles and passes. If review finds gaps, the chain restarts at the implementer. Loops are allowed; the first-occurrence order must still hold.

## Enforcement
`.claude/hooks/gate.sh` runs on three events:
- **Prompt:** starts a gate for engineering prompts (cosmetic edits and pure questions are exempt).
- **Tool use:** records which subagent ran, in what order, and whether a real test/type-check command ran.
- **Stop:** blocks the turn (exit 2) unless all five roles ran in order and the final message has a `GATE RECEIPT` with a non-empty line for Understand, Implement, Verify, Review, Close, Retro. `Verify:` must name real commands or say `skipped: <reason>`. Two revision cycles, then it stops and reports instead of looping forever.

What the hook proves: the process happened. What it does not prove: that the work is good. That is the verifier's, reviewer's, and CI's job. Never describe the hook as a quality check.

## Evidence rules
- Command output beats paraphrase. Paste exit codes.
- A skipped check is named with a concrete reason or it did not happen.
- Verification credit comes from the command that ran, never from a filename that happens to contain "jest".
- A guard that cannot run is a failed guard, not a passed one (this applies to CI too: see `04-ship-operate.md`).

## Graph versus loop
Ask: does step B need anything step A produces?
- **No, run in parallel (graph):** type-check + lint + test + build; three review lenses on one frozen diff; release gates.
- **Yes, keep serial (pipeline):** the role chain; a migration before the code that queries it.
- **Unknown scope, iterate until dry (loop):** audits and discovery reports. Stop after two consecutive passes that find nothing new, and dedupe against everything ever seen, including rejected findings, or rejected items resurface forever.

For high-risk diffs (auth, payments, deletion, migrations) run `adversarial-review`: three independent lenses (correctness+security, consistency+regression, reuse+simplicity) in parallel, merged into one list.

## Rules as memory
Incident knowledge lives in `.claude/rules/`, indexed in `INDEX.md`. Agents run the index as a checklist before touching a path. A script fails if the index points at a missing file or a rule is unindexed. Nothing injects rules automatically, so the checklist step is in the agent prompts and the script is in CI.
