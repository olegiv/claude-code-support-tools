---
description: Export Drupal configuration
allowed-tools: Bash
---

Export Drupal configuration:

1. First check for configuration changes:
   ```bash
   ./vendor/bin/drush config:status
   ```

2. Export the configuration:
   ```bash
   ./vendor/bin/drush cex -y
   ```

3. Report what was exported and remind the user to review changes before committing.
