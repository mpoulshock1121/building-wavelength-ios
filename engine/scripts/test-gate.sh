#!/usr/bin/env bash
# Simulates a Claude Code session against .claude/hooks/gate.sh and asserts the
# Stop gate blocks when roles are missing or out of order, and allows a complete
# chain. Run from anywhere: bash scripts/test-gate.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/../.claude/hooks/gate.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export GATE_STATE_ROOT="$WORK/state"
cd "$WORK" || exit 1          # not a git repo: project root falls back to cwd

pass=0; fail=0
check() { # name expected_exit actual_exit
  if [ "$2" = "$3" ]; then echo "PASS  $1 (exit $3)"; pass=$((pass + 1));
  else echo "FAIL  $1 (wanted exit $2, got $3)"; fail=$((fail + 1)); fi
}

sid=0
new_session() { sid=$((sid + 1)); SID="sim-$sid"; }
run() { # phase json -> exit code, stderr in $ERR
  ERR="$(printf '%s' "$2" | GATE_PHASE="$1" bash "$HOOK" 2>&1 >/dev/null)"; return $?
}
prompt() { run prompt "{\"session_id\":\"$SID\",\"prompt\":\"$1\"}"; }
agent()  { run tool "{\"session_id\":\"$SID\",\"tool_name\":\"Task\",\"tool_input\":{\"subagent_type\":\"$1\"}}"; }
bash_cmd() { run tool "{\"session_id\":\"$SID\",\"tool_name\":\"Bash\",\"command\":\"$1\"}"; }
edit()   { run tool "{\"session_id\":\"$SID\",\"tool_name\":\"Edit\",\"file_path\":\"a.ts\"}"; }
stop()   { run stop "{\"session_id\":\"$SID\",\"transcript_path\":\"$WORK/t.txt\"}"; return $?; }

FULL_RECEIPT='GATE RECEIPT
Understand: add a settings toggle so people can turn reminders off.
Implement: added the toggle and its saved setting.
Verify: ran npm test and tsc, both passed.
Review: no findings, guards checked.
Close: all checks green, no open gaps.
Retro: none.'
printf '%s\n' "$FULL_RECEIPT" >"$WORK/t.txt"

# 1. Only the implementer ran -> blocked
new_session; prompt "implement a reminders toggle feature"; edit; agent implementer; bash_cmd "npm test"
stop; check "blocked: only implementer ran" 2 $?

# 2. Verifier before implementer -> blocked as out of order
new_session; prompt "implement a reminders toggle feature"; edit; bash_cmd "npm test"
for r in verifier implementer reviewer closer retro; do agent $r; done
stop; check "blocked: verifier ran before implementer" 2 $?
case "$ERR" in *"out of order"*) echo "PASS  message names the order problem"; pass=$((pass+1));; *) echo "FAIL  message: $ERR"; fail=$((fail+1));; esac

# 3. Reviewer before verifier (the old documented order) -> blocked
new_session; prompt "implement a reminders toggle feature"; edit; bash_cmd "npm test"
for r in implementer reviewer verifier closer retro; do agent $r; done
stop; check "blocked: reviewer ran before verifier" 2 $?

# 4. Chain complete but closer/retro never ran -> blocked
new_session; prompt "implement a reminders toggle feature"; edit; bash_cmd "npm test"
for r in implementer verifier reviewer; do agent $r; done
stop; check "blocked: closer and retro missing" 2 $?

# 5. Full chain, but receipt lacks Close/Retro -> blocked
new_session; prompt "implement a reminders toggle feature"; edit; bash_cmd "npm test"
for r in implementer verifier reviewer closer retro; do agent $r; done
printf 'GATE RECEIPT\nUnderstand: add a toggle for reminders.\nImplement: done.\nVerify: ran npm test, passed.\nReview: no findings.\n' >"$WORK/t.txt"
stop; check "blocked: receipt missing Close and Retro" 2 $?
printf '%s\n' "$FULL_RECEIPT" >"$WORK/t.txt"

# 6. Full chain, no verification command and no skip reason -> blocked
new_session; prompt "implement a reminders toggle feature"; edit
for r in implementer verifier reviewer closer retro; do agent $r; done
printf 'GATE RECEIPT\nUnderstand: add a toggle for reminders.\nImplement: done.\nVerify: looks fine to me.\nReview: no findings.\nClose: complete.\nRetro: none.\n' >"$WORK/t.txt"
stop; check "blocked: no verification evidence" 2 $?
printf '%s\n' "$FULL_RECEIPT" >"$WORK/t.txt"

# 7. Complete, ordered chain + full receipt -> allowed
new_session; prompt "implement a reminders toggle feature"; edit; bash_cmd "npm test"
for r in implementer verifier reviewer closer retro; do agent $r; done
stop; check "allowed: full chain, in order, full receipt" 0 $?

# 8. Loop (reviewer found gaps, implementer re-ran) keeps first-occurrence order -> allowed
new_session; prompt "implement a reminders toggle feature"; edit; bash_cmd "npm test"
for r in implementer verifier reviewer implementer verifier reviewer closer retro; do agent $r; done
stop; check "allowed: revision loop, first-occurrence order intact" 0 $?

# 9. Clarifying pause -> allowed without chain
new_session; prompt "implement a reminders toggle feature"
echo "Which people should get reminders?
GATE PAUSED - awaiting your answer" >"$WORK/t.txt"
stop; check "allowed: paused to ask the user" 0 $?
printf '%s\n' "$FULL_RECEIPT" >"$WORK/t.txt"

# 10. Cosmetic prompt is not gated at all
new_session; prompt "fix a typo in the readme"
stop; check "allowed: cosmetic edit is not gated" 0 $?

# 11. Revision budget: two blocks, then the gate lets the turn end with a report
new_session; prompt "implement a reminders toggle feature"; edit
printf 'nothing useful\n' >"$WORK/t.txt"
stop; a=$?; stop; b=$?; stop; c=$?
check "budget: first block" 2 $a; check "budget: second block" 2 $b; check "budget: exhausted, turn may end" 0 $c

# 12. The gate's own injected instructions (present in the transcript) must not
#     satisfy the pause or receipt checks
new_session; ctxout="$(printf '{"session_id":"%s","prompt":"implement a reminders toggle feature"}' "$SID" | GATE_PHASE=prompt bash "$HOOK")"
printf '%s\n' "$ctxout" >"$WORK/t.txt"
stop; check "blocked: injected instructions are not a pause or receipt" 2 $?
printf '%s\n' "$FULL_RECEIPT" >"$WORK/t.txt"

# 13. A receipt inside JSONL transcript text (escaped newlines) is still read
new_session; prompt "implement a reminders toggle feature"; edit; bash_cmd "npm test"
for r in implementer verifier reviewer closer retro; do agent $r; done
printf '{"type":"assistant","text":"%s"}\n' "$(printf '%s' "$FULL_RECEIPT" | awk 'BEGIN{f=1}{if(!f)printf "\\n";printf "%s",$0;f=0}')" >"$WORK/t.txt"
stop; check "allowed: receipt in JSONL transcript" 0 $?
printf '%s\n' "$FULL_RECEIPT" >"$WORK/t.txt"

echo; echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
