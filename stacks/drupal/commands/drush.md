---
description: Execute a drush command with documentation
argument-hint: <command> [arguments]
allowed-tools: Bash
---

Execute drush command: $ARGUMENTS

1. Validate the command is safe to run:
   ```bash
   if [ ${#ARGUMENTS} -gt 500 ]; then
     echo "ERROR: Input too long (max 500 characters)"
     exit 1
   fi

   # Extract the drush subcommand (first word)
   DRUSH_CMD=$(echo "$ARGUMENTS" | awk '{print $1}')

   # Allowlist of safe drush commands
   SAFE_COMMANDS="cr|cache:rebuild|status|st|core:status|updb|updatedb|cex|config:export|cim|config:import|fr|features:revert|en|pm:enable|pmu|pm:uninstall|uli|user:login|ws|watchdog:show|user:information|sql:query|php:eval|pm:list|core:requirements|queue:list|queue:run|locale:update|entity:updates"

   if ! echo "$DRUSH_CMD" | grep -qE "^($SAFE_COMMANDS)$"; then
     echo "ERROR: Unknown drush command '$DRUSH_CMD'. Verify it is safe before running."
     exit 1
   fi

   # Block shell metacharacters (glob, redirect, escape, comment, history)
   if echo "$ARGUMENTS" | grep -qE '[][;|&`$(){}!<>\\#*?~]'; then
     echo "ERROR: Arguments contain forbidden shell characters"
     exit 1
   fi
   # Block quote characters (prevent string escaping attacks)
   if echo "$ARGUMENTS" | grep -qF '"' || echo "$ARGUMENTS" | grep -qF "'"; then
     echo "ERROR: Arguments contain forbidden quote characters"
     exit 1
   fi
   # Block newlines (could introduce new commands)
   if [ "$(printf '%s' "$ARGUMENTS" | wc -l)" -gt 0 ]; then
     echo "ERROR: Arguments must be single-line"
     exit 1
   fi
   ```

2. Execute the drush command (no destructive operations without confirmation):
   ```bash
   ./vendor/bin/drush $ARGUMENTS
   ```

3. Common drush commands for reference:
   - `cr` - Clear all caches
   - `status` - Show system status
   - `updb -y` - Run database updates
   - `cex -y` - Export configuration
   - `cim -y` - Import configuration
   - `fr <module> -y` - Revert feature
   - `en <module> -y` - Enable module
   - `pmu <module> -y` - Uninstall module
   - `uli` - Generate login link
   - `ws --count=50` - Show watchdog logs

4. Report the command output and any relevant next steps
