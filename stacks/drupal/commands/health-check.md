---
description: "Check site health: database, cache, cron, queues, and system status"
allowed-tools: Bash
---

# Site Health Check

Run a comprehensive health check on the Drupal site.

## Instructions

Execute the following checks and provide a summary report:

### 1. Drupal Status
```bash
./vendor/bin/drush core:status --format=yaml
```

### 2. Database Connection
```bash
./vendor/bin/drush sql:query "SELECT 1 AS connected" 2>&1
```

### 3. Cache Status
```bash
# Check if Redis is available (optional, may not be installed)
if command -v redis-cli &>/dev/null; then
    redis-cli ping 2>&1 || echo "Redis not available"
    redis-cli INFO memory 2>&1 | head -10 || true
else
    echo "Redis client not installed - skipping Redis check"
fi
```

### 4. Cron Status
```bash
./vendor/bin/drush core:cron-last
```

### 5. Module Security Updates
```bash
./vendor/bin/drush pm:security 2>&1
```

### 6. Watchdog Errors (last hour)
```bash
./vendor/bin/drush watchdog:show --severity=error --count=5 2>&1
```

### 7. Queue Status
```bash
./vendor/bin/drush queue:list 2>&1
```

### 8. Disk Space
```bash
df -h . | tail -1
```

### 9. File Permissions
```bash
# Check file permissions (detect Drupal files directory)
DRUPAL_FILES="sites/default/files"
if [ -d "$DRUPAL_FILES" ]; then
    ls -la "$DRUPAL_FILES/" | head -5
else
    echo "Default files directory not found at $DRUPAL_FILES"
    # Try to find files directory from Drupal config
    ./vendor/bin/drush status --field=files 2>/dev/null || true
fi
```

## Output Format

Provide a summary table:

| Component | Status | Details |
|-----------|--------|---------|
| Drupal Core | OK/ISSUE | Version |
| Database | OK/ISSUE | Connection status |
| Cache | OK/ISSUE | Backend and memory usage |
| Cron | OK/ISSUE | Last run time |
| Security | OK/ISSUE | Updates available |
| Errors | OK/ISSUE | Recent error count |
| Queues | OK/ISSUE | Items pending |
| Disk | OK/ISSUE | Usage percentage |

Flag any issues that need attention.
