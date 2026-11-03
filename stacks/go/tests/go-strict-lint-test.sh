#!/bin/bash
# Tests for stacks/go/hooks/go-strict-lint.sh.
#
# A stub replaces golangci-lint through GO_STRICT_LINT_BIN, so the suite needs
# git and jq but no network or Go build. It covers command matching, repository
# and module discovery, the comparison base, exit-code mapping and --check.
#
# Run from anywhere:
#   bash stacks/go/tests/go-strict-lint-test.sh

set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
HOOK="$SCRIPT_DIR/../hooks/go-strict-lint.sh"
TMPROOT=$(cd -P "$(mktemp -d "${TMPDIR:-/tmp}/go-strict-lint-test.XXXXXX")" && pwd)
trap 'rm -rf "$TMPROOT"' EXIT INT TERM

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); echo "ok   $1"; }
fail() { FAIL=$((FAIL + 1)); echo "FAIL $1" >&2; }

# Isolate git from the user's configuration and hooks.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com

STUB=$TMPROOT/stub-golangci
cat >"$STUB" <<'EOF'
#!/bin/sh
printf '%s|%s\n' "$PWD" "$*" >>"$STUB_LOG"
if [ -n "${STUB_OUT:-}" ]; then printf '%s\n' "$STUB_OUT"; fi
exit "${STUB_RC:-0}"
EOF
chmod +x "$STUB"
export GO_STRICT_LINT_BIN=$STUB STUB_LOG=$TMPROOT/stub.log

PLAIN=$TMPROOT/plain
REPO=$TMPROOT/repo
mkdir -p "$PLAIN" "$REPO/sub"
(
  cd "$REPO" &&
    git init -q -b main &&
    printf 'module example.com/m\n\ngo 1.22\n' >go.mod &&
    printf 'package m\n' >a.go &&
    printf 'module example.com/sub\n\ngo 1.22\n' >sub/go.mod &&
    printf 'package sub\n' >sub/b.go &&
    printf 'ignored.go\n' >.gitignore &&
    printf 'readme\n' >README.md &&
    git add . && git commit -q -m base &&
    git switch -q -c feature
) || { echo "FAIL: fixture setup" >&2; exit 1; }
BASE=$(git -C "$REPO" rev-parse main)

# run_hook COMMAND CWD: sets RC, ERR (stderr) and CALLS (stub invocations).
run_hook() {
  : >"$STUB_LOG"
  ERR=$(jq -n --arg c "$1" --arg d "$2" '{tool_input: {command: $c}, cwd: $d}' |
    bash "$HOOK" 2>&1 >/dev/null)
  RC=$?
  CALLS=$(cat "$STUB_LOG")
}

expect() { # NAME CONDITION...
  local name=$1
  shift
  if "$@"; then pass "$name"; else fail "$name (rc=$RC calls=[$CALLS] err=[$ERR])"; fi
}
not_called() { [[ $RC -eq 0 && -z $CALLS ]]; }
blocked_with() { [[ $RC -eq 2 && $ERR == *"$1"* ]]; }
check_out() { [[ $RC -eq $1 && $OUT == *"$2"* ]]; }
absent() { ! grep -q -- "$1" "$STUB_LOG"; }

# Commands that are not commits pass without running the linter.
export STUB_RC=1 STUB_OUT="a.go:1:1: synthetic finding (errcheck)"
printf 'package m\n\nvar x = 1\n' >"$REPO/a.go"
run_hook "ls -la" "$REPO"
expect "non-git command passes" not_called
run_hook "git commit-tree HEAD^{tree} -m x" "$REPO"
expect "git commit-tree is not a commit" not_called
run_hook "git log --grep commit" "$REPO"
expect "git log mentioning commit passes" not_called
run_hook "git commit -m x" "$PLAIN"
expect "commit outside a repository passes" not_called

# Findings, clean runs and failures in a touched module.
run_hook "git commit -am x" "$REPO"
expect "findings block the commit" blocked_with "synthetic finding"
expect "stub ran in the root module" [ "${CALLS%%|*}" = "$REPO" ]
expect "base is the merge-base with main" grep -q -- "--new-from-rev $BASE --whole-files" "$STUB_LOG"
expect "config file has a .yml extension" grep -q -- "-c [^ ]*/golangci.yml " "$STUB_LOG"
STUB_RC=0 run_hook "git commit -am x" "$REPO"
expect "clean lint allows the commit" [ "$RC" -eq 0 ]
STUB_RC=3 run_hook "git commit -am x" "$REPO"
expect "linter failure blocks as could-not-run" blocked_with "could not run"
GO_STRICT_LINT_BIN=$TMPROOT/missing run_hook "git commit -am x" "$REPO"
expect "missing linter blocks as could-not-run" blocked_with "could not run"

# Repository discovery from the command.
run_hook "git -C $REPO commit -m x" "$PLAIN"
expect "git -C DIR commit finds the repository" blocked_with "synthetic finding"
run_hook "cd $REPO && git commit -m x" "$PLAIN"
expect "cd DIR && git commit finds the repository" blocked_with "synthetic finding"
ln -s "$REPO" "$TMPROOT/my repo"
run_hook "git -C \"$TMPROOT/my repo\" commit -m x" "$PLAIN"
expect "git -C with a quoted path containing spaces matches" blocked_with "synthetic finding"
run_hook "cd '$TMPROOT/my repo' && git commit -m x" "$PLAIN"
expect "cd with a quoted path containing spaces finds the repository" blocked_with "synthetic finding"
HOME=$TMPROOT run_hook "cd ~/repo && git commit -m x" "$PLAIN"
expect "cd ~/DIR expands the home directory" blocked_with "synthetic finding"
run_hook "GIT_EDITOR=true git commit" "$REPO"
expect "env assignment before git commit matches" blocked_with "synthetic finding"
run_hook "git add a.go; git commit -m x" "$REPO"
expect "commit after ; matches" blocked_with "synthetic finding"

# Module selection.
git -C "$REPO" checkout -q -- a.go
printf 'readme 2\n' >"$REPO/README.md"
run_hook "git commit -am x" "$REPO"
expect "no touched Go files skips the linter" not_called
printf 'package sub\n\nvar y = 2\n' >"$REPO/sub/b.go"
run_hook "git commit -am x" "$REPO"
expect "touched nested module lints only that module" [ "${CALLS%%|*}" = "$REPO/sub" ]
expect "nested module call is the only call" [ "$(wc -l <"$STUB_LOG" | tr -d ' ')" -eq 1 ]
git -C "$REPO" checkout -q -- sub/b.go
printf 'package m\n' >"$REPO/ignored.go"
run_hook "git commit -am x" "$REPO"
expect "ignored untracked Go file is not touched" not_called
printf 'package m\n' >"$REPO/c.go"
run_hook "git commit -am x" "$REPO"
expect "untracked new Go file is touched" blocked_with "synthetic finding"
rm -f "$REPO/c.go" "$REPO/ignored.go"

# --check mode.
printf 'package m\n\nvar x = 1\n' >"$REPO/a.go"
: >"$STUB_LOG"
OUT=$(cd "$REPO" && bash "$HOOK" --check 2>&1)
RC=$?
expect "--check reports findings with exit 1" check_out 1 "synthetic finding"
OUT=$(cd "$REPO" && STUB_RC=0 bash "$HOOK" --check 2>&1)
RC=$?
expect "--check clean exits 0" [ "$RC" -eq 0 ]
OUT=$(cd "$REPO" && STUB_RC=3 bash "$HOOK" --check 2>&1)
RC=$?
expect "--check failure exits 3" [ "$RC" -eq 3 ]
: >"$STUB_LOG"
(cd "$REPO" && STUB_RC=0 bash "$HOOK" --check HEAD >/dev/null 2>&1)
expect "--check BASE uses that base" grep -q -- "--new-from-rev HEAD --whole-files" "$STUB_LOG"
OUT=$(cd "$REPO" && STUB_RC=0 bash "$HOOK" --check NOT_A_REVISION 2>&1)
RC=$?
expect "--check with an unknown base fails instead of passing" check_out 3 "unknown comparison base"
git -C "$REPO" checkout -q -- a.go

# Without an override, the linter is installed once into the cache with a
# fake `go`. Its stderr noise must not end up in the executable path, and the
# toolchain must be allowed to upgrade to the linter's minimum.
FAKEBIN=$TMPROOT/fakebin
mkdir -p "$FAKEBIN"
cat >"$FAKEBIN/go" <<EOF
#!/bin/sh
case "\$1" in
  env) echo go1.25.0 ;;
  install)
    echo "GOTOOLCHAIN=\$GOTOOLCHAIN" >>"$TMPROOT/go.log"
    echo "go: downloading github.com/golangci/golangci-lint/v2 v2.15.0" >&2
    cp "$STUB" "\$GOBIN/golangci-lint" ;;
esac
EOF
chmod +x "$FAKEBIN/go"
printf 'package m\n\nvar x = 1\n' >"$REPO/a.go"
OLD_PATH=$PATH
export PATH="$FAKEBIN:$PATH" XDG_CACHE_HOME=$TMPROOT/cache
unset GO_STRICT_LINT_BIN
run_hook "git commit -am x" "$REPO"
expect "cold install with stderr noise still runs the linter" blocked_with "synthetic finding"
expect "install allows a toolchain upgrade" grep -q '^GOTOOLCHAIN=go1.25.0+auto$' "$TMPROOT/go.log"
run_hook "git commit -am x" "$REPO"
expect "cached linter is reused" [ "$(wc -l <"$TMPROOT/go.log" | tr -d ' ')" -eq 1 ]
export PATH=$OLD_PATH GO_STRICT_LINT_BIN=$STUB
git -C "$REPO" checkout -q -- a.go

# An unborn repository lints its staged files without a base.
UNBORN=$TMPROOT/unborn
mkdir -p "$UNBORN" && (cd "$UNBORN" && git init -q -b main &&
  printf 'module example.com/u\n\ngo 1.22\n' >go.mod && printf 'package u\n' >u.go && git add .)
run_hook "git commit -m first" "$UNBORN"
expect "unborn repository is linted" blocked_with "synthetic finding"
expect "unborn repository has no base" absent "--new-from-rev"

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
