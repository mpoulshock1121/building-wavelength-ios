#!/usr/bin/env bash
# Install the engine into a new (or existing) iOS app repo.
#
# Usage: bash bootstrap.sh <target-dir> [--no-scaffold] [--name "My App"]
#
#  - copies .claude/ (agents, hook, commands, rules, workflows), templates/,
#    CI workflows, and helper scripts into <target-dir>
#  - scaffolds an Expo app there unless package.json exists or --no-scaffold
#  - never overwrites an existing file (prints "kept" instead)
#  - verifies the install: rules index check + gate self-test
#
# Human-only steps it will NOT do: sign in to Expo or Apple, create the store
# listing, create the hosted backend project, set secrets.
set -euo pipefail

ENGINE="$(cd "$(dirname "$0")/.." && pwd)"
TARGET=""; SCAFFOLD=1; NAME="My App"
while [ $# -gt 0 ]; do
  case "$1" in
    --no-scaffold) SCAFFOLD=0 ;;
    --name) NAME="${2:?--name needs a value}"; shift ;;
    -*) echo "unknown option $1" >&2; exit 2 ;;
    *) TARGET="$1" ;;
  esac
  shift
done
[ -n "$TARGET" ] || { echo "usage: bootstrap.sh <target-dir> [--no-scaffold] [--name \"My App\"]" >&2; exit 2; }

mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"
[ "$TARGET" != "$ENGINE" ] || { echo "target must not be the engine folder" >&2; exit 2; }

copy() { # src dst : copy a file without overwriting
  mkdir -p "$(dirname "$2")"
  if [ -e "$2" ]; then echo "kept   ${2#"$TARGET"/}"; else cp "$1" "$2"; echo "added  ${2#"$TARGET"/}"; fi
}
copy_tree() { # srcdir dstdir
  ( cd "$1" && find . -type f ! -name '.DS_Store' ) | while IFS= read -r f; do copy "$1/$f" "$2/$f"; done
}

if [ "$SCAFFOLD" -eq 1 ] && [ ! -f "$TARGET/package.json" ]; then
  command -v npx >/dev/null || { echo "npx is required to scaffold; or re-run with --no-scaffold" >&2; exit 1; }
  echo "Scaffolding Expo app..."
  tmp="$(mktemp -d)"
  ( cd "$tmp" && npx --yes create-expo-app@latest app --template blank-typescript --no-install )
  ( cd "$tmp/app" && find . -type f ! -path './node_modules/*' ) | while IFS= read -r f; do copy "$tmp/app/$f" "$TARGET/$f"; done
  rm -rf "$tmp"
fi

copy_tree "$ENGINE/.claude" "$TARGET/.claude"
copy_tree "$ENGINE/templates" "$TARGET/templates"
copy_tree "$ENGINE/ci/workflows" "$TARGET/.github/workflows"
copy_tree "$ENGINE/ci/scripts" "$TARGET/scripts/ci"
for s in check-rules-index.sh scrub-check.sh test-gate.sh; do copy "$ENGINE/scripts/$s" "$TARGET/scripts/$s"; done
chmod +x "$TARGET/.claude/hooks/gate.sh" "$TARGET"/scripts/*.sh "$TARGET"/scripts/ci/*.sh 2>/dev/null || true

# Starter docs from templates (kept if they already exist).
for t in CLAUDE.md CONTEXT.md; do copy "$ENGINE/templates/$t" "$TARGET/$t"; done
sed -i.bak "s/<App name>/$NAME/g" "$TARGET/CLAUDE.md" "$TARGET/CONTEXT.md" 2>/dev/null && rm -f "$TARGET/CLAUDE.md.bak" "$TARGET/CONTEXT.md.bak"

# Ignore gate/build junk, once.
touch "$TARGET/.gitignore"
for line in ".env" ".env.*" "!.env.example" "node_modules/"; do
  grep -qxF "$line" "$TARGET/.gitignore" || echo "$line" >>"$TARGET/.gitignore"
done

[ -d "$TARGET/.git" ] || git -C "$TARGET" init -q

echo
echo "Verifying install..."
( cd "$TARGET" && bash scripts/check-rules-index.sh && bash scripts/test-gate.sh >/dev/null && echo "role-chain gate self-test OK" )

cat <<MSG

Engine installed in $TARGET.

Next (you):
  1. cd "$TARGET" && npm install
  2. Open Claude Code in this folder and run:  /new-app "<your idea>"
  3. Then /spec, approve SPEC.md, then /build 1.

Human-only, later: sign in to Expo (npx eas-cli login, then eas init), create the
hosted backend project, set CI secrets (see the engine's ci/README.md), store listing and review.
MSG
