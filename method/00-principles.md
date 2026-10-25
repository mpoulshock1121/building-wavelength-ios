# 00. Principles

Five rules. Everything else in this repo follows from them.

## 1. Constraints first
An agent given an open goal builds something plausible. An agent given constraints builds something correct. Before any code, write down: who it is for, what it must never do, what it will not do yet, and which steps only a human may take. These go in `SPEC.md` and `CLAUDE.md`, and every agent reads them first.

## 2. Build systems, not features
The unit of work is not "add a toggle". It is the loop that produces toggles reliably: spec, build, verify, review, close, learn. When something goes wrong, fix the loop (a rule, a gate, a check), not only the instance. The Wavelength case study carries four incident rules; each one records a mistake so it is not repeated.

## 3. Gates over trust
"The agent said it works" is not evidence. A gate is a check that a machine runs and that fails closed. Evidence means command output, exit codes, a row-level-security check against the live schema. A gate you cannot see fail is not a gate. Test that yours blocks (`engine/scripts/test-gate.sh` does this for the role chain).

## 4. One order, enforced
`implementer -> verifier -> reviewer -> closer -> retro`. The same order in the hook, the agent prompts, the commands, and the docs. Two orders in two places is how a gate quietly stops meaning anything. The hook enforces it by checking the order subagents actually ran.

## 5. The human owns what and why; the machine owns how
The person building the app decides outcomes, audience, tone, and risk. The agents decide libraries, schemas, and structure, and report in plain language. Anything irreversible or external (money, store review, production data, credentials) stays a human action. See `05-human-gates.md`.

## What this is not
It is not a promise that agents never err. It makes errors loud, early, and cheap: caught at a gate, written into a rule, never repeated.
