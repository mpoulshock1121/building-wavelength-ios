---
description: Start a new iOS app from a rough idea. Captures the idea and constraints, then hands off to /spec.
argument-hint: "<one or two sentences describing the app>"
---

Start a new app. The idea: $ARGUMENTS

1. Restate the idea in two plain sentences and ask the human to confirm. Wait.
2. Create `IDEA.md` from the answers to these questions. Ask only the ones the idea leaves open, as plain-language outcome questions:
   - Who is it for, and what do they do in the first minute?
   - What is the one thing it must do well?
   - Do people need accounts? Is anything private between people?
   - Does it need to work offline, send notifications, take payments, or use the camera or location?
   - What must never happen (data loss, public exposure of private content, surprise charges)?
   - Do you already have an Apple Developer account, a store listing name, and a domain?
3. Write the constraints into `IDEA.md` under "Constraints": platform (iOS only for v1), who signs off, budget for services, deadline if any.
4. Run `bash scripts/check-rules-index.sh` to confirm the engine is wired.
5. Tell the human the next step is `/spec`. Do not start building.
