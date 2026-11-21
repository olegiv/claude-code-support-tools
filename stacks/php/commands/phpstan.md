---
description: Run PHPStan static analysis
argument-hint: [path]
allowed-tools: Bash
---

Run PHPStan static analysis:

Path to analyze: $ARGUMENTS (optional)

**Check the arguments before running anything.** The command arguments are inserted into this prompt before any shell runs, so the shell checks below cannot protect a command that contains them. Check them yourself first: they must be empty or one relative path matching `^[a-zA-Z0-9_./ -]+$` that contains no `..` and does not start with `/`. The whole value must match, on a single line; if you are unsure whether it matches, treat it as invalid. If it does not match, stop and report the invalid argument without running any command. Run the steps below only with arguments that passed this check; their shell blocks read the value from `ARGS`.

1. Validate input if provided:
   ```bash
   ARGS='$ARGUMENTS'  # passed the argument check above, so it contains no '
   if [ -n "${ARGS}" ]; then
     if [ ${#ARGS} -gt 256 ]; then
       echo "ERROR: Input too long (max 256 characters)"
       exit 1
     fi
     if printf '%s' "$ARGS" | grep -qE '\.\.'; then
       echo "ERROR: Path traversal not allowed"
       exit 1
     fi
     if printf '%s' "$ARGS" | grep -qE '^/'; then
       echo "ERROR: Absolute paths not allowed"
       exit 1
     fi
     if ! printf '%s' "$ARGS" | grep -qE '^[a-zA-Z0-9_./ -]+$'; then
       echo "ERROR: Invalid path. Only alphanumeric, dots, slashes, hyphens, underscores, and spaces allowed."
       exit 1
     fi
   fi
   ```

2. If path provided:
   ```bash
   ARGS='$ARGUMENTS'  # passed the argument check above, so it contains no '
   ./vendor/bin/phpstan analyse -- "$ARGS"
   ```

3. If no path specified, run default analysis:
   ```bash
   ./vendor/bin/phpstan analyse
   ```

4. Report:
   - Number of errors found
   - Errors grouped by file
   - Suggestions for fixing common issues
