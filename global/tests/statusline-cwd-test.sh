#!/bin/sh
# Tests for the status line `cwd` validation in global/settings.json.
#
# Regression coverage for the fix to PR #24 review comment:
#   https://github.com/olegiv/claude-code-support-tools/pull/24#discussion_r3067827448
#
# The status line must:
#   1. Render normally for paths containing common shell metacharacters
#      ((), +, @, ',', spaces, Unicode, etc.).
#   2. Fall back to "unknown" when `cwd` contains control characters
#      (ANSI escape injection attempts).
#   3. Fall back to "unknown" when `cwd` does not exist.
#   4. Never emit attacker-controlled escape bytes in its output.
#
# Run from anywhere:
#   sh global/tests/statusline-cwd-test.sh

set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SETTINGS="$SCRIPT_DIR/../settings.json"

if [ ! -f "$SETTINGS" ]; then
  echo "FAIL: cannot find $SETTINGS" >&2
  exit 1
fi

CMD=$(jq -r .statusLine.command < "$SETTINGS")
if [ -z "$CMD" ]; then
  echo "FAIL: statusLine.command missing or empty" >&2
  exit 1
fi

TMPROOT=$(mktemp -d "${TMPDIR:-/tmp}/statusline-test.XXXXXX")
trap 'rm -rf "$TMPROOT"' EXIT INT TERM

PASS=0
FAIL=0

# run_status <cwd-string> -> prints status line stdout (raw bytes)
# Builds valid JSON with the cwd string properly escaped via jq.
run_status() {
  _cwd=$1
  printf '%s' "$_cwd" \
    | jq -Rs '{workspace:{current_dir:.},model:{display_name:"opus"},context_window:{used_percentage:10}}' \
    | sh -c "$CMD" 2>/dev/null
}

# run_status_raw_json <json-literal> -> prints status line stdout
# Use when you need to inject a JSON-escaped sequence (e.g. \u001b) verbatim.
run_status_raw_json() {
  printf '%s' "$1" | sh -c "$CMD" 2>/dev/null
}

# assert_contains <name> <haystack> <needle>
assert_contains() {
  _name=$1; _hay=$2; _needle=$3
  case "$_hay" in
    *"$_needle"*) PASS=$((PASS + 1)); printf 'PASS  %s\n' "$_name" ;;
    *) FAIL=$((FAIL + 1));
       printf 'FAIL  %s\n      expected to contain: %s\n      got: %s\n' \
         "$_name" "$_needle" "$_hay" ;;
  esac
}

# assert_not_contains <name> <haystack> <needle>
assert_not_contains() {
  _name=$1; _hay=$2; _needle=$3
  case "$_hay" in
    *"$_needle"*) FAIL=$((FAIL + 1));
       printf 'FAIL  %s\n      expected NOT to contain: %s\n      got: %s\n' \
         "$_name" "$_needle" "$_hay" ;;
    *) PASS=$((PASS + 1)); printf 'PASS  %s\n' "$_name" ;;
  esac
}

init_repo() {
  _dir=$1
  mkdir -p "$_dir"
  git -C "$_dir" init -q
  git -C "$_dir" -c user.email=t@example.com -c user.name=t \
    commit -q --allow-empty -m init
}

# ---------- Test 1: path with shell metacharacters ----------
DIR1="$TMPROOT/test (dir)+@,1"
init_repo "$DIR1"
OUT1=$(run_status "$DIR1")
assert_contains "metachar path: project name in output" "$OUT1" "test (dir)+@,1"
assert_contains "metachar path: full cwd in output"     "$OUT1" "$DIR1"
assert_not_contains "metachar path: not unknown"        "$OUT1" "unknown"

# ---------- Test 2: Unicode path ----------
DIR2="$TMPROOT/Проект"
init_repo "$DIR2"
OUT2=$(run_status "$DIR2")
assert_contains "unicode path: rendered"                "$OUT2" "Проект"
assert_not_contains "unicode path: not unknown"         "$OUT2" "unknown"

# ---------- Test 3a: raw ESC byte in cwd ----------
# jq -Rs encodes the ESC as \u001b, so it survives JSON, then decodes back
# to a real 0x1B byte inside the status line script. The control-byte guard
# must catch it and fall back to "unknown".
ESC=$(printf '\033')
EVIL="$TMPROOT/${ESC}[31mEVIL"
OUT3A=$(run_status "$EVIL")
assert_contains     "raw ESC: falls back to unknown" "$OUT3A" "unknown"
# The status line emits its own ESC color codes, so we can't just check
# for ESC bytes. Assert the attacker-specific payload does not appear.
assert_not_contains "raw ESC: payload not echoed"    "$OUT3A" "[31mEVIL"

# ---------- Test 3b: JSON-escaped \u001b (the realistic attack) ----------
# This is the form an attacker would use to smuggle an escape past JSON
# validation. jq decodes \u001b into a real ESC byte; our denylist must
# still catch it.
EVIL_JSON='{"workspace":{"current_dir":"/tmp/\u001b[31mEVIL"},"model":{"display_name":"opus"},"context_window":{"used_percentage":10}}'
OUT3B=$(run_status_raw_json "$EVIL_JSON")
assert_contains     "JSON \\u001b: falls back to unknown" "$OUT3B" "unknown"
assert_not_contains "JSON \\u001b: payload not echoed"    "$OUT3B" "[31mEVIL"

# ---------- Test 3c: C1 control bytes and other control chars ----------
# U+009B (CSI) becomes UTF-8 bytes C2 9B. The validator should reject it.
C1=$(printf '\302\233')
OUT3C1=$(run_status "$TMPROOT/x${C1}y")
assert_contains "C1 CSI in cwd: falls back to unknown" "$OUT3C1" "unknown"

# ASCII controls should also still be rejected.
for ctrl_name in CR LF TAB DEL; do
  case "$ctrl_name" in
    CR)  CTRL=$(printf '\r')  ;;
    LF)  CTRL=$(printf '\n')  ;;
    TAB) CTRL=$(printf '\t')  ;;
    DEL) CTRL=$(printf '\177') ;;
  esac
  OUT=$(run_status "$TMPROOT/x${CTRL}y")
  assert_contains "$ctrl_name in cwd: falls back to unknown" "$OUT" "unknown"
done

# ---------- Test 4: non-existent path ----------
OUT4=$(run_status "$TMPROOT/does-not-exist-xyz")
assert_contains     "missing path: falls back to unknown"   "$OUT4" "unknown"
assert_not_contains "missing path: name not echoed"         "$OUT4" "does-not-exist-xyz"

# ---------- Test 5: empty cwd ----------
OUT5=$(run_status "")
assert_contains     "empty cwd: falls back to unknown"      "$OUT5" "unknown"

# ---------- Summary ----------
TOTAL=$((PASS + FAIL))
printf '\n%d/%d passed\n' "$PASS" "$TOTAL"
[ "$FAIL" -eq 0 ]
