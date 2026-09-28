#!/bin/sh
# Tests for global/skills/pr-fix/scripts/pr-fix.sh and global/hooks/pre-push.
#
# Everything runs offline: `gh` and `codex` are stubs on PATH (via PRF_GH_BIN /
# PRF_CODEX_BIN) fed from global/tests/fixtures/pr-fix/, and the repository under
# test is a temporary git repo. The stubs log every invocation so the tests can
# assert what the runner asked for.
#
# Run from anywhere:
#   sh global/tests/pr-fix-test.sh

set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
RUNNER="$SCRIPT_DIR/../skills/pr-fix/scripts/pr-fix.sh"
HOOK="$SCRIPT_DIR/../hooks/pre-push"
FIX="$SCRIPT_DIR/fixtures/pr-fix"

for f in "$RUNNER" "$HOOK" "$FIX/pr-view.json"; do
  [ -e "$f" ] || { echo "FAIL: missing $f" >&2; exit 1; }
done
command -v jq >/dev/null 2>&1 || { echo "FAIL: jq is required" >&2; exit 1; }

TMPROOT=$(mktemp -d "${TMPDIR:-/tmp}/pr-fix-test.XXXXXX")
trap 'rm -rf "$TMPROOT"' EXIT INT TERM

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf 'PASS  %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL  %s\n      %s\n' "$1" "$2"; }

assert_contains() {  # name haystack needle
  case "$2" in *"$3"*) pass "$1" ;; *) fail "$1" "expected to contain: $3
      got: $(printf '%s' "$2" | head -c 600)" ;; esac
}
assert_not_contains() {
  case "$2" in *"$3"*) fail "$1" "expected NOT to contain: $3" ;; *) pass "$1" ;; esac
}
assert_eq() {  # name actual expected
  if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "expected: $3
      got: $2"; fi
}
assert_ne() {
  if [ "$2" != "$3" ]; then pass "$1"; else fail "$1" "expected a value other than: $3"; fi
}
assert_file() { if [ -e "$2" ]; then pass "$1"; else fail "$1" "missing file: $2"; fi; }
perm_of() {  # BSD stat first; on GNU `-f` means filesystem mode, so validate the output before trusting it
  _p=$(stat -f '%Lp' "$1" 2>/dev/null)
  case "$_p" in [0-7][0-7][0-7]|[0-7][0-7][0-7][0-7]) printf '%s' "$_p" ;; *) stat -c '%a' "$1" 2>/dev/null ;; esac
}
assert_no_file() { if [ ! -e "$2" ]; then pass "$1"; else fail "$1" "unexpected file: $2"; fi; }

# ---------- stubs ----------
mkdir -p "$TMPROOT/bin"
GH_LOG="$TMPROOT/gh.log"; : > "$GH_LOG"
CODEX_LOG="$TMPROOT/codex.log"; : > "$CODEX_LOG"

cat > "$TMPROOT/bin/gh" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >> "$GH_STUB_LOG"
jqf=""; prev=""
for a in "$@"; do [[ $prev == --jq ]] && jqf=$a; prev=$a; done
emit() { if [[ -n $jqf ]]; then jq -r "$jqf" <<<"$1"; else printf '%s\n' "$1"; fi; }
case "$1 $2" in
  "pr view") emit "$(cat "$FIX/pr-view-gh.json")" ;;
  "pr list") emit "[{\"number\":${GH_PR_LIST:-0}}]" ;;
  "api graphql")
    if [[ "$*" == *reviewThreads* ]]; then
      emit "$(jq -n --slurpfile a "$FIX/threads-page1.json" --slurpfile b "$FIX/threads-page2.json" \
        '[{data:{repository:{pullRequest:{headRefOid:"c4",reviewThreads:{pageInfo:{hasNextPage:false},nodes:$a[0]}}}}},
          {data:{repository:{pullRequest:{headRefOid:"c4",reviewThreads:{pageInfo:{hasNextPage:false},nodes:$b[0]}}}}}]')"
    else
      if [[ -n ${GH_FAIL_ID:-} && "$*" == *"$GH_FAIL_ID"* ]]; then echo "stub gh: forced failure" >&2; exit 1; fi
      emit '{"data":{"addPullRequestReviewThreadReply":{"comment":{"url":"https://github.com/acme/ocms-go/pull/170#discussion_r99"}},"resolveReviewThread":{"thread":{"id":"x","isResolved":true}}}}'
    fi ;;
  "api "*) emit "$(jq -n --slurpfile r "$FIX/${GH_REVIEWS:-reviews-current}.json" '[$r[0]]')" ;;
  *) echo "stub gh: unhandled: $*" >&2; exit 1 ;;
esac
STUB

cat > "$TMPROOT/bin/codex" <<'STUB'
#!/bin/bash
{ printf '%s\n' "$@"; printf -- '--\n'; } >> "$CODEX_STUB_LOG"
out=""; prev=""
for a in "$@"; do [[ $prev == -o ]] && out=$a; prev=$a; done
if [[ -n $out && -n ${CODEX_FIXTURE:-} ]]; then cp "$CODEX_FIXTURE" "$out"; fi
echo "stub codex: done"
exit "${CODEX_EXIT:-0}"
STUB
chmod +x "$TMPROOT/bin/gh" "$TMPROOT/bin/codex"

export PRF_GH_BIN="$TMPROOT/bin/gh" PRF_CODEX_BIN="$TMPROOT/bin/codex"
export GH_STUB_LOG="$GH_LOG" CODEX_STUB_LOG="$CODEX_LOG" FIX
export PRF_MAX_PUSHES=2 PRF_MAX_REVIEWS_PER_ROUND=2 PRF_REVIEW_TIMEOUT=60 PRF_CHECK_TIMEOUT=60
unset PRF_PR CODEX_REVIEW_MODEL CODEX_REVIEW_EFFORT GH_REVIEWS GH_PR_LIST GH_FAIL_ID CODEX_FIXTURE CODEX_EXIT \
      CODEX_FULL_BRANCH_AUDIT_CHILD PRF_CHILD PRF_SKIP_PUSH_GATE PRF_RUNNER 2>/dev/null || true

gh_lines() { wc -l < "$GH_LOG" | tr -d ' '; }
codex_lines() { wc -l < "$CODEX_LOG" | tr -d ' '; }

# ---------- temp repository ----------
REPO="$TMPROOT/repo"; ORIGIN="$TMPROOT/origin.git"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" config user.email t@example.com
git -C "$REPO" config user.name t
git -C "$REPO" checkout -q -b main 2>/dev/null || git -C "$REPO" symbolic-ref HEAD refs/heads/main
printf '.audit\n' > "$REPO/.gitignore"
printf 'hello\n' > "$REPO/a.txt"
mkdir -p "$REPO/scripts" "$REPO/dsh-git-guard"
i=1; : > "$REPO/scripts/install-git-guard.sh"
while [ $i -le 30 ]; do printf 'line %s\n' "$i" >> "$REPO/scripts/install-git-guard.sh"; i=$((i + 1)); done
printf 'print(1)\n' > "$REPO/dsh-git-guard/git-guard.py"
git -C "$REPO" add -A && git -C "$REPO" commit -q -m base
git init -q --bare "$ORIGIN"
git -C "$REPO" remote add origin "$ORIGIN"
git -C "$REPO" push -q origin main
git -C "$REPO" checkout -q -b feature
printf 'change\n' >> "$REPO/a.txt"
git -C "$REPO" commit -q -am feature
cd "$REPO" || exit 1

# mkinput REVIEWS-FIXTURE PR-NUMBER HEAD-REF  -> --from-file input on stdout
mkinput() {
  jq -n --slurpfile p "$FIX/pr-view.json" --slurpfile r "$FIX/$1.json" \
    --slurpfile a "$FIX/threads-page1.json" --slurpfile b "$FIX/threads-page2.json" \
    --argjson n "$2" --arg ref "$3" \
    '{pr: ($p[0] | .number = $n | .head_ref = $ref | .url = "https://github.com/acme/ocms-go/pull/\($n)"),
      reviews: $r[0], threads: ($a[0] + $b[0])}'
}
ESC=$(printf '\033')

# ---------- 1. syntax ----------
bash -n "$RUNNER" && pass "runner: bash -n" || fail "runner: bash -n" "syntax error"
bash -n "$HOOK" && pass "hook: bash -n" || fail "hook: bash -n" "syntax error"

# ---------- 2. collect --from-file (pending fixture, PR 170) ----------
mkinput reviews-pending 170 other-branch > "$TMPROOT/in170.json"
OUT=$("$RUNNER" collect --from-file "$TMPROOT/in170.json" 2>&1); RC=$?
assert_eq "collect: exit 0" "$RC" 0
assert_contains "collect: passes=3 (distinct reviewed commits, not review objects)" "$OUT" "passes=3"
assert_contains "collect: round=3 (passes win)" "$OUT" "round=3"
assert_contains "collect: cap_reached=true" "$OUT" "cap_reached=true"
assert_contains "collect: pending=true (latest connector commit != head)" "$OUT" "pending=true"
assert_contains "collect: unresolved=6" "$OUT" "unresolved=6"
N=$(ls "$REPO/.audit/pr-170"/findings-*.json 2>/dev/null | wc -l | tr -d ' ')
assert_eq "collect: findings snapshot written" "$N" 1
assert_contains "collect: untrusted author body withheld" "$OUT" "[untrusted author drive-by-user (NONE); body withheld]"
assert_not_contains "collect: untrusted title not printed" "$OUT" "UNTRUSTED-INJECTION"
assert_not_contains "collect: untrusted body not printed" "$OUT" "UNTRUSTED-BODY"
assert_contains "collect: untrusted thread demoted to [P?]" "$OUT" "[P?] README.md:1"
OUT2=$("$RUNNER" collect --include-untrusted --from-file "$TMPROOT/in170.json" 2>&1)
assert_contains "collect --include-untrusted: prints the body" "$OUT2" "UNTRUSTED-BODY"
"$RUNNER" collect --from-file "$TMPROOT/in170.json" >/dev/null 2>&1
assert_contains "collect: P1 line with clean title" "$OUT" "[P1] dsh-git-guard/git-guard.py:23 — Match long-form branch deletion before allowing it (thread PRRT_T1, chatgpt-codex-connector,"
assert_not_contains "collect: no ** left in titles" "$OUT" "**"
assert_not_contains "collect: no <sub> markup" "$OUT" "<sub>"
assert_not_contains "collect: resolved thread excluded" "$OUT" "RESOLVED-THREAD-TITLE"
assert_contains "collect: human thread shows [P?]" "$OUT" "[P?] docs/dsh-onboarding.md:5 — HUMAN-THREAD"
assert_contains "collect: page-2 thread present" "$OUT" "PAGE2-THREAD"
assert_contains "collect: line falls back to originalLine" "$OUT" "cmd/ocms/main.go:2199"
assert_contains "collect: outdated tag" "$OUT" "[outdated]"
assert_not_contains "collect: ESC byte stripped from hostile body" "$OUT" "$ESC"
assert_no_file "collect: hostile \$(touch) not executed (repo)" "$REPO/pwned-marker"
assert_no_file "collect: hostile \$(touch) not executed (cwd)" "$TMPROOT/pwned-marker"
assert_contains "collect: cap notice" "$OUT" "cap reached"
assert_file "collect: state.json written" "$REPO/.audit/pr-170/state.json"
OUT=$(PRF_PR=170 "$RUNNER" status 2>&1)
assert_contains "status: computed round beyond the cap -> escalation-required" "$OUT" "status=escalation-required"
assert_contains "status: pending connector review blocks readiness" "$OUT" "has not reviewed the current head"

OUT=$("$RUNNER" collect --json --from-file "$TMPROOT/in170.json" 2>/dev/null)
assert_eq "collect --json: header.round" "$(printf '%s' "$OUT" | jq -r .header.round)" 3
assert_eq "collect --json: header.cap_reached" "$(printf '%s' "$OUT" | jq -r .header.cap_reached)" true
assert_eq "collect --json: findings count" "$(printf '%s' "$OUT" | jq -r '.findings | length')" 6
assert_eq "collect --json: sorted P1 first" "$(printf '%s' "$OUT" | jq -r '.findings[0].prio')" P1

# ---------- 3. collect through stub gh (live path, fork-safe repo from URL) ----------
BEFORE=$(gh_lines)
OUT=$(GH_REVIEWS=reviews-pending "$RUNNER" collect 170 2>&1); RC=$?
assert_eq "collect live: exit 0" "$RC" 0
assert_contains "collect live: passes=3" "$OUT" "passes=3"
assert_contains "collect live: REST path uses base repo from URL" "$(cat "$GH_LOG")" "repos/acme/ocms-go/pulls/170/reviews"
assert_contains "collect live: graphql owner variable" "$(cat "$GH_LOG")" "owner=acme"
assert_ne "collect live: gh was called" "$(gh_lines)" "$BEFORE"

# ---------- 4. fresh PR with current fixture (PR 171) ----------
mkinput reviews-current 171 feature-171 > "$TMPROOT/in171.json"
OUT=$("$RUNNER" collect --from-file "$TMPROOT/in171.json" 2>&1)
assert_contains "collect 171: round=1" "$OUT" "round=1"
assert_contains "collect 171: cap_reached=false" "$OUT" "cap_reached=false"
assert_contains "collect 171: pending=false (latest commit == head)" "$OUT" "pending=false"

# ---------- 5. triage ----------
OUT=$(PRF_PR=171 "$RUNNER" triage PRRT_T1 FIX --note "long-form delete" --file dsh-git-guard/git-guard.py 2>&1); RC=$?
assert_eq "triage: FIX recorded" "$RC" 0
assert_eq "triage: state has disposition" "$(jq -r '.threads.PRRT_T1.disposition.kind' "$REPO/.audit/pr-171/state.json")" FIX
OUT=$(PRF_PR=171 "$RUNNER" triage PRRT_T2 FIX --file scripts/install-git-guard.sh 2>&1)
assert_contains "triage: P2 FIX prints the P2 rule reminder" "$OUT" "P2 rule"
PRF_PR=171 "$RUNNER" triage 'foo;rm -rf x' FIX >/dev/null 2>&1; RC=$?
assert_eq "triage: invalid id rejected" "$RC" 1
PRF_PR=171 "$RUNNER" triage PRRT_NOPE FIX >/dev/null 2>&1; RC=$?
assert_eq "triage: unknown thread rejected" "$RC" 1
PRF_PR=171 "$RUNNER" triage PRRT_T4 BOGUS >/dev/null 2>&1; RC=$?
assert_eq "triage: invalid disposition rejected" "$RC" 1

# ---------- 6. logged pushes drive the round; [FIXED r1] tag ----------
PRF_PR=171 "$RUNNER" record-push >/dev/null 2>&1
OUT=$("$RUNNER" collect --from-file "$TMPROOT/in171.json" 2>&1)
assert_contains "collect 171 after 1 push: round=2" "$OUT" "round=2"
assert_contains "collect 171: earlier FIX tagged [FIXED r1]" "$OUT" "Match long-form branch deletion before allowing it (thread PRRT_T1, chatgpt-codex-connector, https://github.com/acme/ocms-go/pull/170#discussion_r1) [FIXED r1]"
PRF_PR=171 "$RUNNER" record-push >/dev/null 2>&1
OUT=$("$RUNNER" collect --from-file "$TMPROOT/in171.json" 2>&1)
assert_contains "collect 171 after 2 pushes: round=3 (pushes win over passes=1)" "$OUT" "round=3"
assert_contains "collect 171 after 2 pushes: cap_reached=true" "$OUT" "cap_reached=true"
OUT=$(PRF_PR=171 "$RUNNER" record-push --undo 2>&1)
assert_contains "record-push --undo: drops the last push" "$OUT" "1 remain"
assert_eq "record-push --undo: head restored to the previous push" "$(jq -r '.head == .pushes[-1].sha' "$REPO/.audit/pr-171/state.json")" true
jq '.latest_connector_commit = .head' "$REPO/.audit/pr-171/state.json" > "$TMPROOT/s.json" && mv "$TMPROOT/s.json" "$REPO/.audit/pr-171/state.json"
PRF_PR=171 "$RUNNER" record-push >/dev/null 2>&1
PRF_PR=171 "$RUNNER" record-push --undo >/dev/null 2>&1
assert_eq "record-push --undo: pending cleared when the restored head was reviewed" "$(jq -r '.pending' "$REPO/.audit/pr-171/state.json")" false
OUT=$(PRF_PR=171 "$RUNNER" override 2>&1)
assert_contains "override: grants one more push" "$OUT" "may now use 3 fix pushes"
PRF_PR=171 "$RUNNER" record-push >/dev/null 2>&1
OUT=$("$RUNNER" collect --from-file "$TMPROOT/in171.json" 2>&1)
assert_contains "collect: override raises the cap (round 3 of 3 not capped)" "$OUT" "cap_reached=false"
PRF_PR=171 "$RUNNER" record-push >/dev/null 2>&1

# ---------- 7. check ----------
OUT=$(PRF_PR=171 "$RUNNER" check -- "true" "false" 2>&1); RC=$?
assert_ne "check: failing command makes exit non-zero" "$RC" 0
assert_eq "check: two entries recorded" "$(jq -r '.checks | length' "$REPO/.audit/pr-171/state.json")" 2
assert_eq "check: exit codes recorded" "$(jq -r '[.checks[].exit] | join(",")' "$REPO/.audit/pr-171/state.json")" "0,1"
OUT=$(PRF_PR=171 "$RUNNER" check --none "docs only" 2>&1); RC=$?
assert_eq "check --none: exit 0" "$RC" 0
assert_eq "check --none: waiver recorded" "$(jq -r '.checks[-1].waived' "$REPO/.audit/pr-171/state.json")" "docs only"
PRF_PR=171 "$RUNNER" check --note "pre-existing debt" -- "false" >/dev/null 2>&1
assert_eq "check --note: baseline note recorded" "$(jq -r '.checks[-1].note' "$REPO/.audit/pr-171/state.json")" "pre-existing debt"

# ---------- 8. review --dry-run (PR 172) ----------
mkinput reviews-current 172 feature-172 > "$TMPROOT/in172.json"
"$RUNNER" collect --from-file "$TMPROOT/in172.json" >/dev/null 2>&1
FLAKY="test -e $TMPROOT/flaky-ok"
PRF_PR=172 "$RUNNER" check -- "$FLAKY" >/dev/null 2>&1
OUT=$(PRF_PR=172 "$RUNNER" status 2>&1)
assert_contains "status: latest failing check counts" "$OUT" "whose latest run failed"
touch "$TMPROOT/flaky-ok"
PRF_PR=172 "$RUNNER" check -- "$FLAKY" >/dev/null 2>&1
OUT=$(PRF_PR=172 "$RUNNER" status 2>&1)
assert_not_contains "status: a passing rerun supersedes the earlier failure" "$OUT" "whose latest run failed"
OUT=$(PRF_PR=172 "$RUNNER" review --dry-run --base main 2>&1); RC=$?
assert_eq "review --dry-run: exit 0" "$RC" 0
assert_contains "review argv: read-only sandbox" "$OUT" "read-only"
assert_contains "review argv: -a never" "$OUT" "never"
assert_contains "review argv: effort high by default" "$OUT" 'model_reasoning_effort="high"'
assert_contains "review argv: developer_instructions passed" "$OUT" "developer_instructions="
assert_contains "review argv: exec review --base main --ephemeral" "$OUT" "--ephemeral"
assert_not_contains "review argv: never --uncommitted" "$OUT" "--uncommitted"
assert_contains "review argv: child guard env" "$OUT" "CODEX_FULL_BRANCH_AUDIT_CHILD=1"
OUT=$(CODEX_REVIEW_EFFORT=medium PRF_PR=172 "$RUNNER" review --dry-run --base main 2>&1)
assert_contains "review argv: effort override" "$OUT" 'model_reasoning_effort="medium"'
OUT=$(CODEX_REVIEW_MODEL=gpt-test PRF_PR=172 "$RUNNER" review --dry-run --base main 2>&1)
assert_contains "review argv: model override" "$OUT" "gpt-test"
OUT=$(PRF_PR=172 "$RUNNER" review --dry-run --base 'main;rm' 2>&1); RC=$?
assert_eq "review: unsafe base ref rejected" "$RC" 1
OUT=$(PRF_PR=172 "$RUNNER" review --dry-run --base origin/main 2>&1)
assert_contains "review: origin/ prefix accepted and stripped" "$OUT" "base=main"
assert_contains "review: codex is pointed at the fetched remote ref" "$OUT" "origin/main"
printf 'tmp\n' > "$REPO/dry-untracked.txt"
OUT=$(PRF_PR=172 "$RUNNER" review --dry-run --base main --include-untracked 2>&1)
assert_contains "review --dry-run --include-untracked: only reports" "$OUT" "would run git add -N"
assert_not_contains "review --dry-run: index untouched" "$(git -C "$REPO" diff --name-only)" "dry-untracked.txt"
rm -f "$REPO/dry-untracked.txt"

# ---------- 9. review with stub codex ----------
OUT=$(CODEX_FIXTURE="$FIX/codex-json.md" PRF_PR=172 "$RUNNER" review --base main --no-fetch 2>&1); RC=$?
assert_eq "review json: exit 10 when P1 present" "$RC" 10
assert_contains "review json: counts" "$OUT" "P0=0 P1=1 P2=1 P3=0 format=json"
N=$(ls "$REPO/.audit/pr-172"/local-review-*.md 2>/dev/null | wc -l | tr -d ' ')
assert_eq "review json: output file under .audit/pr-172" "$N" 1
assert_eq "review json: state.reviews has one entry" "$(jq -r '.reviews | length' "$REPO/.audit/pr-172/state.json")" 1
assert_contains "review json: codex called with exec review" "$(cat "$CODEX_LOG")" "review"
assert_contains "review json: codex called with --base" "$(cat "$CODEX_LOG")" "--base"
assert_file "review json: last-local-review marker" "$REPO/.audit/pr-172/last-local-review"
assert_contains "review json: marker has tree=" "$(cat "$REPO/.audit/pr-172/last-local-review")" "tree="

OUT=$(CODEX_FIXTURE="$FIX/codex-text.md" PRF_PR=172 "$RUNNER" review --base main --no-fetch 2>&1); RC=$?
assert_eq "review text: exit 10" "$RC" 10
assert_contains "review text: counts" "$OUT" "P0=0 P1=1 P2=2 P3=0 format=text"
sleep 1
OUT=$(CODEX_FIXTURE="$FIX/codex-json-title.md" PRF_PR=172 "$RUNNER" review --base main --no-fetch --force 2>&1); RC=$?
assert_contains "review json: priority parsed from [P1] title when .priority is absent" "$OUT" "P0=0 P1=1 P2=0 P3=1 format=json"
assert_eq "review json title: exit 10" "$RC" 10

OUT=$(CODEX_FIXTURE="$FIX/codex-clean.md" PRF_PR=172 "$RUNNER" review --base main --no-fetch 2>&1); RC=$?
assert_eq "review: third run in a round refused (exit 6)" "$RC" 6
OUT=$(CODEX_FIXTURE="$FIX/codex-clean.md" PRF_PR=172 "$RUNNER" review --base main --no-fetch --force 2>&1); RC=$?
assert_eq "review clean --force: exit 0" "$RC" 0
assert_contains "review clean: counts" "$OUT" "P0=0 P1=0"

OUT=$(CODEX_FIXTURE="$FIX/codex-clean.md" CODEX_EXIT=3 PRF_PR=172 "$RUNNER" review --base main --no-fetch --force 2>&1); RC=$?
assert_eq "review: codex failure surfaces as exit 4" "$RC" 4
OUT=$(CODEX_FIXTURE="" PRF_PR=172 "$RUNNER" review --base main --no-fetch --force 2>&1); RC=$?
assert_eq "review: empty output is a failed review (exit 4)" "$RC" 4
assert_contains "review: empty output recorded as format=none" "$OUT" "format=none"

# ---------- 10. review guards: child refusal, lock, untracked ----------
BEFORE=$(codex_lines)
OUT=$(CODEX_FULL_BRANCH_AUDIT_CHILD=1 PRF_PR=172 "$RUNNER" review --dry-run --base main 2>&1); RC=$?
assert_eq "review: refuses inside another reviewer (exit 2)" "$RC" 2
OUT=$(PRF_CHILD=1 PRF_PR=172 "$RUNNER" review --dry-run --base main 2>&1); RC=$?
assert_eq "review: refuses when PRF_CHILD=1" "$RC" 2
assert_eq "review: no codex call while refused" "$(codex_lines)" "$BEFORE"

mkdir -p "$REPO/.audit/pr-172/review.lock" && printf '%s' "$$" > "$REPO/.audit/pr-172/review.lock/pid"
OUT=$(CODEX_FIXTURE="$FIX/codex-clean.md" PRF_PR=172 "$RUNNER" review --base main --no-fetch --force 2>&1); RC=$?
assert_eq "review: live lock blocks a duplicate run (exit 7)" "$RC" 7
rm -rf "$REPO/.audit/pr-172/review.lock"

printf 'new\n' > "$REPO/newfile.txt"
OUT=$(CODEX_FIXTURE="$FIX/codex-clean.md" PRF_PR=172 "$RUNNER" review --base main --no-fetch --force 2>&1); RC=$?
assert_eq "review: untracked file -> exit 5" "$RC" 5
assert_contains "review: untracked hint names git add -N" "$OUT" "git add -N"
OUT=$(CODEX_FIXTURE="$FIX/codex-clean.md" PRF_PR=172 "$RUNNER" review --base main --no-fetch --force --include-untracked 2>&1); RC=$?
assert_eq "review --include-untracked: proceeds" "$RC" 0
assert_contains "review --include-untracked: file is intent-to-add" "$(git -C "$REPO" diff --name-only)" "newfile.txt"
git -C "$REPO" rm -q --cached newfile.txt 2>/dev/null; rm -f "$REPO/newfile.txt"

# ---------- 11. fingerprint equals the tree of an identical-content commit ----------
printf 'edited\n' >> "$REPO/a.txt"
OUT=$(CODEX_FIXTURE="$FIX/codex-clean.md" PRF_PR=172 "$RUNNER" review --base main --no-fetch --force 2>&1)
REVIEWED_TREE=$(jq -r '.reviews[-1].tree' "$REPO/.audit/pr-172/state.json")
OLD_TREE=$(git -C "$REPO" rev-parse 'HEAD^{tree}')
git -C "$REPO" add -A && git -C "$REPO" commit -q -m "edit"
assert_eq "fingerprint: reviewed tree == committed tree" "$(git -C "$REPO" rev-parse 'HEAD^{tree}')" "$REVIEWED_TREE"
assert_ne "fingerprint: differs from the previous commit" "$REVIEWED_TREE" "$OLD_TREE"

# ---------- 12. status transitions (PR 173, head_ref = feature for the hook) ----------
mkinput reviews-current 173 feature > "$TMPROOT/in173.json"
"$RUNNER" collect --from-file "$TMPROOT/in173.json" >/dev/null 2>&1
OUT=$("$RUNNER" status 2>&1); RC=$?
assert_contains "status: incomplete while threads lack dispositions" "$OUT" "status=incomplete"
assert_eq "status: non-zero when not ready" "$RC" 1
for t in PRRT_T1 PRRT_T2 PRRT_T4 PRRT_T5 PRRT_T6 PRRT_T7; do "$RUNNER" triage "$t" REJECT --note "test" >/dev/null 2>&1; done
OUT=$("$RUNNER" status 2>&1)
assert_contains "status: incomplete without a check this round" "$OUT" "status=incomplete"
assert_contains "status: reason names the missing check" "$OUT" "no deterministic check"
"$RUNNER" check --none "test waiver" >/dev/null 2>&1
OUT=$("$RUNNER" status 2>&1)
assert_contains "status: needs-fix without a local review" "$OUT" "status=needs-fix"
CODEX_FIXTURE="$FIX/codex-json.md" "$RUNNER" review --base main --no-fetch >/dev/null 2>&1
OUT=$("$RUNNER" status 2>&1)
assert_contains "status: needs-fix while review P1 is untriaged" "$OUT" "status=needs-fix"
"$RUNNER" triage local REJECT --note "P1 is outside the PR diff" >/dev/null 2>&1
OUT=$("$RUNNER" status 2>&1); RC=$?
assert_contains "status: ready after leftovers are triaged" "$OUT" "status=ready"
assert_eq "status: exit 0 when ready" "$RC" 0
printf 'more\n' >> "$REPO/a.txt"
OUT=$("$RUNNER" status 2>&1)
assert_contains "status: checks are bound to the tree (edit -> incomplete)" "$OUT" "status=incomplete"
assert_contains "status: reason names the current tree" "$OUT" "no deterministic check recorded for the current tree"
"$RUNNER" check --none "re-waived after edit" >/dev/null 2>&1
OUT=$("$RUNNER" status 2>&1)
assert_contains "status: stale after an edit once checks are current" "$OUT" "status=stale"
CODEX_FIXTURE="$FIX/codex-clean.md" CODEX_EXIT=3 "$RUNNER" review --base main --no-fetch >/dev/null 2>&1
OUT=$("$RUNNER" status 2>&1)
assert_contains "status: failed codex run is not a usable review" "$OUT" "status=needs-fix"
assert_contains "status: reason names the failed review" "$OUT" "last local review failed"
CODEX_FIXTURE="$FIX/codex-clean.md" "$RUNNER" review --base main --no-fetch --force >/dev/null 2>&1
OUT=$("$RUNNER" status --report 2>&1); RC=$?
assert_contains "status: ready after the second review" "$OUT" "status=ready"
assert_file "status --report: round-1.md written" "$REPO/.audit/pr-173/round-1.md"
assert_contains "report: lists dispositions" "$(cat "$REPO/.audit/pr-173/round-1.md")" "REJECT r1"
assert_contains "report: lists local reviews" "$(cat "$REPO/.audit/pr-173/round-1.md")" "effort=high"

# P2 rule warning: a FIX on a P2 thread whose file has two hunks
PRF_PR=171 "$RUNNER" triage PRRT_T2 FIX >/dev/null 2>&1   # no --file: falls back to the thread path
perl -pi -e 's/^line 2$/line two/; s/^line 28$/line twenty-eight/' "$REPO/scripts/install-git-guard.sh"   # portable in-place edit
OUT=$(PRF_PR=171 "$RUNNER" status 2>&1)
assert_contains "status: warns when a P2 fix spans two hunks" "$OUT" "warning: P2 fix in scripts/install-git-guard.sh spans 2 hunks"
git -C "$REPO" checkout -q -- scripts/install-git-guard.sh

# ---------- 13. pre-push gate (runner body) ----------
git -C "$REPO" add -A && git -C "$REPO" commit -q -m "fix round 1"
HEAD_SHA=$(git -C "$REPO" rev-parse HEAD)
OLD_SHA=$(git -C "$REPO" rev-parse HEAD~1)
ZERO=0000000000000000000000000000000000000000

# unarmed repository: no state, no gh calls
mkdir -p "$TMPROOT/repo2" && git -C "$TMPROOT/repo2" init -q && git -C "$TMPROOT/repo2" config user.email t@example.com && git -C "$TMPROOT/repo2" config user.name t
git -C "$TMPROOT/repo2" commit -q --allow-empty -m init
BEFORE=$(gh_lines)
OUT=$(cd "$TMPROOT/repo2" && printf 'refs/heads/main %s refs/heads/main %s\n' "$(git rev-parse HEAD)" "$ZERO" | "$RUNNER" pre-push 2>&1); RC=$?
assert_eq "pre-push: unarmed repo allows" "$RC" 0
assert_eq "pre-push: unarmed repo never calls gh" "$(gh_lines)" "$BEFORE"

# armed, ready, matching tree
OUT=$(printf 'HEAD %s refs/heads/feature %s\n' "$HEAD_SHA" "$OLD_SHA" | "$RUNNER" pre-push 2>&1); RC=$?
assert_eq "pre-push: ready + reviewed tree allows (matched on the destination ref)" "$RC" 0
assert_eq "pre-push: recorded push marks the head pending" "$(jq -r '.pending' "$REPO/.audit/pr-173/state.json")" true
assert_eq "pre-push: push recorded" "$(jq -r '.pushes | length' "$REPO/.audit/pr-173/state.json")" 1
assert_eq "pre-push: recorded sha" "$(jq -r '.pushes[0].sha' "$REPO/.audit/pr-173/state.json")" "$HEAD_SHA"

# same commit again but working tree untouched: mismatch only when content changes
printf 'unreviewed\n' >> "$REPO/a.txt" && git -C "$REPO" commit -q -am "unreviewed"
NEW_SHA=$(git -C "$REPO" rev-parse HEAD)
OUT=$(printf 'refs/heads/feature %s refs/heads/feature %s\n' "$NEW_SHA" "$HEAD_SHA" | "$RUNNER" pre-push 2>&1); RC=$?
assert_eq "pre-push: unreviewed tree blocked" "$RC" 1
assert_contains "pre-push: refusal message" "$OUT" "refusing feature (PR #173)"
assert_contains "pre-push: after a push the new head awaits the connector (pending)" "$OUT" "has not reviewed the current head"
assert_eq "pre-push: blocked push not recorded" "$(jq -r '.pushes | length' "$REPO/.audit/pr-173/state.json")" 1

OUT=$(printf 'refs/heads/feature %s refs/heads/feature %s\n' "$NEW_SHA" "$HEAD_SHA" | PRF_SKIP_PUSH_GATE=1 "$RUNNER" pre-push 2>&1); RC=$?
assert_eq "pre-push: PRF_SKIP_PUSH_GATE=1 bypasses" "$RC" 0
jq '.head_repo = "forker/ocms-go"' "$REPO/.audit/pr-173/state.json" > "$TMPROOT/s.json" && mv "$TMPROOT/s.json" "$REPO/.audit/pr-173/state.json"
OUT=$(printf 'refs/heads/feature %s refs/heads/feature %s\n' "$NEW_SHA" "$HEAD_SHA" | "$RUNNER" pre-push fork git@github.com:forker/ocms-go.git 2>&1); RC=$?
assert_eq "pre-push: a push to the fork head repository is gated" "$RC" 1
OUT=$(printf 'refs/heads/feature %s refs/heads/feature %s\n' "$NEW_SHA" "$HEAD_SHA" | "$RUNNER" pre-push backup git@github.com:someone/backup-mirror.git 2>&1); RC=$?
assert_eq "pre-push: a push to another remote is not gated" "$RC" 0
assert_contains "pre-push: other remote reported as not counted" "$OUT" "not counted"
OUT=$(printf 'refs/heads/feature %s refs/heads/feature %s\n' "$NEW_SHA" "$HEAD_SHA" | "$RUNNER" pre-push mirror https://github.com/acme/ocms-go-mirror.git 2>&1); RC=$?
assert_eq "pre-push: a remote whose name merely contains the slug is not gated" "$RC" 0
assert_contains "pre-push: exact slug reported" "$OUT" "(acme/ocms-go-mirror)"
OUT=$(printf 'refs/heads/feature %s refs/heads/feature %s\n' "$NEW_SHA" "$HEAD_SHA" | "$RUNNER" pre-push origin ssh://git@github.com/Acme/ocms-go.git 2>&1); RC=$?
assert_eq "pre-push: ssh URL of the PR repository is gated (case-insensitive)" "$RC" 1
OUT=$(printf 'refs/heads/feature %s refs/heads/feature %s\n' "$NEW_SHA" "$HEAD_SHA" | "$RUNNER" pre-push origin https://github.com/acme/ocms-go/ 2>&1); RC=$?
assert_eq "pre-push: trailing slash in the remote URL still matches" "$RC" 1
OUT=$(printf 'refs/heads/feature %s refs/heads/feature %s\n' "$NEW_SHA" "$HEAD_SHA" | "$RUNNER" pre-push gh github:acme/ocms-go.git 2>&1); RC=$?
assert_eq "pre-push: scp-style remote without a user is gated" "$RC" 1
# the review base comes from the remote matching the PR base repository, not from origin
git -C "$REPO" remote add upstream https://github.com/acme/ocms-go.git
git -C "$REPO" remote set-url origin git@github.com:forker/ocms-go.git
git -C "$REPO" update-ref refs/remotes/upstream/main main
OUT=$(PRF_PR=173 "$RUNNER" review --dry-run --base main 2>&1)
assert_contains "review: base ref taken from the PR base repository's remote" "$OUT" "remote=upstream review_base=upstream/main"
git -C "$REPO" update-ref -d refs/remotes/upstream/main
git -C "$REPO" remote set-url origin "$ORIGIN"
git -C "$REPO" remote remove upstream
assert_eq "pre-push: other remote not recorded" "$(jq -r '.pushes | length' "$REPO/.audit/pr-173/state.json")" 1
OUT=$(printf 'refs/heads/feature %s refs/heads/feature %s\nrefs/tags/v1 %s refs/tags/v1 %s\n' "$ZERO" "$HEAD_SHA" "$NEW_SHA" "$ZERO" | "$RUNNER" pre-push 2>&1); RC=$?
assert_eq "pre-push: delete and tag refs are skipped" "$RC" 0
ZERO256=0000000000000000000000000000000000000000000000000000000000000000
OUT=$(printf 'refs/heads/feature %s refs/heads/feature %s\n' "$ZERO256" "$HEAD_SHA" | "$RUNNER" pre-push 2>&1); RC=$?
assert_eq "pre-push: SHA-256 deletion object name is skipped" "$RC" 0
assert_eq "pre-push: SHA-256 deletion not recorded" "$(jq -r '.pushes | length' "$REPO/.audit/pr-173/state.json")" 1

# second round: a fresh collect clears pending (fixture head == latest reviewed), then check + review the new head
"$RUNNER" collect --from-file "$TMPROOT/in173.json" >/dev/null 2>&1
"$RUNNER" check --none "round 2" >/dev/null 2>&1
CODEX_FIXTURE="$FIX/codex-clean.md" "$RUNNER" review --base main --no-fetch >/dev/null 2>&1
OUT=$(printf 'refs/heads/feature %s refs/heads/feature %s\n' "$NEW_SHA" "$HEAD_SHA" | "$RUNNER" pre-push 2>&1); RC=$?
assert_eq "pre-push: second round allowed" "$RC" 0
assert_eq "pre-push: two pushes recorded" "$(jq -r '.pushes | length' "$REPO/.audit/pr-173/state.json")" 2
OUT=$("$RUNNER" status 2>&1)
assert_contains "status: escalation-required at the cap" "$OUT" "status=escalation-required"
OUT=$("$RUNNER" collect --from-file "$TMPROOT/in173.json" 2>&1)
assert_contains "collect: round=3 after two pushes" "$OUT" "round=3"
"$RUNNER" check --none "round 3" >/dev/null 2>&1
CODEX_FIXTURE="$FIX/codex-clean.md" "$RUNNER" review --base main --no-fetch >/dev/null 2>&1
OUT=$(printf 'refs/heads/feature %s refs/heads/feature %s\n' "$NEW_SHA" "$HEAD_SHA" | "$RUNNER" pre-push 2>&1); RC=$?
assert_eq "pre-push: third push blocked by the cap" "$RC" 1
assert_contains "pre-push: cap reason" "$OUT" "exceed the cap"

# ---------- 13b. fallback state directory when .audit is not ignored ----------
BEFORE=$(gh_lines)
OUT=$(cd "$TMPROOT/repo2" && XDG_STATE_HOME="$TMPROOT/state" "$RUNNER" collect --from-file "$TMPROOT/in171.json" 2>&1)
assert_contains "fallback: warns that .audit is not ignored" "$OUT" "not gitignored"
FB=$(ls -d "$TMPROOT/state/pr-fix"/repo2-* 2>/dev/null | head -1)
assert_ne "fallback: state dir under XDG_STATE_HOME with repo hash" "$FB" ""
assert_eq "fallback: state dir is private (700)" "$(perm_of "$FB/pr-171")" 700
assert_eq "fallback: state file is private (600)" "$(perm_of "$FB/pr-171/state.json")" 600
assert_no_file "fallback: nothing written under the repo" "$TMPROOT/repo2/.audit"
OUT=$(cd "$TMPROOT/repo2" && printf 'refs/heads/other %s refs/heads/other %s\n' "$(git rev-parse HEAD)" "$ZERO" | XDG_STATE_HOME="$TMPROOT/state" "$RUNNER" pre-push 2>&1); RC=$?
assert_eq "pre-push: branch without matching state is unarmed" "$RC" 0
assert_eq "pre-push: no gh lookup for unmatched branches" "$(gh_lines)" "$BEFORE"

# ---------- 14. hook wrapper: runs the runner and chains the repo's own hook ----------
cat > "$TMPROOT/repo2/.git/hooks/pre-push" <<'CHAIN'
#!/bin/sh
cat > "$CHAIN_LOG"
exit 0
CHAIN
chmod +x "$TMPROOT/repo2/.git/hooks/pre-push"
export CHAIN_LOG="$TMPROOT/chain.log"
OUT=$(cd "$TMPROOT/repo2" && printf 'refs/heads/main %s refs/heads/main %s\n' "$(git rev-parse HEAD)" "$ZERO" | PRF_RUNNER="$RUNNER" "$HOOK" origin file:///dev/null 2>&1); RC=$?
assert_eq "hook wrapper: allows in an unarmed repo" "$RC" 0
assert_contains "hook wrapper: chained hook received the same stdin" "$(cat "$CHAIN_LOG" 2>/dev/null)" "refs/heads/main"
OUT=$(cd "$REPO" && printf 'refs/heads/feature %s refs/heads/feature %s\n' "$NEW_SHA" "$HEAD_SHA" | PRF_RUNNER="$RUNNER" "$HOOK" origin https://github.com/acme/ocms-go.git 2>&1); RC=$?
assert_eq "hook wrapper: propagates a block" "$RC" 1
OUT=$(cd "$TMPROOT/repo2" && printf 'refs/heads/main %s refs/heads/main %s\n' "$(git rev-parse HEAD)" "$ZERO" | PRF_RUNNER=/nonexistent/pr-fix.sh HOME="$TMPROOT/nohome" "$HOOK" origin x 2>&1); RC=$?
assert_eq "hook wrapper: missing runner fails open" "$RC" 0
assert_contains "hook wrapper: missing runner notice" "$OUT" "runner not found"

# a repository hook that is a symlink to this very wrapper must not run the gate twice
ln -sf "$HOOK" "$TMPROOT/repo2/.git/hooks/pre-push"
OUT=$(cd "$TMPROOT/repo2" && printf 'refs/heads/main %s refs/heads/main %s\n' "$(git rev-parse HEAD)" "$ZERO" | PRF_RUNNER="$RUNNER" "$HOOK" origin x 2>&1); RC=$?
assert_eq "hook wrapper: symlinked copy of itself is not chained" "$RC" 0
assert_not_contains "hook wrapper: no recursion notice" "$OUT" "runner not found"

# ---------- 15. close ----------
BEFORE=$(gh_lines)
OUT=$(printf 'Fixed in abc1234: test\n' | PRF_PR=171 "$RUNNER" close PRRT_T1 --reply-stdin --resolve --dry-run 2>&1); RC=$?
assert_eq "close --dry-run: exit 0" "$RC" 0
assert_contains "close --dry-run: would reply" "$OUT" "would reply thread=PRRT_T1"
assert_contains "close --dry-run: would resolve" "$OUT" "would resolve thread=PRRT_T1"
assert_eq "close --dry-run: no gh calls" "$(gh_lines)" "$BEFORE"
PRF_PR=171 "$RUNNER" close 'foo;rm' --resolve --dry-run >/dev/null 2>&1; RC=$?
assert_ne "close: invalid thread id rejected" "$RC" 0
printf 'Fixed in abc1234: long-form delete\n' > "$TMPROOT/reply1.md"
OUT=$(PRF_PR=171 "$RUNNER" close PRRT_T1 --reply-file "$TMPROOT/reply1.md" --resolve 2>&1); RC=$?
assert_eq "close: real reply+resolve exit 0" "$RC" 0
assert_contains "close: body passed as a file variable" "$(cat "$GH_LOG")" "-F body=@"
assert_contains "close: thread id passed as a variable" "$(cat "$GH_LOG")" "-f threadId=PRRT_T1"
assert_eq "close: state records closure" "$(jq -r '.threads.PRRT_T1.closed.resolved' "$REPO/.audit/pr-171/state.json")" true
BEFORE=$(gh_lines)
OUT=$(PRF_PR=171 "$RUNNER" close PRRT_T1 --reply-file "$TMPROOT/reply1.md" --resolve 2>&1); RC=$?
assert_eq "close: retry of a closed thread is a no-op" "$RC" 0
assert_contains "close: retry reports already closed" "$OUT" "already closed thread=PRRT_T1"
assert_ne "close: reply url persisted" "$(jq -r '.threads.PRRT_T1.closed.reply_url // ""' "$REPO/.audit/pr-171/state.json")" ""
jq '.threads.PRRT_T2.closed = {reply_url: "https://x/r", replied_ts: "t"}' "$REPO/.audit/pr-171/state.json" > "$TMPROOT/s.json" && mv "$TMPROOT/s.json" "$REPO/.audit/pr-171/state.json"
"$RUNNER" collect --from-file "$TMPROOT/in171.json" >/dev/null 2>&1
assert_eq "collect: unresolved reply bookkeeping survives a refresh" "$(jq -r '.threads.PRRT_T2.closed.reply_url // ""' "$REPO/.audit/pr-171/state.json")" "https://x/r"
assert_eq "collect: a resolved-then-reopened thread drops its closure" "$(jq -r '.threads.PRRT_T1.closed // "gone"' "$REPO/.audit/pr-171/state.json")" "gone"
assert_eq "close: retry posts nothing" "$(gh_lines)" "$BEFORE"
printf '{"thread":"PRRT_BAD1","reply":"x","resolve":true}\n{"thread":"PRRT_T2","reply":"Not changing: test","resolve":true}\n' > "$TMPROOT/closes.jsonl"
OUT=$(GH_FAIL_ID=PRRT_BAD1 PRF_PR=171 "$RUNNER" close --batch "$TMPROOT/closes.jsonl" 2>&1); RC=$?
assert_eq "close --batch: exit 2 when one thread fails" "$RC" 2
assert_contains "close --batch: other thread still processed" "$OUT" "resolved thread=PRRT_T2"

# ---------- summary ----------
TOTAL=$((PASS + FAIL))
printf '\n%d/%d passed\n' "$PASS" "$TOTAL"
[ "$FAIL" -eq 0 ]
