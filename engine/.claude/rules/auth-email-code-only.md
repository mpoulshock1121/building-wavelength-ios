# Sign-in emails: offer a code or a link, never both

**Rule:** A tappable link and a typed code in the same auth email are the same single-use secret. Whichever is used first (a real tap, a corporate link scanner, a privacy relay) invalidates the other. Send code-only sign-in emails. Do not add a link back, and do not add a code step to a flow whose email still has a link.

**Why:** Link prefetchers consumed the token before people could use the code, producing "invalid or expired" for correct input.

**How to apply:** Template files in the repo are the source of truth but do not deploy themselves; a human pastes each changed template into the auth provider's dashboard, then sends a real test email and reads it. Never bulk-push auth config: it can reset the site URL and redirect allowlist. Do not trust a local config file's claims about what is live.
