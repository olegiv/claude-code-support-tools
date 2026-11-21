---
description: "Check status of Drupal modules (optional: module name)"
argument-hint: [module-name]
allowed-tools: Bash, Read, Grep
---

Check Drupal module status for: $ARGUMENTS

**Check the arguments before running anything.** The command arguments are inserted into this prompt before any shell runs, so the shell checks below cannot protect a command that contains them. Check them yourself first: they must be empty or one module machine name matching `^[a-zA-Z0-9_]+$`. The whole value must match, on a single line; if you are unsure whether it matches, treat it as invalid. If it does not match, stop and report the invalid argument without running any command. Run the steps below only with arguments that passed this check; their shell blocks read the value from `ARGS`.

1. Validate input:
   ```bash
   ARGS='$ARGUMENTS'  # passed the argument check above, so it contains no '
   if [ -n "${ARGS}" ]; then
     if [ ${#ARGS} -gt 128 ]; then
       echo "ERROR: Input too long (max 128 characters)"
       exit 1
     fi
     if ! printf '%s' "$ARGS" | grep -qE '^[a-zA-Z0-9_]+$'; then
       echo "ERROR: Invalid module name. Only alphanumeric and underscores allowed."
       exit 1
     fi
   fi
   ```

2. If a module name is provided, check that specific module:
   ```bash
   ARGS='$ARGUMENTS'  # passed the argument check above, so it contains no '
   ./vendor/bin/drush pm:list --filter="$ARGS"
   ```

3. If no argument, show all enabled modules:
   ```bash
   ./vendor/bin/drush pm:list --status=enabled
   ```

4. Check for available updates:
   ```bash
   composer outdated "drupal/*" 2>/dev/null | head -20
   ```

5. Report:
   - Module status (enabled/disabled)
   - Version information
   - Available updates if any
   - Dependencies
