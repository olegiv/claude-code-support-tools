---
description: Revert Drupal feature(s) to sync config from code
argument-hint: <module-name> [module-name2...]
allowed-tools: Bash
---

Revert Drupal features: $ARGUMENTS

1. If no module specified, show available features:
   ```bash
   ./vendor/bin/drush features:list 2>/dev/null || ./vendor/bin/drush pm:list --status=enabled
   ```
   Then ask the user which feature(s) to revert.

2. Validate input:
   ```bash
   if [ -n "$ARGUMENTS" ]; then
     if [ ${#ARGUMENTS} -gt 500 ]; then
       echo "ERROR: Input too long (max 500 characters)"
       exit 1
     fi
     for MODULE in $ARGUMENTS; do
       if ! echo "$MODULE" | grep -qE '^[a-zA-Z0-9_-]+$'; then
         echo "ERROR: Invalid module name '$MODULE'. Only alphanumeric, underscores, and hyphens allowed."
         exit 1
       fi
     done
   fi
   ```

3. Revert the specified feature(s):
   ```bash
   # Unquoted: drush fr needs separate arguments per module
   # Safe because for-loop validation above ensures ^[a-zA-Z0-9_-]+$ per word
   # -y before -- so drush recognizes it as an option; module names after -- are positional only
   ./vendor/bin/drush fr -y -- $ARGUMENTS
   ```

4. Clear caches after revert:
   ```bash
   ./vendor/bin/drush cr
   ```

5. Report:
   - Features reverted
   - Any errors or warnings
   - Configuration changes applied

Note: Feature revert syncs configuration from code (config/install/) to the database.
