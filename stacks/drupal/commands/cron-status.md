---
description: "Check cron jobs and scheduled task status"
allowed-tools: Bash
---

# Cron Status

Check the status of Drupal cron and scheduled tasks.

## Instructions

### 1. Last Cron Run
```bash
./vendor/bin/drush core:cron-last 2>&1
```

### 2. Cron State Variables
```bash
./vendor/bin/drush state:get system.cron_last 2>&1
```

### 3. Check Scheduler Module (if enabled)
```bash
./vendor/bin/drush pm:list --filter=scheduler --format=list 2>&1
./vendor/bin/drush scheduler:list 2>/dev/null || echo "Scheduler not enabled or no items"
```

### 4. Queue Items (cron-related)
```bash
./vendor/bin/drush queue:list 2>&1
```

### 5. Ultimate Cron (if enabled)
```bash
./vendor/bin/drush pm:list --filter=ultimate_cron --format=list 2>&1
```

### 6. System Crontab (if accessible)
```bash
crontab -l 2>&1 | grep -iE "(drush|drupal|cron)" || echo "No user crontab entries for Drupal"
```

### 7. Recent Cron Log Entries
```bash
./vendor/bin/drush watchdog:show --type=cron --count=10 2>&1
```

### 8. Check for Stuck Cron
```bash
./vendor/bin/drush state:get system.cron_lock 2>&1 || echo "No cron lock"
```

## Output Format

### Cron Summary

| Metric | Value |
|--------|-------|
| Last Run | timestamp |
| Status | Running/Idle |
| Lock | Yes/No |
| Queued Items | count |

### Recent Cron Activity

List the last 10 cron-related log entries.

### Issues

Flag any problems:
- Cron has not run in more than 1 hour
- Cron lock is stuck
- Large queue backlogs
- Failed cron tasks

### Recommendations

If issues found, provide:
- Commands to fix stuck cron: `./vendor/bin/drush state:delete system.cron_lock`
- Queue processing commands: `./vendor/bin/drush queue:run <queue_name>`
- Manual cron trigger: `./vendor/bin/drush cron`
