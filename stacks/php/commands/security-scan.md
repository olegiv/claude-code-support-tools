---
description: Run PHP security scan (composer audit and static analysis)
argument-hint: [severity]
allowed-tools: Bash, Read
---

Run a PHP security scan: $ARGUMENTS

1. Run Composer security audit:
   ```bash
   composer audit
   ```

2. If PHPStan is available, run static analysis:
   ```bash
   ./vendor/bin/phpstan analyse 2>/dev/null || echo "PHPStan not configured"
   ```

3. Check for common security issues:
   ```bash
   # Look for dangerous functions
   grep -rn "eval\s*(" --include="*.php" src/ app/ 2>/dev/null || true
   grep -rn "exec\s*(\|shell_exec\s*(\|system\s*(\|passthru\s*(" --include="*.php" src/ app/ 2>/dev/null || true
   ```

4. Summarize the findings:
   - Total vulnerabilities found by composer audit
   - Static analysis issues (if available)
   - Dangerous function usage
   - Recommendations for remediation
