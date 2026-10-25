# 01. Idea to spec

The build chain is only as good as the spec it builds against. This is the stage most projects skip, and the one that costs the most later.

## Core loop
1. **Intake (`/new-app`).** Capture the idea in two sentences and confirm them back. Ask only questions that change what gets built, in plain language about outcomes: Who is it for? What is the one thing it must do well? Are there accounts, and is anything private between people? What must never happen?
2. **Constraints.** Platform (iOS first), accounts and privacy, offline, push, payments, camera or location, budget. Write what is out of scope as carefully as what is in.
3. **Spec (`/spec`).** The `spec-writer` agent fills `templates/SPEC.md`: problem, outcome, out-of-scope, constraints, decisions, slices, data model, risks.
4. **Sign-off.** A human sets `Status: approved` and the date. `/build` refuses to run otherwise. Any substantive change resets the status to draft.

## What a good spec contains
- **Slices, thinnest end-to-end first.** Slice 1 is sign in, one write, one read, on a real device. Not "set up the design system".
- **Acceptance criteria a tester can check on a phone.** "Tapping Save puts the new item at the top of the list" is checkable. "Works well" is not.
- **For every data surface: does the data exist, or is it new?** New means storage, a write path, a protected read, and a screen, all in the same slice. A screen that lists history nobody recorded is a lie; state "collection starts now".
- **Security as a sentence per table:** who can read, who can write, in one line. This becomes the row-level-security policy.
- **Human-only steps listed up front,** so nobody is surprised at release.

## Questions: ask or decide?
| Ask the human | Decide yourself |
| --- | --- |
| Audience, outcome, tone, naming | Library, framework, schema shape |
| Anything irreversible or public | Fail-open vs fail-closed |
| Money, data retention promises | File layout, state management |

If the repo can answer it, read the repo. If only the human can answer it, ask the smallest set of questions and wait. If you must proceed on a guess, write the assumption into the spec and the code.

## Failure modes
- Spec written after the code: it describes what exists, not what was wanted.
- Criteria that restate the design ("uses a bottom sheet"). Write behavior, not construction.
- Approval implied by silence. Approval is an explicit edit by the human.
