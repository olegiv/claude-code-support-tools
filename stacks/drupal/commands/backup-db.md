---
description: Create a database backup
allowed-tools: Bash
---

# Database Backup

Create a database backup using Drush.

## Instructions

### 1. Create Backup

```bash
./vendor/bin/drush sql:dump --result-file=backup_$(date +%Y%m%d_%H%M%S).sql 2>&1
```

If the `--result-file` flag is not supported or fails, use a redirect:

```bash
./vendor/bin/drush sql:dump > backup_$(date +%Y%m%d_%H%M%S).sql 2>&1
```

### 2. Verify Backup

```bash
ls -lh backup_*.sql | tail -5
```

### 3. Report

- Backup file name and location
- Backup file size
- Confirmation of success or failure details

## Notes

- For MySQL/MariaDB, the dump is in SQL format
- For PostgreSQL, the dump uses `pg_dump` under the hood
- Consider compressing large backups: `gzip backup_*.sql`
- Store backups in a safe location outside the web root
