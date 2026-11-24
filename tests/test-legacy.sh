#!/bin/bash
# Carry-over from ClaudeWatch, this plugin's former name: the overrides file is
# copied into place on first run ([OVR-08]) and CLAUDEWATCH_LOG is still read
# when LOOKOUT_LOG is unset ([LOG-05]). HOME is sandboxed.
source "$(cd "$(dirname "$0")" && pwd)/harness.sh"

OVR="$SCRIPT_DIR/../scripts/overrides.py"
SANDBOX=$(mktemp -d /tmp/lookout-legacy.XXXXXX)
export HOME="$SANDBOX"
FILE="$SANDBOX/.claude/lookout/overrides.yml"
LEGACY="$SANDBOX/.claude/claudewatch/overrides.yml"

check() {
  local label="$1" ok="$2"
  TOTAL=$((TOTAL + 1))
  if [ "$ok" = yes ]; then
    PASS=$((PASS + 1)); echo -e "  ${GREEN}PASS${NC}: $label"
  else
    FAIL=$((FAIL + 1)); echo -e "  ${RED}FAIL${NC}: $label"
  fi
}
has() { if printf '%s' "$1" | grep -qF -- "$2"; then echo yes; else echo no; fi; }
session_start() { printf '{"session_id":"s1"}' | LOOKOUT_LOG=off python3 "$OVR" session-start; }

echo "=== legacy: ClaudeWatch overrides are carried over ([OVR-08]) ==="
out=$(session_start)
check "no ClaudeWatch file: nothing is created" "$( [ -e "$FILE" ] && echo no || echo yes)"
check "and nothing is said" "$( [ -z "$out" ] && echo yes || echo no)"

mkdir -p "$(dirname "$LEGACY")"
printf 'watch-dotnet: off\n' > "$LEGACY"
out=$(session_start)
check "the ClaudeWatch file is copied into place" "$(cmp -s "$LEGACY" "$FILE" && echo yes || echo no)"
check "the copy is called out in context" "$(has "$out" "copied your ClaudeWatch rule overrides")"
check "the ClaudeWatch file is left in place" "$( [ -f "$LEGACY" ] && echo yes || echo no)"

printf 'watch-git: off\n' > "$LEGACY"
out=$(session_start)
check "an existing lookout file is never overwritten" "$(has "$(cat "$FILE")" "watch-dotnet: off")"
check "and nothing is said" "$( [ -z "$out" ] && echo yes || echo no)"

echo "--- legacy: CLAUDEWATCH_LOG is read when LOOKOUT_LOG is unset ([LOG-05]) ---"
input='{"tool_name":"Bash","session_id":"s1","cwd":"/tmp","tool_input":{"command":"git commit -m wip"}}'
LOG="$SANDBOX/legacy.jsonl"
echo "$input" | env -u LOOKOUT_LOG CLAUDEWATCH_LOG="$LOG" python3 "$HOOK" "$RULES_DIR" >/dev/null 2>&1 || true
check "CLAUDEWATCH_LOG names the destination" "$( [ -s "$LOG" ] && echo yes || echo no)"

NEW="$SANDBOX/new.jsonl"
rm -f "$LOG"
echo "$input" | LOOKOUT_LOG="$NEW" CLAUDEWATCH_LOG="$LOG" python3 "$HOOK" "$RULES_DIR" >/dev/null 2>&1 || true
check "LOOKOUT_LOG wins when both are set" "$( [ -s "$NEW" ] && [ ! -e "$LOG" ] && echo yes || echo no)"

DEFAULT="$SANDBOX/.claude/lookout/decisions.jsonl"
rm -f "$DEFAULT"
echo "$input" | env -u LOOKOUT_LOG CLAUDEWATCH_LOG=off python3 "$HOOK" "$RULES_DIR" >/dev/null 2>&1 || true
check "CLAUDEWATCH_LOG=off still opts out" "$( [ -e "$DEFAULT" ] && echo no || echo yes)"

rm -rf "$SANDBOX"
print_results
