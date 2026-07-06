---
description: Run PHPStan static analysis
argument-hint: [path]
allowed-tools: Bash(./vendor/bin/phpstan:*)
---

Run PHPStan static analysis:

Path to analyze: $ARGUMENTS (optional)

1. Validate input if provided:
   ```bash
   if [ -n "${ARGUMENTS:-}" ]; then
     if [ ${#ARGUMENTS} -gt 256 ]; then
       echo "ERROR: Input too long (max 256 characters)"
       exit 1
     fi
     if printf '%s' "$ARGUMENTS" | grep -qE '\.\.'; then
       echo "ERROR: Path traversal not allowed"
       exit 1
     fi
     if printf '%s' "$ARGUMENTS" | grep -qE '^/'; then
       echo "ERROR: Absolute paths not allowed"
       exit 1
     fi
     if ! printf '%s' "$ARGUMENTS" | grep -qE '^[a-zA-Z0-9_./ -]+$'; then
       echo "ERROR: Invalid path. Only alphanumeric, dots, slashes, hyphens, underscores, and spaces allowed."
       exit 1
     fi
   fi
   ```

2. If path provided:
   ```bash
   ./vendor/bin/phpstan analyse -- "$ARGUMENTS"
   ```

3. If no path specified, run default analysis:
   ```bash
   ./vendor/bin/phpstan analyse
   ```

4. Report:
   - Number of errors found
   - Errors grouped by file
   - Suggestions for fixing common issues
