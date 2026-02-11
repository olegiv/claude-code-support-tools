---
description: Import Drupal configuration
allowed-tools: Bash
---

Import Drupal configuration:

1. First check what will be imported:
   ```bash
   ./vendor/bin/drush config:status
   ```

2. Show the user what changes will be made and confirm they want to proceed.

3. If user confirms, import the configuration:
   ```bash
   ./vendor/bin/drush cim -y
   ```

4. Clear caches:
   ```bash
   ./vendor/bin/drush cr
   ```

5. Report the result.
