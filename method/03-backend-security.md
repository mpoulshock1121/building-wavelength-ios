# 03. Backend and security

Written from a Supabase + Expo stack. The ideas transfer; the commands are Supabase's.

## Row-level security first
The client talks to the database directly, so the database is the security boundary. Every table gets row-level security in the migration that creates it. For each operation the app performs, there is a policy. A table with security on and no policy is locked, which is safe but broken; a table with security off is public.

Layer protections: a permissive "own rows only" policy, plus restrictive policies for session-level conditions (for example, a second factor must have been completed). The effective rule is all of them AND-ed. Test that both layers exist; losing the permissive one breaks writes, losing the restrictive one opens them.

CI check: a script asserts security is on and policies exist for each user-data table, and a second check runs the platform's security advisor against a reviewed baseline. Both fail when their credentials are missing.

## Migrations
- Additive and forward-only. Rollback is a new migration, never an edited old file.
- Number them, one concern each.
- Apply to a preview or dev project first; then production, by a human.
- After applying, verify the live catalog against the file and record it as applied in one table the repo owns.
- When a tool bridge (an MCP server, an API wrapper) hangs mid-migration, do not resend. Read live state with read-only queries, then apply in small transactional chunks. Rule: `migrations-and-mcp.md`.

## Secrets
- Client config is public by construction: only publishable keys, never service credentials. Anything in the app bundle is readable by anyone.
- Server secrets live in the platform's secret store. You cannot read one back, only compare a hash. Rule: `secrets-are-write-only.md`.
- A code-level guard against a bad secret is a mitigation; record that a human must still fix the secret.
- Production build config comes from the build service's hosted environment variables, not from values committed in config files.

## Functions
- Guards (authentication, authorization, validation) before side effects, always. State fail-open or fail-closed for each guard and default to closed.
- Authorization is not authentication: "logged in" is not "allowed".
- Deploy from repo files and prove parity afterward. Rule: `deploy-parity.md`.
- Webhooks: verify the signature before trusting the body, dedupe by event id, treat the provider as the source of truth.

## Auth email
Send codes, not links, or links, not codes. Both in one email share one single-use secret, and link scanners burn it. Rule: `auth-email-code-only.md`. Auth dashboard settings and email templates are pasted by a human one field at a time; never bulk-push config.

## Test accounts and bypasses
A developer sign-in bypass must be disabled in production by an environment flag that is unset there, and the bypass function must itself refuse to run when the flag is absent. Store-review demo logins are temporary doors: open them for a review, close them after approval, and track their state in a doc.
