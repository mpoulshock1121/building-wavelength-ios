// Adversarial review: three independent lenses on the same diff, merged into
// one gap list. Use for high-risk diffs (auth, payments, data deletion,
// migrations). Invoke with: Workflow({ name: "adversarial-review" })
//
// agent(), parallel(), phase(), and log() are provided by the Workflow runtime.
/* global agent, parallel, phase, log */

export const meta = {
  name: "adversarial-review",
  description:
    "Three independent review lenses (correctness/security, consistency/regression, reuse/simplicity) run in parallel on the current diff, then merged into one numbered gap list or LGTM.",
  phases: ["parallel-review", "synthesis"],
};

const SHARED =
  "Review the CURRENT DIFF only (git status / git diff, or git diff against the branch base if committed). " +
  "Do not read any other reviewer's output; this pass must be independent. " +
  "Return a numbered list: location (file:line), what is wrong, what to do instead. If this lens has no gaps, return LGTM.\n\n";

const LENSES = [
  {
    description: "Correctness + security lens",
    prompt:
      SHARED +
      "Check ONLY correctness and security:\n" +
      "- Logic matches the SPEC; no swallowed errors or unhandled rejections.\n" +
      "- Types and validation agree across every boundary (input, storage, API contract).\n" +
      "- Auth AND authorization guards are wired into the request path and not bypassable by ordering.\n" +
      "- Input is validated at the trust boundary before storage or any side effect.\n" +
      "- Row-level security exists for each table touched, for each operation the app performs.\n" +
      "- No secrets, tokens, or personal data logged or returned.\n" +
      "- Breach mindset: if a user sends hostile input, does every guard hold?",
  },
  {
    description: "Consistency + regression lens",
    prompt:
      SHARED +
      "Check ONLY repo consistency and regression risk:\n" +
      "- New config and env vars are declared where the repo centralizes them; no secret in client-exposed config.\n" +
      "- Data-model changes have a matching additive migration; no destructive drop unless clearly deliberate.\n" +
      "- Module boundaries respected; shared logic not duplicated.\n" +
      "- Run the checklist in .claude/rules/INDEX.md for every touched path, read each matching rule, and flag any diff that risks repeating a documented incident.",
  },
  {
    description: "Reuse + simplicity lens",
    prompt:
      SHARED +
      "Check ONLY reuse and simplicity:\n" +
      "- No hand-rolled auth, token, hash, or crypto where the platform or an installed library covers it.\n" +
      "- UI uses the existing component and icon system.\n" +
      "- Data access goes through the existing data layer.\n" +
      "- No speculative abstraction or cleanup beyond the stated goal.",
  },
];

let lensResults = [];

phase("parallel-review", async () => {
  log("Spawning 3 independent review lenses in parallel.");
  lensResults = await parallel(LENSES.map((l) => agent(l)));
});

phase("synthesis", async () => {
  log("Merging the 3 lenses into one deduplicated gap list.");
  return await agent({
    description: "Synthesis",
    prompt:
      "Merge three independent review outputs on the same diff into ONE numbered gap list.\n\n" +
      "Correctness + security:\n" + lensResults[0] + "\n\n" +
      "Consistency + regression:\n" + lensResults[1] + "\n\n" +
      "Reuse + simplicity:\n" + lensResults[2] + "\n\n" +
      "Dedupe findings at the same file:line and note which lens(es) raised each. Keep distinct findings. " +
      "If all three returned LGTM, return LGTM. Format: location (file:line), what is wrong, what to do instead.",
  });
});
