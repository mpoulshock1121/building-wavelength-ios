# ci/

`bootstrap.sh` copies `workflows/` to `.github/workflows/` and `scripts/` to `scripts/ci/` in your app.

Principle: **a guard that cannot run is a failed guard.** Missing secrets fail the job with the names of what is missing (never values). The one escape hatch is the visible repository variable `DB_GUARDS=off`, which prints a warning on every run.

Set these once: repo secrets `EXPO_TOKEN`, `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF`, `SUPABASE_DB_URL`. Store the App Store Connect API key in EAS credentials (a human step), so submission is non-interactive.

Edit `scripts/ci/check-rls.sql` so the table list matches your schema. Start `advisors-baseline.json` empty.
