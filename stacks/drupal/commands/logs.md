---
description: View Drupal watchdog logs (optional: severity or count)
argument-hint: [error|warning|notice] [count]
allowed-tools: Bash
---

View Drupal watchdog logs: $ARGUMENTS

1. Validate arguments:
   ```bash
   # Parse severity and count from $ARGUMENTS
   SEVERITY=$(echo "$ARGUMENTS" | awk '{print $1}')
   COUNT=$(echo "$ARGUMENTS" | awk '{print $2}')

   # Validate severity if provided
   if [ -n "$SEVERITY" ]; then
     if ! echo "$SEVERITY" | grep -qE '^(error|warning|notice|info|debug|emergency|alert|critical)$'; then
       # Might be a count instead of severity
       if echo "$SEVERITY" | grep -qE '^[0-9]+$'; then
         COUNT="$SEVERITY"
         SEVERITY=""
       else
         echo "ERROR: Invalid severity. Use: error, warning, notice, info, debug, emergency, alert, critical"
         exit 1
       fi
     fi
   fi

   # Validate and cap count
   COUNT="${COUNT:-50}"
   if ! echo "$COUNT" | grep -qE '^[0-9]+$'; then
     echo "ERROR: Count must be a number"
     exit 1
   fi
   if [ "$COUNT" -gt 1000 ]; then
     COUNT=1000
   fi
   ```

2. Run watchdog command:

   For all recent logs:
   ```bash
   ./vendor/bin/drush ws --count=$COUNT
   ```

   For specific severity:
   ```bash
   ./vendor/bin/drush ws --severity=$SEVERITY --count=$COUNT
   ```

3. If looking for errors specifically:
   ```bash
   ./vendor/bin/drush ws --severity=error --count=20
   ```

4. Report:
   - Summary of log entries
   - Any critical errors
   - Patterns or recurring issues
   - Recommendations for addressing problems
