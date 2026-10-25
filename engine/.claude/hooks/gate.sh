#!/usr/bin/env bash
# Role-chain gate for Claude Code. One order, enforced everywhere:
#
#   implementer -> verifier -> reviewer -> closer -> retro
#
# Phases (set by .claude/settings.json via GATE_PHASE):
#   prompt  UserPromptSubmit  start a fresh gate for engineering prompts
#   tool    PostToolUse       record subagent runs and edit/verify evidence
#   stop    Stop              block the turn unless the chain ran, in order,
#                             and the final message carries a complete receipt
#
# What this proves: each role ran as its own subagent, in order, and the
# receipt has a line per role. It does NOT prove the work is good. Quality is
# the job of the agents' prompts and of CI. See method/02-build-verify.md.
#
# Failure stance (explicit): the gate FAILS OPEN on its own faults. Missing or
# unwritable state, unreadable transcript, or an exhausted revision budget all
# let the turn end (the first one warns the model at prompt time). It is a
# process guard against an honest-but-sloppy agent, not a security boundary: the
# receipt and role names are model-written text and can be faked. Real
# enforcement is CI and the human gates. The hook never evals input; values are
# only passed to grep/printf, and state lives outside the repo.
#
# Exit codes: 0 = allow, 2 = block (stderr is fed back to the model).

MAX_CYCLES=2
ROLE_ORDER="implementer verifier reviewer closer retro"

INPUT="$(cat)"
PHASE="${GATE_PHASE:-}"

PROJECT_ROOT="$(pwd)"
if command -v git >/dev/null 2>&1; then
  GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$GIT_ROOT" ] && PROJECT_ROOT="$GIT_ROOT"
fi

# ---------- tiny JSON helpers (no jq dependency) ----------
json_string_field() {
  printf '%s' "$INPUT" | tr '\n' ' ' |
    sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n 1
}
json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' |
    awk 'BEGIN{f=1}{gsub(/\r/,""); if(!f) printf "\\n"; printf "%s",$0; f=0}'
}

# ---------- state: one directory per project AND per session ----------
# Concurrent sessions on one repo must not clobber each other's evidence.
# State lives outside the repo so it can never be committed by accident.
STATE_ROOT="${GATE_STATE_ROOT:-${XDG_STATE_HOME:-$HOME/.local/state}/building-wavelength-gate}"
PROJECT_KEY="$(printf '%s' "$PROJECT_ROOT" | cksum | cut -d ' ' -f 1)"
SESSION_ID="$(json_string_field session_id)"
if [ -n "$SESSION_ID" ]; then
  STATE_DIR="$STATE_ROOT/$PROJECT_KEY/$(printf '%s' "$SESSION_ID" | cksum | cut -d ' ' -f 1)"
else
  STATE_DIR="$STATE_ROOT/$PROJECT_KEY"
fi
STATE_PATH="$STATE_DIR/state.env"

state_get() { [ -f "$STATE_PATH" ] && grep "^$1=" "$STATE_PATH" | tail -n 1 | cut -d= -f2-; }
state_put() { # cycle edited verified roles
  mkdir -p "$STATE_DIR" 2>/dev/null || true
  {
    printf 'cycle=%s\n' "$1"
    printf 'edited=%s\n' "$2"
    printf 'verified=%s\n' "$3"
    printf 'roles=%s\n' "$4"
  } >"$STATE_PATH" 2>/dev/null || true
}
state_clear() { rm -f "$STATE_PATH" 2>/dev/null || true; }

allow() { exit 0; }

# ---------- which prompts get gated ----------
# Engineering work is gated. Pure questions and cosmetic edits are not.
# Substantive signals always win over cosmetic ones.
SUBSTANTIVE_RE='implement|feature|endpoint|route|handler|\bapi\b|schema|migration|database|\bdb\b|\bsql\b|query|model|table|\bauth\b|login|signup|sign-?in|session|password|token|permission|payment|billing|checkout|webhook|subscription|refactor|rewrite|integrat|security|rate.?limit|queue|cron|deploy|pipeline|new (page|screen|view|component|service|module)|validation|upload|cache'
TRIVIAL_RE='typo|misspell|spelling|wording|copy ?edit|rephras|reword|whitespace|indent|prettier|rename|comment|docstring|\bdocs?\b|readme|changelog|version bump|colou?r|margin|padding|\bfont\b'
ENGINEERING_RE='implement|fix|debug|build|create|add|change|update|rewrite|refactor|test|api|schema|migration|component|bug|patch|feature|screen|endpoint'

should_gate() {
  t="$1"
  printf '%s' "$t" | grep -Eiq "$ENGINEERING_RE" || return 1
  if printf '%s' "$t" | grep -Eiq "$SUBSTANTIVE_RE"; then return 0; fi
  if printf '%s' "$t" | grep -Eiq "$TRIVIAL_RE"; then return 1; fi
  return 0
}

# ---------- role mapping ----------
# Exact project agent names first, then by function keyword so a host that
# surfaces differently named agents still maps. Keyword precedence:
# review > verify/test > implement. Generic agents (explore, plan) map to nothing.
canonical_role() {
  n="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$n" in
    implementer|verifier|reviewer|closer|retro) printf '%s' "$n"; return ;;
  esac
  if printf '%s' "$n" | grep -Eq '(^|[^a-z])(review|critic|audit)'; then printf 'reviewer'; return; fi
  if printf '%s' "$n" | grep -Eq '(^|[^a-z])(verif|test|qa|validat)'; then printf 'verifier'; return; fi
  if printf '%s' "$n" | grep -Eq '(^|[^a-z])(implement|engineer|developer|coder|build|debug)'; then printf 'implementer'; return; fi
}

# ---------- phase: prompt ----------
start_gate() {
  prompt="$(json_string_field prompt)"
  [ -z "$prompt" ] && prompt="$INPUT"
  state_clear                       # every new user turn starts clean
  should_gate "$prompt" || allow
  state_put 0 0 0 ""
  [ -f "$STATE_PATH" ] || warn="WARNING: the gate could not write its state, so it is NOT enforcing this turn. Tell the user. "
  ctx="${warn:-}ROLE-CHAIN GATE ACTIVE. Delegate to subagents via the Task tool in this exact order: implementer, verifier, reviewer, closer, retro. The turn cannot end until all five have run in that order. Before delegating, restate the request in plain words; if the desired outcome is unclear, ask and end the turn with a line made of the words GATE and PAUSED (capitals), then space, hyphen, space, then: awaiting your answer. Finish with a receipt block whose first line is the words GATE and RECEIPT (capitals) and has one non-empty line each for Understand:, Implement:, Verify:, Review:, Close:, Retro:. Verify: must name real commands and results, or 'skipped: <reason>'."
  printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$(json_escape "$ctx")"
  exit 0
}

# ---------- phase: tool ----------
record_tool() {
  [ -f "$STATE_PATH" ] || allow     # not a gated turn
  tool="$(json_string_field tool_name)"
  cmd="$(json_string_field command)"
  cycle="$(state_get cycle)"; edited="$(state_get edited)"
  verified="$(state_get verified)"; roles="$(state_get roles)"

  sub="$(json_string_field subagent_type)"
  if [ -n "$sub" ]; then
    r="$(canonical_role "$sub")"
    if [ -n "$r" ]; then
      case ",$roles," in
        *",$r,"*) ;;                                  # keep FIRST occurrence only
        *) roles="${roles:+$roles,}$r" ;;
      esac
    fi
  fi

  case "$tool" in Edit|Write|MultiEdit|NotebookEdit|apply_patch) edited=1 ;; esac

  # Credit verification only from the COMMAND text, never from file paths.
  if [ "$tool" = "Bash" ] && printf '%s' "$cmd" | grep -Eiq "$TEST_RUNNER_RE"; then
    if ! printf '%s' "$INPUT" | grep -Eiq 'exitCode[^0-9]*[1-9]|command not found|permission denied'; then
      verified=1
    fi
  fi
  state_put "${cycle:-0}" "${edited:-0}" "${verified:-0}" "$roles"
  allow
}

TEST_RUNNER_RE='npm[[:space:]]+(test|run[[:space:]]+(test|typecheck|lint|check))|pnpm[[:space:]]+(test|run)|yarn[[:space:]]+(test|typecheck|lint)|bun[[:space:]]+(test|run)|npx[[:space:]]+(tsc|jest|vitest|eslint)|\btsc\b|jest|vitest|eslint|pytest|cargo[[:space:]]+(test|check)|go[[:space:]]+test|swift[[:space:]]+test|xcodebuild.*test|shellcheck|bash[[:space:]]+-n|make[[:space:]]+(test|check)'

# ---------- phase: stop ----------
# True when every role in ROLE_ORDER appears in $1 (comma list of first
# occurrences) and the positions are strictly increasing.
chain_problem() {
  list="$1"; prev=0
  for r in $ROLE_ORDER; do
    pos="$(printf '%s' "$list" | tr ',' '\n' | grep -n -x "$r" | head -n 1 | cut -d: -f1)"
    if [ -z "$pos" ]; then printf 'missing:%s' "$r"; return; fi
    if [ "$pos" -le "$prev" ]; then printf 'order:%s' "$r"; return; fi
    prev="$pos"
  done
}

receipt_line() { # label -> prints content after "Label:" (last match), trimmed
  printf '%s\n' "$TEXT" | grep -Ei "^[[:space:]>*-]*$1[[:space:]]*:" | tail -n 1 |
    sed -E "s/^[^:]*:[[:space:]]*//"
}

stop_gate() {
  [ -f "$STATE_PATH" ] || allow

  tp="$(json_string_field transcript_path)"
  tail_text=""
  [ -n "$tp" ] && [ -r "$tp" ] && tail_text="$(tail -n 200 "$tp" 2>/dev/null | sed 's/\\n/\n/g' || true)"
  TEXT="$INPUT
$tail_text"

  # A clarifying question is a legitimate way to end the turn.
  if printf '%s' "$TEXT" | grep -q 'GATE PAUSED - awaiting your answer'; then
    state_clear; allow
  fi

  cycle="$(state_get cycle)"; verified="$(state_get verified)"; roles="$(state_get roles)"
  cycle="${cycle:-0}"; missing=""

  # 1. Role chain, in order.
  problem="$(chain_problem "$roles")"
  case "$problem" in
    missing:*) missing="$missing- Role '${problem#missing:}' has not run as a subagent. Required order: implementer, verifier, reviewer, closer, retro.\n" ;;
    order:*)   missing="$missing- Role '${problem#order:}' ran out of order. Required order: implementer, verifier, reviewer, closer, retro.\n" ;;
  esac

  # 2. Receipt: a block marker plus a non-empty line per role.
  printf '%s' "$TEXT" | grep -q 'GATE RECEIPT' || missing="$missing- No 'GATE RECEIPT' block in the final message.\n"
  for label in Understand Implement Verify Review Close Retro; do
    body="$(receipt_line "$label")"
    if [ -z "$body" ] || [ "${#body}" -lt 4 ]; then
      missing="$missing- Receipt line '$label:' is missing or empty.\n"
    fi
  done

  # 3. Verification: real runner seen, or an explicit skipped reason on the Verify line.
  vline="$(receipt_line Verify)"
  if [ "$verified" != "1" ] && ! printf '%s' "$vline" | grep -Eiq '(skipped|not run)[[:space:]]*:[[:space:]]*[^[:space:]]{4,}'; then
    missing="$missing- No verification command was run. Run the checks, or write 'Verify: skipped: <concrete reason>'.\n"
  fi

  # 4. Close must be concrete. (Retro may legitimately be "none".)
  body="$(receipt_line Close)"
  if printf '%s' "$body" | grep -Eiq '^(n/?a|none|todo|tbd|\.\.\.)\.?$'; then
    missing="$missing- 'Close:' must summarise evidence and remaining gaps, not '$body'.\n"
  fi

  if [ -z "$missing" ]; then state_clear; allow; fi

  if [ "$cycle" -ge "$MAX_CYCLES" ] 2>/dev/null; then
    state_clear
    printf 'GATE BUDGET EXHAUSTED after %s revision cycles. Still missing:\n%b\nStop, report the failed gates to the user, and ask before retrying.\n' "$MAX_CYCLES" "$missing" >&2
    exit 0
  fi

  state_put "$((cycle + 1))" "$(state_get edited)" "$verified" "$roles"
  printf 'GATE BLOCKED (revision %s/%s). Fix the first failed item, then end with a complete receipt.\n%b' "$((cycle + 1))" "$MAX_CYCLES" "$missing" >&2
  exit 2
}

if [ -z "$PHASE" ]; then
  case "$(json_string_field hook_event_name)" in
    UserPromptSubmit) PHASE=prompt ;;
    Stop) PHASE=stop ;;
    *) PHASE=tool ;;
  esac
fi

case "$PHASE" in
  prompt) start_gate ;;
  tool) record_tool ;;
  stop) stop_gate ;;
  *) allow ;;
esac
