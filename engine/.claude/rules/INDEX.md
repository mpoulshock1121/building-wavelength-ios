# Rule index (a checklist you run, not a hook)

Nothing in the harness injects these rules automatically. Agents run this checklist by hand, and a script keeps the index honest.

## Checklist (implementer, reviewer, retro)
1. List the file paths you are about to edit or review.
2. For each path, find every row below whose pattern matches it. A trailing `/**` matches everything under that folder; `*` matches within one name.
3. Read each matching rule file in full before editing. Write "rules read: <names>" in your output.
4. If an incident taught you something not covered here, add a rule from `templates/RULE.md` AND a row here in the same change.
5. Run `bash scripts/check-rules-index.sh`. It fails if a row points to a file that does not exist, or a rule file has no row. Run it in CI.

## Index

<!-- Table format is parsed by scripts/check-rules-index.sh: | `pattern` | `rule-file.md` | -->

| Path pattern | Rule file |
| --- | --- |
| `supabase/migrations/**` | `migrations-and-mcp.md` |
| `supabase/functions/**` | `deploy-parity.md` |
| `supabase/functions/**` | `secrets-are-write-only.md` |
| `supabase/templates/**` | `auth-email-code-only.md` |
| `eas.json` | `branch-freshness.md` |
| `app.json` | `branch-freshness.md` |
| `.github/workflows/**` | `branch-freshness.md` |
| `RELEASE_CHECKLIST.md` | `branch-freshness.md` |
| `.claude/workflows/**` | `graph-loop-decision-tree.md` |

Add rows for your stack. Patterns that match no file today are fine; rule files that do not exist are not.
