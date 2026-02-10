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
   # Detect project structure
   SEARCH_DIRS=""
   [ -d "src" ] && SEARCH_DIRS="$SEARCH_DIRS src/"
   [ -d "app" ] && SEARCH_DIRS="$SEARCH_DIRS app/"
   [ -z "$SEARCH_DIRS" ] && SEARCH_DIRS="."

   # Look for dangerous functions
   grep -rn -E "eval\s*\(" --include="*.php" $SEARCH_DIRS 2>/dev/null || true
   grep -rn -E "(exec|shell_exec|system|passthru)\s*\(" --include="*.php" $SEARCH_DIRS 2>/dev/null || true
   ```

4. Summarize the findings:
   - Total vulnerabilities found by composer audit
   - Static analysis issues (if available)
   - Dangerous function usage
   - Recommendations for remediation
