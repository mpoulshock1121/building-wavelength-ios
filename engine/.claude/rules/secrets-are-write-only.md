# Hosted secrets can be set but not read back

**Rule:** A secrets list shows a digest of each value, never the value. To check what a live secret is set to, hash your candidate and compare with the digest (`printf '%s' "$CANDIDATE" | shasum -a 256`). Do not search for a reveal option.

**Why:** A "sign-in emails never arrive" incident turned on whether a sender-address secret still held the provider's sandbox address. It could only be confirmed by hashing and comparing; the first clue came from delivery logs (every failing recipient was a non-owner).

**How to apply:** When a secret may be wrong, infer from behavior (logs) and confirm by digest. If you cannot set the secret yourself, add a code-level guard AND record visibly that a human still has to fix the secret; a guard is a mitigation, not the fix.
