#!/bin/sh
# Static checks for the repository's agent instruction files and skills.
#
#   1. AGENTS.md stays within Codex's default 32 KiB project_doc_max_bytes
#      budget: fails above 32768 bytes, warns above 28672. Codex cuts the
#      file short without failing, so the tail would be lost silently.
#   2. CLAUDE.md imports AGENTS.md with a standalone `@AGENTS.md` line outside
#      any fenced code block; Claude Code ignores imports inside fences, and
#      without the import it ignores AGENTS.md whenever CLAUDE.md exists.
#   3. AGENTS.md has no line starting with `@` outside fences: Codex does not
#      follow imports, so shared text must not depend on one.
#   4. Every SKILL.md has a kebab-case `name` equal to its directory and a
#      single-line `description` of at most 1024 bytes without < or >.
#
# Each check also runs against broken fixtures, so a check that stops
# detecting its failure case fails the suite.
#
# Run from anywhere:
#   sh global/tests/instruction-files-test.sh
set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
TMPROOT=$(mktemp -d "${TMPDIR:-/tmp}/instruction-files-test.XXXXXX")
trap 'rm -rf "$TMPROOT"' EXIT INT TERM

LIMIT=32768
WARN=28672
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "ok   $1"; }
fail() { FAIL=$((FAIL + 1)); echo "FAIL $1" >&2; }

# assert_ok DESC CMD...: CMD must succeed; its output is shown either way.
assert_ok() {
  label=$1
  shift
  if "$@" > "$TMPROOT/out" 2>&1; then
    pass "$label"
  else
    fail "$label"
  fi
  sed 's/^/     /' "$TMPROOT/out"
}

# assert_fails DESC CMD...: CMD must fail, proving the check detects the case.
assert_fails() {
  label=$1
  shift
  if "$@" > /dev/null 2>&1; then
    fail "$label (the check did not detect it)"
  else
    pass "$label"
  fi
}

# Lines outside fenced code blocks, carriage returns stripped.
outside_fences() {
  awk 'BEGIN { t = sprintf("%c%c%c", 96, 96, 96) }
       { sub(/\r$/, ""); s = $0; sub(/^[ \t]+/, "", s) }
       index(s, t) == 1 || index(s, "~~~") == 1 { f = !f; next }
       !f { print }' "$1"
}

agents_size() {
  n=$(wc -c < "$1" | tr -d ' ')
  if [ "$n" -gt "$LIMIT" ]; then
    echo "$1: $n bytes, over Codex's default $LIMIT-byte budget"
    return 1
  fi
  if [ "$n" -gt "$WARN" ]; then
    echo "warning: $n bytes, above $WARN; $((LIMIT - n)) bytes left before Codex cuts it short"
  else
    echo "$n bytes, $((LIMIT - n)) bytes left"
  fi
}

imports_agents() {
  outside_fences "$1" | grep -qx '@AGENTS\.md'
}

no_line_imports() {
  if outside_fences "$1" | grep -q '^@'; then
    outside_fences "$1" | grep '^@'
    return 1
  fi
}

skill_ok() {
  f=$1
  dir=$(basename "$(dirname "$f")")
  fm=$(awk 'NR == 1 { if ($0 != "---") exit 2; next }
            $0 == "---" { closed = 1; exit 0 }
            { print }
            END { if (!closed) exit 2 }' "$f") || { echo "$f: no frontmatter"; return 1; }
  name=$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -n 1)
  desc=$(printf '%s\n' "$fm" | sed -n 's/^description:[[:space:]]*//p' | head -n 1)
  [ -n "$name" ] || { echo "$f: missing name"; return 1; }
  [ "$name" = "$dir" ] || { echo "$f: name '$name' differs from directory '$dir'"; return 1; }
  printf '%s\n' "$name" | grep -Eqx '[a-z0-9]+(-[a-z0-9]+)*' || { echo "$f: name is not kebab-case"; return 1; }
  [ -n "$desc" ] || { echo "$f: missing description"; return 1; }
  case $desc in
    '|'* | '>'*) echo "$f: description must be on one line"; return 1 ;;
    *'<'* | *'>'*) echo "$f: description contains < or >"; return 1 ;;
  esac
  [ "$(printf '%s' "$desc" | wc -c | tr -d ' ')" -le 1024 ] || { echo "$f: description over 1024 bytes"; return 1; }
}

# --- Fixtures: each check must catch its failure case -----------------------

F=$TMPROOT/fixtures
mkdir -p "$F"

printf '# CLAUDE.md\n\n@AGENTS.md\n' > "$F/import-ok.md"
printf '# CLAUDE.md\r\n\r\n@AGENTS.md\r\n' > "$F/import-crlf.md"
printf '# CLAUDE.md\n\n```markdown\n@AGENTS.md\n```\n' > "$F/import-fenced.md"
printf '# CLAUDE.md\n\n~~~\n@AGENTS.md\n~~~\n' > "$F/import-tilde.md"
printf '# CLAUDE.md\n\nSee `@AGENTS.md`.\n' > "$F/import-inline.md"
printf '# CLAUDE.md\n\n@../AGENTS.md\n' > "$F/import-wrong-path.md"
printf '# CLAUDE.md\n\nNo import here.\n' > "$F/import-missing.md"
assert_ok "fixture: standalone import is accepted" imports_agents "$F/import-ok.md"
assert_ok "fixture: import with CRLF line endings is accepted" imports_agents "$F/import-crlf.md"
assert_fails "fixture: import inside a backtick fence is rejected" imports_agents "$F/import-fenced.md"
assert_fails "fixture: import inside a tilde fence is rejected" imports_agents "$F/import-tilde.md"
assert_fails "fixture: import inside a code span is rejected" imports_agents "$F/import-inline.md"
assert_fails "fixture: ../AGENTS.md in the root CLAUDE.md is rejected" imports_agents "$F/import-wrong-path.md"
assert_fails "fixture: missing import is rejected" imports_agents "$F/import-missing.md"

awk -v n="$LIMIT" 'BEGIN { while (n-- > 0) printf "x" }' > "$F/size-limit.md"
{ cat "$F/size-limit.md"; printf 'x'; } > "$F/size-over.md"
assert_ok "fixture: AGENTS.md of exactly $LIMIT bytes is accepted" agents_size "$F/size-limit.md"
assert_fails "fixture: AGENTS.md of $((LIMIT + 1)) bytes is rejected" agents_size "$F/size-over.md"

printf '# AGENTS.md\n\n@docs/testing.md\n' > "$F/agents-import.md"
printf '# AGENTS.md\n\n```text\n@docs/testing.md\n```\n' > "$F/agents-fenced-import.md"
assert_fails "fixture: @ import line in AGENTS.md is rejected" no_line_imports "$F/agents-import.md"
assert_ok "fixture: @ line inside a fence in AGENTS.md is accepted" no_line_imports "$F/agents-fenced-import.md"

make_skill() {
  mkdir -p "$F/skills/$1"
  printf '%s\n' "$2" > "$F/skills/$1/SKILL.md"
}
long=$(awk 'BEGIN { while (n++ < 1025) printf "d" }')
make_skill good-skill "$(printf -- '---\nname: good-skill\ndescription: Does one thing well.\n---\n\nBody.')"
make_skill other-dir "$(printf -- '---\nname: good-skill\ndescription: Does one thing.\n---')"
make_skill Bad-Case "$(printf -- '---\nname: Bad-Case\ndescription: Does one thing.\n---')"
make_skill no-desc "$(printf -- '---\nname: no-desc\n---')"
make_skill folded "$(printf -- '---\nname: folded\ndescription: >\n  Spread over\n  lines.\n---')"
make_skill angle "$(printf -- '---\nname: angle\ndescription: Uses <tags>.\n---')"
make_skill too-long "$(printf -- '---\nname: too-long\ndescription: %s\n---' "$long")"
make_skill unclosed "$(printf -- '---\nname: unclosed\ndescription: Never closed.')"
assert_ok "fixture: valid skill frontmatter is accepted" skill_ok "$F/skills/good-skill/SKILL.md"
assert_fails "fixture: skill name differing from its directory is rejected" skill_ok "$F/skills/other-dir/SKILL.md"
assert_fails "fixture: non-kebab-case skill name is rejected" skill_ok "$F/skills/Bad-Case/SKILL.md"
assert_fails "fixture: missing description is rejected" skill_ok "$F/skills/no-desc/SKILL.md"
assert_fails "fixture: folded multi-line description is rejected" skill_ok "$F/skills/folded/SKILL.md"
assert_fails "fixture: description with < or > is rejected" skill_ok "$F/skills/angle/SKILL.md"
assert_fails "fixture: description over 1024 bytes is rejected" skill_ok "$F/skills/too-long/SKILL.md"
assert_fails "fixture: unclosed frontmatter is rejected" skill_ok "$F/skills/unclosed/SKILL.md"

# --- Repository files ---------------------------------------------------------

assert_ok "AGENTS.md is within Codex's default budget" agents_size "$ROOT/AGENTS.md"
assert_ok "CLAUDE.md imports AGENTS.md outside code fences" imports_agents "$ROOT/CLAUDE.md"
assert_ok "AGENTS.md has no @ import lines outside code fences" no_line_imports "$ROOT/AGENTS.md"
found=0
for f in "$ROOT"/global/skills/*/SKILL.md "$ROOT"/stacks/*/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  found=$((found + 1))
  assert_ok "skill frontmatter: ${f#"$ROOT"/}" skill_ok "$f"
done
if [ "$found" -gt 0 ]; then
  pass "found $found SKILL.md files"
else
  fail "no SKILL.md files found under global/skills or stacks/*/skills"
fi

echo
echo "$PASS/$((PASS + FAIL)) passed"
[ "$FAIL" -eq 0 ]
