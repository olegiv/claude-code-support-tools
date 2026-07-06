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

   # Extract the drush subcommand (first word). Use printf, not echo:
   # under zsh the builtin echo decodes backslash escapes, so the value
   # checked here could differ from the raw $ARGUMENTS run below.
   DRUSH_CMD=$(printf '%s' "$ARGUMENTS" | awk '{print $1}')

   # Allowlist of safe drush commands. Deliberately excludes sql:query and
   # php:eval: their effect is determined entirely by free-form text this
   # generic wrapper does not validate. Use /db-query for read-only SQL.
   SAFE_COMMANDS="cr|cache:rebuild|status|st|core:status|updb|updatedb|cex|config:export|cim|config:import|fr|features:revert|en|pm:enable|pmu|pm:uninstall|uli|user:login|ws|watchdog:show|user:information|pm:list|core:requirements|queue:list|queue:run|locale:update|entity:updates"

   if ! printf '%s' "$DRUSH_CMD" | grep -qE "^($SAFE_COMMANDS)$"; then
     echo "ERROR: Unknown drush command '$DRUSH_CMD'. Verify it is safe before running."
     exit 1
   fi

   # Block shell metacharacters (glob, redirect, escape, comment, history)
   if printf '%s' "$ARGUMENTS" | grep -qE '[][;|&`$(){}!<>\\#*?~]'; then
     echo "ERROR: Arguments contain forbidden shell characters"
     exit 1
   fi
   # Block quote characters (prevent string escaping attacks)
   if printf '%s' "$ARGUMENTS" | grep -qF '"' || printf '%s' "$ARGUMENTS" | grep -qF "'"; then
     echo "ERROR: Arguments contain forbidden quote characters"
     exit 1
   fi
   # Block auto-confirmation flags so drush's native prompts for
   # destructive operations (updb/cim/fr/en/pmu) always fire — this
   # command must never suppress them on the user's behalf.
   if printf '%s' "$ARGUMENTS" | grep -qE '(^|[[:space:]])(-y|--yes|-n|--no)([[:space:]]|$)'; then
     echo "ERROR: Auto-confirmation flags (-y/--yes/-n/--no) are not allowed"
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
   ./vendor/bin/drush -- $ARGUMENTS
   ```

3. Common drush commands for reference. This command blocks the
   `-y`/`--yes` auto-confirm flag, so destructive operations prompt
   interactively; for scripted config/database workflows use the
   purpose-built `/db-update`, `/config-import`, and `/feature-revert`
   commands, and `/db-query` for read-only SQL:
   - `cr` - Clear all caches
   - `status` - Show system status
   - `updb` - Run database updates (prompts for confirmation)
   - `cex` - Export configuration (prompts for confirmation)
   - `cim` - Import configuration (prompts for confirmation)
   - `fr <module>` - Revert feature (prompts for confirmation)
   - `en <module>` - Enable module (prompts for confirmation)
   - `pmu <module>` - Uninstall module (prompts for confirmation)
   - `uli` - Generate login link
   - `ws --count=50` - Show watchdog logs

4. Report the command output and any relevant next steps
