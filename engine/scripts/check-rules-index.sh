#!/usr/bin/env bash
# Keeps .claude/rules/INDEX.md honest.
#  - every rule file named in the index must exist
#  - every rule file in the folder must be named in the index
# Index rows look like:  | `path/pattern/**` | `rule-file.md` |
# Usage: bash scripts/check-rules-index.sh [rules-dir]   (default .claude/rules)
set -u
DIR="${1:-.claude/rules}"
INDEX="$DIR/INDEX.md"
if [ ! -f "$INDEX" ]; then
  echo "ERROR: $INDEX not found." >&2
  echo "Run this from the root of an app repo that has the engine installed (bash <engine>/scripts/bootstrap.sh <app-dir>), or pass the rules folder: bash check-rules-index.sh path/to/.claude/rules" >&2
  exit 1
fi

rc=0
referenced="$(grep -E '^\|[[:space:]]*`[^`]+`[[:space:]]*\|[[:space:]]*`[^`]+\.md`[[:space:]]*\|' "$INDEX" |
  sed -E 's/^\|[^|]*\|[[:space:]]*`([^`]+)`.*/\1/' | sort -u)"

while IFS= read -r f; do
  [ -z "$f" ] && continue
  if [ ! -f "$DIR/$f" ]; then
    echo "ERROR: index references missing rule file: $DIR/$f" >&2
    rc=1
  fi
done <<<"$referenced"

for path in "$DIR"/*.md; do
  base="$(basename "$path")"
  [ "$base" = "INDEX.md" ] && continue
  if ! printf '%s\n' "$referenced" | grep -qx "$base"; then
    echo "ERROR: rule file not listed in the index: $base" >&2
    rc=1
  fi
done

if [ "$rc" -eq 0 ]; then
  echo "rules index OK: $(printf '%s\n' "$referenced" | grep -c .) rule file(s) referenced, all present and all indexed"
fi
exit "$rc"
