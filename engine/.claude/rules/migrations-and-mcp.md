# Applying migrations through a tool bridge: check state read-only, then chunk

**Rule:** If a migration call through an MCP or API bridge hangs or times out, stop. Do not resend it. Check what landed with read-only queries (does the table exist, which policies, triggers, functions, scheduled jobs exist), then apply the file in small transactional chunks (tables; policies and triggers; functions and grants; schedules), one at a time.

**Why:** One bridge hung for a minute on any statement containing a policy or trigger drop, without the database seeing it. A blind retry could have left a half-applied migration. Read-only checks proved nothing had landed; chunked application then succeeded and a catalog diff matched the file.

**How to apply:**
1. After a hang, run the read-only checks first.
2. Omit `drop ... if exists` lines only if the checks showed the objects are new; otherwise use a path outside the bridge (SQL editor or CLI).
3. Keep the release's required order (schedules only after the functions they call are deployed).
4. Verify the live catalog against the file, then record the migration as applied in your migrations table. Bridge-applied migrations may leave no history row, so the table is the record.
5. Migrations are additive and forward-only. Rollback is a new migration.
