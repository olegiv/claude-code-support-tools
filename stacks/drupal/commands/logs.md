---
description: "View Drupal watchdog logs (optional: severity or count)"
argument-hint: "[error|warning|notice] [count]"
allowed-tools: Bash
---

View Drupal watchdog logs: $ARGUMENTS

**Check the arguments before running anything.** The command arguments are inserted into this prompt before any shell runs, so the shell checks below cannot protect a command that contains them. Check them yourself first: they must be empty, a severity (`error`, `warning`, `notice`, `info`, `debug`, `emergency`, `alert` or `critical`), a count of at least 1 matching `^[0-9]+$` (counts above 1000 are capped at 1000), or a severity followed by a count. The whole value must match, on a single line; if you are unsure whether it matches, treat it as invalid. If it does not match, stop and report the invalid argument without running any command. Run the steps below only with arguments that passed this check; their shell blocks read the value from `ARGS`.

1. Parse the arguments and show the logs, in one Bash call so the parsed
   values reach drush:
   ```bash
   ARGS='$ARGUMENTS'  # passed the argument check above, so it contains no '
   if [ ${#ARGS} -gt 100 ]; then
     echo "ERROR: Input too long (max 100 characters)"
     exit 1
   fi
   # Printable characters only: grep matches line by line, so a line break
   # would otherwise slip through the checks below.
   if [ "$(printf '%s' "$ARGS" | LC_ALL=C tr -d '[:print:]' | wc -c)" -ne 0 ]; then
     echo "ERROR: Arguments must be one line of printable characters"
     exit 1
   fi

   # Words by position; awk's $i avoids dollar-digit tokens, which Claude Code substitutes
   W1=$(printf '%s' "$ARGS" | awk -v i=1 '{print $i}' | tr '[:upper:]' '[:lower:]')
   W2=$(printf '%s' "$ARGS" | awk -v i=2 '{print $i}' | tr '[:upper:]' '[:lower:]')
   W3=$(printf '%s' "$ARGS" | awk -v i=3 '{print $i}')
   SEVERITIES='^(error|warning|notice|info|debug|emergency|alert|critical)$'
   SEVERITY=""
   COUNT=""
   if [ -n "$W3" ]; then
     echo "ERROR: Use at most a severity and a count"
     exit 1
   elif printf '%s' "$W1" | grep -qE "$SEVERITIES"; then
     SEVERITY="$W1"
     COUNT="$W2"
   elif [ -n "$W2" ]; then
     echo "ERROR: Put the severity before the count, e.g. 'error 50'"
     exit 1
   else
     COUNT="$W1"
   fi

   # Validate and cap count
   COUNT="${COUNT:-50}"
   if ! printf '%s\n' "$COUNT" | grep -qxE '[0-9]+'; then
     echo "ERROR: Count must be a number"
     exit 1
   fi
   COUNT=$(printf '%s' "$COUNT" | sed 's/^0*//')   # strip leading zeros
   if [ -z "$COUNT" ]; then
     echo "ERROR: Count must be at least 1"
     exit 1
   fi
   # Check the length first: a very long number overflows the shell's integers.
   if [ ${#COUNT} -gt 4 ] || [ "$COUNT" -gt 1000 ]; then
     COUNT=1000
   fi

   if [ -n "$SEVERITY" ]; then
     ./vendor/bin/drush ws --severity="$SEVERITY" --count="$COUNT"
   else
     ./vendor/bin/drush ws --count="$COUNT"
   fi
   ```

2. Severities: `error`, `warning`, `notice`, `info`, `debug`, `emergency`,
   `alert`, `critical`.

3. If looking for errors specifically:
   ```bash
   ./vendor/bin/drush ws --severity=error --count=20
   ```

4. Report:
   - Summary of log entries
   - Any critical errors
   - Patterns or recurring issues
   - Recommendations for addressing problems
