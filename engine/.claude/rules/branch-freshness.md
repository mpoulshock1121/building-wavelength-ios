# Before any release build, prove the branch contains every main commit

**Rule:** Never assume a long-lived branch is current because it has no merge conflict. Before a release build or store submission run:

```
git fetch origin
git log HEAD..origin/main --oneline
git merge-base --is-ancestor origin/main HEAD && echo "up to date" || echo "BEHIND - do not build"
```

If behind, build from `main` with the fix merged on top, not from the stale branch.

**Why:** A real release branch was found missing a commit that fixed a store-review rejection. Building from it would have shipped the rejection reason a second time and cost a full review cycle. `git status` says nothing about freshness against the remote.

**How to apply:** Mandatory immediately before any build command. The `release-preflight` workflow runs it as a gate.
