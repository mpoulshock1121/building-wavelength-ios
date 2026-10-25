# Deploy functions from repo files and prove parity afterward

**Rule:** When deploying a serverless function through a bridge instead of the CLI, bundle the current repo files for the whole import closure at the commit being deployed. Never copy files from the live function or rebuild them from memory. After deploying, re-fetch and compare every file byte for byte (sha256 or diff) against `git show <commit>:<path>`; redeploy on any mismatch before recording the deploy anywhere. Always pass the JWT-verification setting explicitly.

**Why:** A function was deployed with a shared helper copied from the previous live bundle. It was a months-old version missing a later export. Harmless at runtime there, but repo and live silently diverged. A redeploy that omits the JWT setting can flip a public or cron-triggered function to require a token and return 401 before its own secret check runs.

**How to apply:** List the import closure (grep imports recursively), pass those exact repo files, deploy, re-fetch, compare, then record.
