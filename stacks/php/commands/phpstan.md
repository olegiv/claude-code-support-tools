---
description: Run PHPStan static analysis
argument-hint: [path]
allowed-tools: Bash(./vendor/bin/phpstan:*)
---

Run PHPStan static analysis:

Path to analyze: $ARGUMENTS (optional)

1. If path provided:
   ```bash
   ./vendor/bin/phpstan analyse $1
   ```

2. If no path specified, run default analysis:
   ```bash
   ./vendor/bin/phpstan analyse
   ```

3. Report:
   - Number of errors found
   - Errors grouped by file
   - Suggestions for fixing common issues
