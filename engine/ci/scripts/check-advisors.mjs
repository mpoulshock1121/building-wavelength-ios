#!/usr/bin/env node
// Fails when the database security advisors report an ERROR or WARN that is not
// in the reviewed baseline (scripts/ci/advisors-baseline.json). Needs
// SUPABASE_PROJECT_REF and SUPABASE_ACCESS_TOKEN; missing either is an ERROR,
// not a skip. Node 20+, no dependencies.
import { readFileSync, existsSync } from "node:fs";

const ref = process.env.SUPABASE_PROJECT_REF;
const token = process.env.SUPABASE_ACCESS_TOKEN;
if (!ref || !token) {
  console.error("::error::SUPABASE_PROJECT_REF and SUPABASE_ACCESS_TOKEN are required. Refusing to pass without running the check.");
  process.exit(1);
}

const baselinePath = new URL("./advisors-baseline.json", import.meta.url);
const accepted = new Set(
  existsSync(baselinePath) ? JSON.parse(readFileSync(baselinePath, "utf8")).accepted ?? [] : []
);

const res = await fetch(`https://api.supabase.com/v1/projects/${ref}/advisors/security`, {
  headers: { Authorization: `Bearer ${token}`, Accept: "application/json" },
});
if (!res.ok) {
  console.error(`::error::Advisor request failed with HTTP ${res.status}. Treating as a failed gate.`);
  process.exit(1);
}
const body = await res.json();
const lints = Array.isArray(body) ? body : body.lints ?? [];
const fresh = lints.filter(
  (l) => (l.level === "ERROR" || l.level === "WARN") && !accepted.has(l.cache_key)
);
if (fresh.length > 0) {
  for (const l of fresh) console.error(`::error::[${l.level}] ${l.title ?? l.name}: ${l.cache_key}`);
  console.error(`${fresh.length} new security finding(s). Fix them, or add the cache_key to the baseline with a written reason.`);
  process.exit(1);
}
console.log(`Security advisors: no new ERROR/WARN findings (${lints.length} total, ${accepted.size} baselined).`);
