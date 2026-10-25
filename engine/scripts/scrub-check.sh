#!/usr/bin/env bash
# Pre-publication scrub. Fails (exit 1) if the tree contains secrets, personal
# identifiers, or anything on your private deny-list.
#
# Usage: bash scripts/scrub-check.sh <dir> [denylist-file]
#
# The deny-list is one literal string per line (case-insensitive): your store
# app id, Apple ID email, backend project refs, demo-account domains, personal
# emails, org/user names. KEEP THE DENY-LIST OUTSIDE THE REPO you publish.
set -u
DIR="${1:?usage: scrub-check.sh <dir> [denylist-file]}"
DENY="${2:-}"
rc=0

hit() { echo "SCRUB FAIL [$1]"; shift; printf '%s\n' "$@" | sed 's/^/    /'; rc=1; }
EXCL=(--exclude=scrub-check.sh --exclude-dir=.git --exclude-dir=node_modules)

scan() { # label regex
  out="$(grep -rEIn "${EXCL[@]}" -e "$2" "$DIR" 2>/dev/null | head -n 20)"
  [ -n "$out" ] && hit "$1" "$out"
}

scan "private key block"   '-----BEGIN [A-Z ]*PRIVATE KEY-----'
scan "JWT-like token"      'eyJ[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{10,}\.'
scan "cloud/API key"       '(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|xox[bpa]-[A-Za-z0-9-]{10,}|sk-ant-[A-Za-z0-9_-]{20,}|sk_live_[A-Za-z0-9]{10,}|re_[A-Za-z0-9]{20,})'
scan "hosted-project URL"  '[a-z0-9]{20}\.supabase\.(co|in)'
scan "store app id"        '(ascAppId|appleId|appleTeamId)"?[[:space:]]*[:=][[:space:]]*"?[A-Za-z0-9@._-]{6,}'
scan "assigned secret"     '(password|secret|api[_-]?key|token)[[:space:]]*[:=][[:space:]]*["'"'"'][A-Za-z0-9/+_=-]{20,}["'"'"']'

# Email addresses, except obvious placeholders.
emails="$(grep -rEIno "${EXCL[@]}" -e '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$DIR" 2>/dev/null |
  grep -viE '@(example\.(com|org|net)|users\.noreply\.github\.com|anthropic\.com|your-domain\.[a-z]+|yourdomain\.[a-z]+)$' |
  grep -viE '@(types|expo|react-native|tanstack|babel|jest|testing-library)/' | head -n 20)"
[ -n "$emails" ] && hit "email address" "$emails"

if [ -n "$DENY" ]; then
  [ -r "$DENY" ] || { echo "ERROR: cannot read deny-list $DENY" >&2; exit 2; }
  n=0
  while IFS= read -r term; do
    [ -z "$term" ] && continue
    case "$term" in \#*) continue ;; esac
    n=$((n + 1))
    out="$(grep -rIniF "${EXCL[@]}" -e "$term" "$DIR" 2>/dev/null | head -n 10)"
    [ -n "$out" ] && hit "deny-list term #$n" "$out"
  done <"$DENY"
  echo "deny-list terms checked: $n"
else
  echo "WARNING: no deny-list supplied; only generic patterns were checked." >&2
fi

[ "$rc" -eq 0 ] && echo "scrub check PASSED for $DIR"
exit "$rc"
