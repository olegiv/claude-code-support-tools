---
description: Run PHP security scan (composer audit and static analysis)
argument-hint: "[critical|high|medium|low]"
allowed-tools: Bash, Read
---

# PHP Security Scan

**Check the arguments before running anything.** The command arguments are inserted into this prompt before any shell runs, so the shell checks below cannot protect a command that contains them. Check them yourself first: they must be empty or one of `critical`, `high`, `medium` or `low`, in any case. The whole value must match, on a single line; if you are unsure whether it matches, treat it as invalid. If it does not match, stop and report the invalid argument without running any command. Run the steps below only with arguments that passed this check; their shell blocks read the value from `ARGS`.

Run a PHP security scan with optional severity filtering.

## Arguments

- `$ARGUMENTS` - Optional severity level to filter results (critical, high, medium, low)

## Instructions

### 1. Check the Severity and Run the Composer Audit

One Bash call, so the checked severity reaches the filter. Requires `jq`.

```bash
ARGS='$ARGUMENTS'  # passed the argument check above, so it contains no '
SEVERITY=$(printf '%s' "$ARGS" | tr '[:upper:]' '[:lower:]')
if [ -n "$SEVERITY" ] && ! printf '%s\n' "$SEVERITY" | grep -qxE '(critical|high|medium|low)'; then
  echo "ERROR: Invalid severity '$SEVERITY'. Use: critical, high, medium, low"
  exit 1
fi

# composer audit exits non-zero when it finds advisories, so judge the run by
# its JSON: no valid JSON means the audit itself failed.
AUDIT=$(composer audit --format=json 2>/dev/null)
if ! printf '%s' "$AUDIT" | jq -e 'type == "object"' >/dev/null 2>&1; then
  echo "ERROR: composer audit failed:"
  composer audit 2>&1 | tail -20
  exit 1
fi

if [ -n "$SEVERITY" ]; then
  echo "=== Composer Audit (severity: $SEVERITY, plus advisories without a severity) ==="
  printf '%s' "$AUDIT" | jq --arg s "$SEVERITY" '
    (.advisories // {}) | if type == "object" then . else {} end
    | map_values(map(select(((.severity // "") | ascii_downcase) as $v | $v == $s or $v == "")))
    | with_entries(select(.value | length > 0))'
else
  echo "=== Composer Audit ==="
  printf '%s' "$AUDIT" | jq '.advisories // {}'
fi
printf '%s' "$AUDIT" | jq -r '"Abandoned packages: \((.abandoned // {}) | length)"'
```

### 2. Run Static Analysis (if available)
```bash
echo "=== PHPStan Analysis ==="
./vendor/bin/phpstan analyse 2>/dev/null || echo "PHPStan not configured"
```

### 3. Check for Dangerous Function Usage
```bash
echo "=== Dangerous Function Detection ==="
FOUND_DIRS=false
for dir in src app; do
  if [ -d "$dir" ]; then
    FOUND_DIRS=true
    grep -rn -E "eval\s*\(" --include="*.php" "$dir/" 2>/dev/null || true
    grep -rn -E "(exec|shell_exec|system|passthru)\s*\(" --include="*.php" "$dir/" 2>/dev/null || true
  fi
done
if [ "$FOUND_DIRS" = false ]; then
  grep -rn -E "eval\s*\(" --include="*.php" . 2>/dev/null || true
  grep -rn -E "(exec|shell_exec|system|passthru)\s*\(" --include="*.php" . 2>/dev/null || true
fi
```

### 4. Summary

Summarize the findings:
- Total vulnerabilities found by composer audit
- Static analysis issues (if available)
- Dangerous function usage
- Recommendations for remediation
