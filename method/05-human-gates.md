# 05. Human gates

The engine automates until a build exists. These stay human, and why.

| Gate | Why it stays human |
| --- | --- |
| Approve the SPEC | Only the owner knows what they want and what is acceptable risk. |
| Store review submission and release timing | External, irreversible, and tied to your account and reputation. |
| Store and build-service credentials | A leaked or misused key outlives the session. Keys are created by a person and stored once. |
| Production secrets (set, rotate) | Agents can set them, but the decision and the value belong to a person. Values cannot be read back. |
| Production database changes | Irreversible without a forward-fix, affects real users. An agent prepares and verifies; a human applies. |
| Auth dashboard settings and email templates | They deploy by hand-paste; bulk pushes can reset redirect allowlists and break sign-in for everyone. |
| Spending money, accepting terms, legal text | Binding. |
| Deleting data | Irreversible. |

## How the engine keeps them human
- The agents' prompts and `/ship-prep` list these steps and stop.
- `RELEASE_CHECKLIST.md` gives every step an owner and a date; the `human-gates` preflight gate fails on an unowned step.
- The build workflow is `workflow_dispatch` only: a person starts it.
- Agents do not commit or push unless asked.

## What a human reviewer still adds
The gates catch process and mechanical error. A human catches "this is not what I meant". Read the plain-language summary the closer produces; if you cannot follow it, the agent has not finished.
