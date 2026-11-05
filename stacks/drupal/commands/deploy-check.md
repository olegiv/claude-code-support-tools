---
description: Run pre-deployment checklist
allowed-tools: Bash, Read, Grep
---

# Pre-Deployment Checklist

Run a comprehensive pre-deployment checklist using standard Drupal tools.

## 1. Git Status
```bash
git status
```

## 2. Check for Uncommitted Changes
Verify all changes are committed or intentionally excluded.

## 3. Composer Audit
```bash
composer audit
```

## 4. Run Tests (only when the user asks)
PHPUnit is not a mandatory step. When the user asks for it in their own message, run only
the tests of the modules and themes changed against the remote default branch (`origin/HEAD`), never the full suite. Run the block
as one Bash call with a timeout of 600000 ms, or in the background: PHPUnit's output streams
as it runs, every outcome prints a line, and the block exits with PHPUnit's status (1 when
git or `mktemp` fails). Paths are read as whole NUL-separated records, so none is quoted,
split or merged, both sides of a move count, and only machine names are kept.
```bash
tmpd=$(mktemp -d) || { echo 'PHPUnit: ERROR mktemp failed; nothing run' >&2; exit 1; }
trap 'rm -rf "$tmpd"' EXIT
rc=0
if ! base=$(git symbolic-ref -q --short refs/remotes/origin/HEAD); then
  echo 'PHPUnit: ERROR origin/HEAD is not set (git remote set-head origin --auto); nothing run' >&2; rc=1
elif ! git -c core.quotePath=false diff --relative -z --no-renames --name-only "$base...HEAD" >"$tmpd/paths"; then
  echo "PHPUnit: ERROR git diff against $base failed; nothing run" >&2; rc=1
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
    echo "PHPUnit: no module or theme changed against $base has tests/; nothing run"
  else
    ./vendor/bin/phpunit -c core/phpunit.xml.dist --fail-on-empty-test-suite "$@" 2>&1; rc=$?
    echo "PHPUnit exit=$rc"
  fi
fi
exit "$rc"
```

## 5. Check Database Updates
```bash
./vendor/bin/drush updb --no-post-updates -n 2>&1 | head -10
```

## 6. Check Configuration Status
```bash
./vendor/bin/drush config:status 2>&1 | head -20
```

## 7. Check Module Status
```bash
./vendor/bin/drush pm:security 2>&1
```

## Report Summary

Provide a summary of:
- [ ] Git status (clean/dirty)
- [ ] Composer audit results
- [ ] Test results (pass/fail)
- [ ] Pending database updates
- [ ] Configuration sync status
- [ ] Security advisories
- [ ] Overall deployment readiness

Recommend whether it is safe to deploy or what needs to be addressed first.
