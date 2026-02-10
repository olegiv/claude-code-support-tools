---
description: "Check queue items and workers status"
allowed-tools: Bash
---

# Queue Status

Check the status of Drupal queues and background workers.

## Instructions

### 1. List All Queues
```bash
./vendor/bin/drush queue:list 2>&1
```

### 2. Queue Details
For each queue with items, show details:
```bash
./vendor/bin/drush php:eval "
  \$queue_factory = \Drupal::service('queue');
  \$definitions = \Drupal::service('plugin.manager.queue_worker')->getDefinitions();
  foreach (array_keys(\$definitions) as \$name) {
    \$queue = \$queue_factory->get(\$name);
    \$count = \$queue->numberOfItems();
    if (\$count > 0) {
      echo \"\$name: \$count items\n\";
    }
  }
"
```

### 3. Check for Stuck Items
```bash
./vendor/bin/drush sql:query "
SELECT name, COUNT(*) as count, MIN(created) as oldest
FROM queue
GROUP BY name
HAVING COUNT(*) > 0
ORDER BY count DESC;
" 2>&1
```

### 4. AdvancedQueue (if enabled)
```bash
./vendor/bin/drush advancedqueue:list 2>/dev/null || echo "AdvancedQueue not enabled"
```

### 5. Check Queue Workers
```bash
./vendor/bin/drush php:eval "
  \$definitions = \Drupal::service('plugin.manager.queue_worker')->getDefinitions();
  echo 'Registered queue workers: ' . count(\$definitions) . PHP_EOL;
  foreach (\$definitions as \$id => \$def) {
    echo \"- \$id\" . PHP_EOL;
  }
" 2>&1 | head -30
```

## Output Format

### Queue Summary

| Queue Name | Items | Oldest Item | Worker |
|------------|-------|-------------|--------|
| queue_name | count | timestamp | worker_id |

### Status

- **Healthy**: No backlogs, all queues processing
- **Warning**: Some queues have items older than 1 hour
- **Critical**: Queues blocked or very large backlogs

### Actions

If issues found:

**Process a specific queue:**
```bash
./vendor/bin/drush queue:run <queue_name>
```

**Delete stuck items:**
```bash
./vendor/bin/drush queue:delete <queue_name>
```

### Recommendations

Provide queue-specific recommendations based on findings.
