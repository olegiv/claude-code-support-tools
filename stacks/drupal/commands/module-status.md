---
description: Check status of Drupal modules (optional: module name)
argument-hint: [module-name]
allowed-tools: Bash, Read, Grep
---

Check Drupal module status for: $ARGUMENTS

1. If a module name is provided, check that specific module:
   ```bash
   ./vendor/bin/drush pm:list --filter="$1"
   ```

2. If no argument, show all enabled modules:
   ```bash
   ./vendor/bin/drush pm:list --status=enabled
   ```

3. Check for available updates:
   ```bash
   composer outdated "drupal/*" 2>/dev/null | head -20
   ```

4. Report:
   - Module status (enabled/disabled)
   - Version information
   - Available updates if any
   - Dependencies
