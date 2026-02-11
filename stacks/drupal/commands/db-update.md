---
description: Run Drupal database updates
allowed-tools: Bash
---

Run Drupal database updates:

1. Run pending database updates:
   ```bash
   ./vendor/bin/drush updb -y
   ```

2. Clear all caches:
   ```bash
   ./vendor/bin/drush cr
   ```

3. Report the result, including any updates that were applied.
