#!/bin/sh
# Regression test for the claude.yml trust-boundary trigger condition.
#
# Guards the fix for GHA-NEW-001: every event branch must validate the
# author_association of its OWN actor, and the flat cross-entity OR of
# three different entities' associations must never be reintroduced (that
# bug let an untrusted commenter trigger the workflow via a trusted user's
# issue/PR).
#
# Run from the repository root:
#   sh .github/tests/claude-trigger-test.sh
# Requires only POSIX sh + grep.

set -eu

WORKFLOW="${1:-.github/workflows/claude.yml}"
pass=0
fail=0

expect_count() {
  # expect_count "description" pattern expected_count
  actual=$(printf '%s\n' "$STRIPPED" | grep -Fc "$2" || true)
  if [ "$actual" = "$3" ]; then
    printf 'PASS  %s (%s)\n' "$1" "$actual"
    pass=$((pass + 1))
  else
    printf 'FAIL  %s: got %s, expected %s\n' "$1" "$actual" "$3"
    fail=$((fail + 1))
  fi
}

if [ ! -f "$WORKFLOW" ]; then
  printf 'FAIL  workflow not found: %s\n' "$WORKFLOW"
  exit 1
fi

# Strip full-line comments so the checks below inspect the actual `if:`
# expression, not prose that documents it (the condition's own comment
# legitimately names github.event.issue.author_association, etc.).
STRIPPED=$(grep -v '^[[:space:]]*#' "$WORKFLOW")

# 1. Anti-pattern guard: the old flat "== 'OWNER'" equality style is gone.
#    Reintroducing it is exactly how the trust-boundary bug comes back.
expect_count "no flat author_association equality (anti-pattern)" \
  "author_association == '" "0"

# 2. Exactly one per-event allowlist-membership check per event branch (4).
expect_count "four per-event association allowlist checks" \
  '["OWNER","MEMBER","COLLABORATOR"]' "4"

# 3. Each actor's association is consulted only where it belongs:
#    comment author for the two comment events, review author for the
#    review event, issue author for the issues event.
expect_count "comment.author_association appears twice" \
  "github.event.comment.author_association" "2"
expect_count "review.author_association appears once" \
  "github.event.review.author_association" "1"
expect_count "issue.author_association appears once" \
  "github.event.issue.author_association" "1"

# 4. All four event types are still branched explicitly.
for ev in issue_comment pull_request_review_comment pull_request_review issues; do
  if printf '%s\n' "$STRIPPED" | grep -Fq "github.event_name == '$ev'"; then
    printf 'PASS  event branch present: %s\n' "$ev"
    pass=$((pass + 1))
  else
    printf 'FAIL  event branch missing: %s\n' "$ev"
    fail=$((fail + 1))
  fi
done

# 5. Structural coupling (the property counts alone can't prove): each
#    association check must live INSIDE its own event branch, not in a
#    shared OR alongside the event checks. Without this, a rewrite like
#      (event_a || event_b || ...) && (assoc_a || assoc_b || ...)
#    keeps every count above correct while letting one entity's trusted
#    association authorize another entity's @claude trigger.
#
# Extract the `if:` block, flatten it, then split the outer group into its
# top-level parenthesized branches (one per line) by tracking paren depth.
IFBLOCK=$(awk '/^    if:/{f=1;next} f&&/^      /{print;next} f{exit}' "$WORKFLOW")
FLAT=$(printf '%s' "$IFBLOCK" | tr '\n' ' ' | tr -s ' ')
BRANCHES=$(printf '%s' "$FLAT" | awk '{
  depth = 0; start = 0
  for (i = 1; i <= length($0); i++) {
    c = substr($0, i, 1)
    if (c == "(") { depth++; if (depth == 2) start = i + 1 }
    else if (c == ")") {
      if (depth == 2 && start > 0) { print substr($0, start, i - start); start = 0 }
      depth--
    }
  }
}')

check_coupling() {
  # check_coupling <event_name> <expected_entity>
  ev="$1"; want="$2"
  branch=$(printf '%s\n' "$BRANCHES" | grep -F "github.event_name == '$ev'" || true)
  if [ -z "$branch" ]; then
    printf 'FAIL  coupling: no single branch owns event %s\n' "$ev"
    fail=$((fail + 1)); return
  fi
  if ! printf '%s' "$branch" | grep -Fq "github.event.$want.author_association"; then
    printf 'FAIL  coupling: %s branch does not check %s.author_association\n' "$ev" "$want"
    fail=$((fail + 1)); return
  fi
  for other in comment review issue; do
    [ "$other" = "$want" ] && continue
    if printf '%s' "$branch" | grep -Fq "github.event.$other.author_association"; then
      printf 'FAIL  coupling: %s branch also references %s.author_association\n' "$ev" "$other"
      fail=$((fail + 1)); return
    fi
  done
  printf 'PASS  coupling: %s branch checks only %s.author_association\n' "$ev" "$want"
  pass=$((pass + 1))
}

check_coupling issue_comment comment
check_coupling pull_request_review_comment comment
check_coupling pull_request_review review
check_coupling issues issue

printf '\n%d/%d passed\n' "$pass" "$((pass + fail))"
[ "$fail" -eq 0 ]
