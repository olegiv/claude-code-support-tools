---
description: Run PHP security scan (composer audit and static analysis)
argument-hint: "<severity: critical|high|medium|low>"
allowed-tools: Bash(composer:*), Bash(./vendor/bin/phpstan:*), Bash(grep:*), Read
---

# PHP Security Scan

Run a PHP security scan with optional severity filtering.

## Arguments

- `$ARGUMENTS` - Optional severity level to filter results (critical, high, medium, low)

## Instructions

### 0. Validate Input
```bash
SEVERITY="${ARGUMENTS:-}"

if [ -n "$SEVERITY" ]; then
  if [ ${#SEVERITY} -gt 20 ]; then
    echo "ERROR: Input too long (max 20 characters)"
    exit 1
  fi
  # Normalize to lowercase
  SEVERITY=$(printf '%s' "$SEVERITY" | tr '[:upper:]' '[:lower:]')
  if ! printf '%s' "$SEVERITY" | grep -qE '^(critical|high|medium|low)$'; then
    echo "ERROR: Invalid severity '$SEVERITY'. Use: critical, high, medium, low"
    exit 1
  fi
fi
```

### 1. Run Composer Security Audit
```bash
if [ -n "$SEVERITY" ]; then
  echo "=== Composer Audit (filtering: $SEVERITY) ==="
  composer audit 2>&1 | grep -iE "$SEVERITY|^Package|^Sever|^Title|^CVE|^Link|^Advis|^Report|^Found|No security" || true
else
  echo "=== Composer Audit ==="
  composer audit 2>&1
fi
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
