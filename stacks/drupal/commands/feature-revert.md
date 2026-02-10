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

2. Revert the specified feature(s):
   ```bash
   ./vendor/bin/drush fr $ARGUMENTS -y
   ```

3. Clear caches after revert:
   ```bash
   ./vendor/bin/drush cr
   ```

4. Report:
   - Features reverted
   - Any errors or warnings
   - Configuration changes applied

Note: Feature revert syncs configuration from code (config/install/) to the database.
