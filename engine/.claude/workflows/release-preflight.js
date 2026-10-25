// Release preflight: every gate runs in parallel, none reads another's output.
// A missing prerequisite is BLOCKED and fails the release exactly like FAIL.
// Invoke with: Workflow({ name: "release-preflight" })
//
// agent(), parallel(), phase(), and log() are provided by the Workflow runtime.
/* global agent, parallel, phase, log */

export const meta = {
  name: "release-preflight",
  description:
    "Runs branch-freshness, version, tests, db-guards, secrets-present, and human-gates in parallel. Any FAIL or BLOCKED fails the release.",
  phases: ["gates", "verdict"],
};

export const GATES = [
  "branch-freshness",
  "version",
  "tests",
  "db-guards",
  "secrets-present",
  "human-gates",
];

let results = [];

phase("gates", async () => {
  log(`Running ${GATES.length} release gates in parallel.`);
  results = await parallel(
    GATES.map((gate) =>
      agent({
        description: `Gate: ${gate}`,
        subagent_type: "release-preflight",
        prompt:
          `Run exactly one gate: ${gate}. Follow .claude/agents/release-preflight.md. ` +
          "Your first line must be exactly 'PASS " + gate + "', 'FAIL " + gate + "', or 'BLOCKED " + gate + "'. " +
          "A missing secret, login, or network is BLOCKED, never a skip or a pass. Then give evidence: commands, exit codes, output tail.",
      })
    )
  );
});

phase("verdict", () => {
  const lines = GATES.map((g, i) => {
    const first = String(results[i] ?? "").split("\n")[0].trim();
    const ok = first === `PASS ${g}`;
    return { gate: g, ok, first: ok ? first : first || `BLOCKED ${g} (no result returned)` };
  });
  const failed = lines.filter((l) => !l.ok);
  const summary = lines.map((l) => `${l.ok ? "PASS   " : "NOT OK "} ${l.first}`).join("\n");
  if (failed.length > 0) {
    // Loud failure: any non-PASS, including an unparseable or missing result.
    throw new Error(
      `RELEASE PREFLIGHT FAILED (${failed.length}/${GATES.length} gates not passing)\n${summary}\n\n` +
        "Fix each failing gate or supply the missing prerequisite, then re-run. Do not build around a BLOCKED gate."
    );
  }
  log(`RELEASE PREFLIGHT PASSED\n${summary}`);
  return summary;
});
