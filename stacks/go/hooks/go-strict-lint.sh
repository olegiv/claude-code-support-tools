#!/bin/bash
# Strict lint pass for the Go files a change touches.
#
# Reports what IDE inspections such as GoLand show but common golangci-lint
# presets hide: unchecked errors (including Close, os.Remove* and fmt.Fprint*),
# variables that shadow builtins, and malformed package comments. Every finding
# in a touched file counts, not only those on changed lines.
#
#   Hook:  PreToolUse on Bash. Blocks `git commit` (exit 2) while touched Go
#          files have findings or the linter cannot run. Every other command
#          passes through after a JSON parse and a pattern match.
#   CLI:   go-strict-lint.sh --check [BASE]
#          Exit 0 clean, 1 findings, 3 linter could not run.
#
# Touched files are tracked .go files that differ from BASE (default: the
# merge-base of HEAD with origin/HEAD, origin/main, main or master) plus
# untracked, non-ignored .go files. Coverage is best effort:
# - Files are linted as they are in the working tree. A file staged with
#   different content is checked in its working-tree version.
# - A Go file renamed without content changes is not re-linted.
# - A commit made inside a script file is not seen.
# - errcheck keeps its own defaults, which allow prints to stdout and stderr
#   and writes to in-memory buffers.
#
# GO_STRICT_LINT_BIN selects a golangci-lint v2 executable instead of the
# pinned `go run` build; the test suite uses it for a stub. The hook reads it
# from Claude Code's environment, never from the Bash command being checked.
set -euo pipefail

GOLANGCI_VERSION=v2.15.0

config() {
  cat <<'EOF'
version: "2"
run:
  tests: true
  relative-path-mode: gomod
linters:
  default: none
  enable:
    - errcheck
    - govet
    - predeclared
    - revive
    - staticcheck
  settings:
    revive:
      rules:
        - name: package-comments
  exclusions:
    generated: lax
issues:
  max-issues-per-linter: 0
  max-same-issues: 0
EOF
}

# The default comparison base for a repository, or nothing for an unborn HEAD.
default_base() {
  local ref
  git rev-parse -q --verify 'HEAD^{commit}' >/dev/null || return 0
  for ref in origin/HEAD origin/main main master; do
    if git rev-parse -q --verify "$ref^{commit}" >/dev/null; then
      git merge-base HEAD "$ref" && return 0
    fi
  done
  git rev-parse HEAD
}

# Touched .go files, relative to the repository root.
touched_files() {
  local base=$1
  {
    if [[ -n $base ]]; then
      git diff --name-only --diff-filter=ACMR "$base" -- '*.go'
    else
      git ls-files -- '*.go'
    fi
    git ls-files --others --exclude-standard -- '*.go'
  } | sort -u
}

# The directory of the nearest go.mod at or above a file, relative to the root.
module_of() {
  local dir
  dir=$(dirname "$1")
  while :; do
    if [[ -f $dir/go.mod ]]; then
      echo "$dir"
      return 0
    fi
    [[ $dir == . ]] && return 1
    dir=$(dirname "$dir")
  done
}

# The golangci-lint executable for a module directory. Without an override,
# build the pinned version once per Go toolchain into a cache. Start from the
# module's own toolchain, since a build older than the module's go directive
# cannot load it; `+auto` still upgrades when the linter needs a newer Go.
# Running the binary directly keeps its exit code; `go run` would report every
# failure as exit 1, the same as findings.
linter_for() {
  if [[ -n ${GO_STRICT_LINT_BIN:-} ]]; then
    echo "$GO_STRICT_LINT_BIN"
    return 0
  fi
  local gov bindir
  gov=$(cd "$1" && go env GOVERSION) || return 1
  bindir=${XDG_CACHE_HOME:-$HOME/.cache}/go-strict-lint/$GOLANGCI_VERSION-$gov
  if [[ ! -x $bindir/golangci-lint ]]; then
    mkdir -p "$bindir"
    (cd "$1" && GOTOOLCHAIN=$gov+auto GOBIN=$bindir \
      go install "github.com/golangci/golangci-lint/v2/cmd/golangci-lint@$GOLANGCI_VERSION") >&2 || return 1
  fi
  echo "$bindir/golangci-lint"
}

# check DIR [BASE]: print findings; return 0 clean, 1 findings, 3 failure.
check() {
  local dir=$1 base=${2:-} top file module status=0 rc cfg out
  top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || return 0
  cd "$top"
  [[ -n $base ]] || base=$(default_base)
  # An unknown base would make git diff fail inside the enumeration below
  # and report a clean pass without linting anything.
  if [[ -n $base ]] && ! git rev-parse -q --verify "$base^{commit}" >/dev/null; then
    echo "== unknown comparison base: $base"
    return 3
  fi
  local modules=()
  while IFS= read -r file; do
    [[ -n $file ]] || continue
    module=$(module_of "$file") || continue
    [[ " ${modules[*]-} " == *" $module "* ]] || modules+=("$module")
  done < <(touched_files "$base")
  [[ ${#modules[@]} -gt 0 ]] || return 0

  # golangci-lint picks the config format from the file extension.
  cfg=$(mktemp -d "${TMPDIR:-/tmp}/go-strict-lint.XXXXXX")
  # shellcheck disable=SC2064 # Expand now: cfg is local to this function.
  trap "rm -rf '$cfg'" EXIT
  config >"$cfg/golangci.yml"
  local args=(run -c "$cfg/golangci.yml" --issues-exit-code=1)
  [[ -z $base ]] || args+=(--new-from-rev "$base" --whole-files)

  local linter
  for module in "${modules[@]}"; do
    rc=0
    # Keep install diagnostics out of the captured executable path.
    if linter=$(linter_for "$module" 2>"$cfg/install.log"); then
      out=$(cd "$module" && "$linter" "${args[@]}" ./... 2>&1) || rc=$?
    else
      out=$(cat "$cfg/install.log")
      rc=3
    fi
    case $rc in
      0) ;;
      1)
        echo "== $module: findings"
        echo "$out"
        [[ $status -eq 3 ]] || status=1
        ;;
      *)
        echo "== $module: golangci-lint could not run (exit $rc)"
        echo "$out"
        status=3
        ;;
    esac
  done
  return "$status"
}

if [[ ${1:-} == --check ]]; then
  rc=0
  check . "${2:-}" || rc=$?
  exit "$rc"
fi

# Hook mode.
input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null) || command=""

# One shell word: double- or single-quoted (may contain spaces), or bare.
arg_re="(\"[^\"]*\"|'[^']*'|[^[:space:];&|\"']+)"
commit_re="(^|[;&|(]|[[:space:]])git([[:space:]]+-[Cc][[:space:]]+$arg_re)*[[:space:]]+commit([[:space:]]|\$)"
[[ $command =~ $commit_re ]] || exit 0
cwd=$(printf '%s' "$input" | jq -r '.cwd // ""' 2>/dev/null) || cwd=""

# Find the repository: `git -C DIR commit`, a leading `cd DIR &&`, or cwd.
dir=${cwd:-.}
dash_c_re="git[[:space:]]+-C[[:space:]]+$arg_re"
leading_cd_re="^[[:space:]]*cd[[:space:]]+${arg_re}[[:space:]]*(&&|;)"
target=""
if [[ $command =~ $dash_c_re ]]; then
  target=${BASH_REMATCH[1]}
elif [[ $command =~ $leading_cd_re ]]; then
  target=${BASH_REMATCH[1]}
fi
if [[ -n $target ]]; then
  target=${target//[\"\']/}
  # Expand a leading ~ the way the shell would for an unquoted word.
  [[ $target == \~ || $target == \~/* ]] && target=$HOME${target#\~}
  [[ $target == /* ]] && dir=$target || dir=$dir/$target
fi

rc=0
report=$(check "$dir" 2>&1) || rc=$?
case $rc in
  0) exit 0 ;;
  1)
    {
      echo "go-strict-lint: blocked git commit. Touched Go files have warnings that"
      echo "IDE inspections show but common lint presets hide:"
      echo "$report"
      echo
      echo "Handle each error, or discard it explicitly with \`_ =\` and a comment when"
      echo "nothing can act on it; rename variables that shadow builtins; start the"
      echo "package comment with \"Package <name>\". Then commit again."
    } >&2
    ;;
  *)
    {
      echo "go-strict-lint: blocked git commit. The strict lint pass could not run:"
      echo "$report"
      echo
      echo "Fix the cause (for example network access for the first golangci-lint"
      echo "build, or a package that does not compile), then commit again."
    } >&2
    ;;
esac
exit 2
