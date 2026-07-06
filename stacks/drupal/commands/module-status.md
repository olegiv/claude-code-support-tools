---
description: "Check status of Drupal modules (optional: module name)"
argument-hint: [module-name]
allowed-tools: Bash, Read, Grep
---

Check Drupal module status for: $ARGUMENTS

1. Validate input:
   ```bash
   if [ -n "${ARGUMENTS:-}" ]; then
     if [ ${#ARGUMENTS} -gt 128 ]; then
       echo "ERROR: Input too long (max 128 characters)"
       exit 1
     fi
     if ! printf '%s' "$ARGUMENTS" | grep -qE '^[a-zA-Z0-9_]+$'; then
       echo "ERROR: Invalid module name. Only alphanumeric and underscores allowed."
       exit 1
     fi
   fi
   ```

2. If a module name is provided, check that specific module:
   ```bash
   ./vendor/bin/drush pm:list --filter="$ARGUMENTS"
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
