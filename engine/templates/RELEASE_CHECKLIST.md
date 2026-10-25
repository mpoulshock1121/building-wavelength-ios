# Release checklist: v<version>

Gates 1-6 are run by `/ship-prep` (the `release-preflight` workflow). Any FAIL or BLOCKED stops the release.

## Automated gates
- [ ] 1. branch-freshness: `origin/main` is an ancestor of the release commit
- [ ] 2. version: app version and build number both higher than the last release
- [ ] 3. tests: type-check, lint, tests all exit 0
- [ ] 4. db-guards: security advisors clean against baseline; row-level-security check passes
- [ ] 5. secrets-present: all names below set in CI and in the store build environment
- [ ] 6. human-gates: every item below has an owner and a date

## Secret names that must exist (names only, never values)
- CI: `EXPO_TOKEN`, `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF`, `SUPABASE_DB_URL`
- Build environment: `<public client config names>`
- Server: `<function secret names>`

## Human-only steps
| Step | Owner | Date | Done |
| --- | --- | --- | --- |
| Apply production database changes (migrations), then verify against the files | | | [ ] |
| Set or rotate production secrets | | | [ ] |
| Auth dashboard settings and email templates pasted and test email read | | | [ ] |
| Store listing text, screenshots, privacy answers | | | [ ] |
| Start the build from the CI Actions tab | | | [ ] |
| Submit for review | | | [ ] |
| Release timing | | | [ ] |

## Rollback
Client: ship a new build (no instant rollback; keep the previous build number handy). Database: forward-fix migration only. Functions: redeploy the previous version from the repo.
