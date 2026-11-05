---
description: "Run PHPUnit tests (default: the modules the change touches; or a module name, or 'all')"
argument-hint: [module-name | all]
allowed-tools: Bash, Read
---

Run tests for: $ARGUMENTS

Run tests for the updated code only, never the full suite unless the user asks for it in
their own message. Run each block as one Bash call with a timeout of 600000 ms, or in the
background: PHPUnit's output streams as it runs, and the block exits with PHPUnit's status.
Kernel and functional tests need `SIMPLETEST_DB` (and `SIMPLETEST_BASE_URL`); without them
they error, which is a setup problem, not a test failure.

## 1. Check the argument

If an argument is given, it must be `all` or a Drupal machine name matching
`^[a-z][a-z0-9_]{0,49}$` (at most 50 characters; no `/`, `..`, spaces or shell
characters). Check it before running anything; otherwise stop and say the argument is not a
module name.

## 2. No argument: the modules the change touches

The modules and themes changed against the remote default branch (`origin/HEAD`), plus uncommitted work. The block lists the paths
NUL-separated, so no path is quoted, split or merged, and both sides of a move count. It
keeps only `modules/custom/<name>/` and `themes/custom/<name>/` with a machine name and a
`tests/` directory, and exits 1 with a message if git or `mktemp` fails. Ask the user only
when it reports that the change touches none.

```bash
tmpd=$(mktemp -d) || { echo 'PHPUnit: ERROR mktemp failed; nothing run' >&2; exit 1; }
trap 'rm -rf "$tmpd"' EXIT
rc=0
if ! base=$(git symbolic-ref -q --short refs/remotes/origin/HEAD); then
  echo 'PHPUnit: ERROR origin/HEAD is not set (git remote set-head origin --auto); nothing run' >&2; rc=1
elif ! { git -c core.quotePath=false diff -z --no-renames --name-only "$base...HEAD" &&
         git -c core.quotePath=false diff -z --no-renames --name-only HEAD &&
         git ls-files -z --others --exclude-standard; } >"$tmpd/paths"; then
  echo 'PHPUnit: ERROR git could not list the changed paths; nothing run' >&2; rc=1
else
  # Whole NUL-separated records: a path is never quoted, split or merged. Only
  # modules/custom/<name>/ and themes/custom/<name>/ with a machine name count.
  set --; seen=' '
  while IFS= read -r -d '' p; do
    case $p in modules/custom/?*/*|themes/custom/?*/*) ;; *) continue ;; esac
    rest=${p#*/custom/}; name=${rest%%/*}; dir=${p%%/*}/custom/$name
    case $name in *[!abcdefghijklmnopqrstuvwxyz0123456789_]*) continue ;; esac
    case $seen in *" $dir "*) continue ;; esac
    seen="$seen$dir "
    [ -d "$dir/tests" ] && set -- "$@" "$dir/tests/"
  done <"$tmpd/paths"
  if [ $# -eq 0 ]; then
    echo 'PHPUnit: the change touches no module or theme with tests/; nothing run'
  else
    ./vendor/bin/phpunit -c core/phpunit.xml.dist --fail-on-empty-test-suite "$@" 2>&1; rc=$?
    echo "PHPUnit exit=$rc"
  fi
fi
exit "$rc"
```

## 3. A module name

```bash
./vendor/bin/phpunit -c core/phpunit.xml.dist --fail-on-empty-test-suite "modules/custom/<module>/tests/"; echo "PHPUnit exit=$?"
```

## 4. "all"

Only when the user asked for the full suite in their own message:

```bash
./vendor/bin/phpunit -c core/phpunit.xml.dist --fail-on-empty-test-suite modules/custom themes/custom; echo "PHPUnit exit=$?"
```

## 5. Report

- The PHPUnit exit code
- Tests run, passed and failed
- Details of any failures, and recommendations for fixing them
- A non-zero exit with no PHPUnit summary is a run failure (for example a missing test
  database), not failing tests: say so instead of reporting counts
