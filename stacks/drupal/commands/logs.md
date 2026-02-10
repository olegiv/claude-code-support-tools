---
description: View Drupal watchdog logs (optional: severity or count)
argument-hint: [error|warning|notice] [count]
allowed-tools: Bash
---

View Drupal watchdog logs: $ARGUMENTS

1. Parse arguments:
   - First arg: severity filter (error, warning, notice) or count
   - Second arg: count (default 50)

2. Run watchdog command:

   For all recent logs:
   ```bash
   ./vendor/bin/drush ws --count=${2:-50}
   ```

   For specific severity:
   ```bash
   ./vendor/bin/drush ws --severity=$1 --count=${2:-50}
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
