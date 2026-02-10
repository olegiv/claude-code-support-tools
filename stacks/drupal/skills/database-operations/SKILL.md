---
name: database-operations
description: Perform Drupal database operations including backups, restores, queries, and migrations. Use for database maintenance, troubleshooting, and data operations.
allowed-tools: Bash, Read, Grep
---

# Database Operations Skill

This skill guides database operations for Drupal sites using PostgreSQL or MySQL/MariaDB.

## Important Notes

- **Supported Databases**: PostgreSQL and MySQL/MariaDB
- **Primary Tool**: Drush (`./vendor/bin/drush`) for database-agnostic operations
- **Config Location**: `sites/default/settings.php` or `settings.local.php`

## Detecting Your Database Type

```bash
# Check via Drush
./vendor/bin/drush status --fields=db-driver

# Check from settings.php
grep "'driver'" sites/default/settings.php
```

---

## Backup Operations

### Using Drush (Database-Agnostic)

```bash
# Standard SQL dump
./vendor/bin/drush sql:dump > backup.sql

# Compressed dump
./vendor/bin/drush sql:dump --gzip > backup-$(date +%Y%m%d-%H%M%S).sql.gz

# Dump specific tables only
./vendor/bin/drush sql:dump --tables-list=node,node_field_data > partial-backup.sql

# Dump excluding cache tables
./vendor/bin/drush sql:dump --skip-tables-list=cache_default,cache_render,cache_page,cache_discovery > backup-no-cache.sql
```

### PostgreSQL Native Dump

```bash
# Plain SQL format
pg_dump -h localhost -U drupal_user drupal_db > backup.sql

# Custom format (supports parallel restore)
pg_dump -h localhost -U drupal_user -Fc drupal_db > backup.dump

# Directory format (supports parallel dump/restore)
pg_dump -h localhost -U drupal_user -Fd drupal_db -j 4 -f backup_dir/
```

### MySQL Native Dump

```bash
# Standard dump
mysqldump -h localhost -u drupal_user -p drupal_db > backup.sql

# With single transaction (InnoDB, no locking)
mysqldump -h localhost -u drupal_user -p --single-transaction drupal_db > backup.sql

# Compressed
mysqldump -h localhost -u drupal_user -p --single-transaction drupal_db | gzip > backup.sql.gz
```

---

## Restore Operations

### Using Drush (Database-Agnostic)

```bash
# Restore from SQL file
./vendor/bin/drush sql:cli < backup.sql

# Restore from gzipped file
gunzip -c backup.sql.gz | ./vendor/bin/drush sql:cli

# Drop all tables first, then restore (clean restore)
./vendor/bin/drush sql:drop -y
./vendor/bin/drush sql:cli < backup.sql
```

### PostgreSQL Native Restore

```bash
# From plain SQL
psql -h localhost -U drupal_user drupal_db < backup.sql

# From custom format
pg_restore -h localhost -U drupal_user -d drupal_db backup.dump

# Clean restore (drop and recreate)
pg_restore -h localhost -U drupal_user -d drupal_db --clean --if-exists backup.dump
```

### MySQL Native Restore

```bash
# From plain SQL
mysql -h localhost -u drupal_user -p drupal_db < backup.sql

# From gzipped file
gunzip -c backup.sql.gz | mysql -h localhost -u drupal_user -p drupal_db
```

---

## Drush Database Commands

### Cache and Updates

```bash
./vendor/bin/drush cr          # Clear all caches
./vendor/bin/drush updb -y     # Run database updates
./vendor/bin/drush status      # Check DB connection
```

### Configuration

```bash
./vendor/bin/drush cex -y      # Export config to files
./vendor/bin/drush cim -y      # Import config from files
```

### Features (Module Config)

```bash
./vendor/bin/drush fr <module> -y   # Revert feature
```

---

## Database Queries

### Via Drush

```bash
./vendor/bin/drush sql:query "SELECT COUNT(*) FROM node"
./vendor/bin/drush sql:cli    # Open database CLI (psql or mysql)
```

### Common Queries (Database-Agnostic)

```sql
-- Count nodes by type
SELECT type, COUNT(*) FROM node GROUP BY type;

-- Find recent content
SELECT nid, title FROM node_field_data ORDER BY changed DESC LIMIT 10;

-- Check users
SELECT uid, name, mail FROM users_field_data WHERE status = 1 LIMIT 10;

-- Count content per content type
SELECT n.type, COUNT(*) AS total
FROM node n
JOIN node_field_data nfd ON n.nid = nfd.nid
WHERE nfd.status = 1
GROUP BY n.type
ORDER BY total DESC;
```

### PostgreSQL-Specific Queries

```sql
-- Database size
SELECT pg_size_pretty(pg_database_size(current_database()));

-- Table sizes
SELECT relname, pg_size_pretty(pg_total_relation_size(relid))
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 20;

-- Active connections
SELECT count(*) FROM pg_stat_activity WHERE state = 'active';

-- Running queries
SELECT pid, age(clock_timestamp(), query_start), usename, query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;

-- Index usage
SELECT indexrelname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Unused indexes
SELECT indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0;
```

### MySQL-Specific Queries

```sql
-- Database size
SELECT table_schema AS db,
       ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.tables
WHERE table_schema = DATABASE()
GROUP BY table_schema;

-- Table sizes
SELECT table_name,
       ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)',
       table_rows
FROM information_schema.tables
WHERE table_schema = DATABASE()
ORDER BY (data_length + index_length) DESC
LIMIT 20;

-- Active connections
SHOW PROCESSLIST;

-- Running queries
SELECT * FROM information_schema.processlist
WHERE command != 'Sleep'
ORDER BY time DESC;

-- Index usage (requires sys schema)
SELECT * FROM sys.schema_unused_indexes
WHERE object_schema = DATABASE();
```

---

## Maintenance Tasks

### Rebuild Cache Tables

```bash
./vendor/bin/drush cr
```

### Update Entity Schema

```bash
./vendor/bin/drush updb -y
./vendor/bin/drush entup      # Update entity definitions
```

### Clear Specific Caches

```bash
./vendor/bin/drush cache:rebuild
./vendor/bin/drush cache:clear render    # Render cache
./vendor/bin/drush cache:clear menu      # Menu cache
```

### Database Maintenance

```bash
# PostgreSQL only: Vacuum and analyze
./vendor/bin/drush sql:query "VACUUM ANALYZE"

# MySQL: Optimize cache tables
./vendor/bin/drush sql:query "OPTIMIZE TABLE cache_default, cache_render, cache_page"
```

### Truncate Large Tables

```bash
# Clear watchdog logs (database-agnostic via Drush)
./vendor/bin/drush watchdog:delete all -y

# Truncate specific tables via SQL
# PostgreSQL
./vendor/bin/drush sql:query "TRUNCATE TABLE cache_default RESTART IDENTITY"

# MySQL
./vendor/bin/drush sql:query "TRUNCATE TABLE cache_default"
```

---

## Migration Operations

### Check Migrations

```bash
./vendor/bin/drush ms         # Migration status
./vendor/bin/drush migrate:status
```

### Run Migrations

```bash
./vendor/bin/drush mim <migration_id>        # Import
./vendor/bin/drush mr <migration_id>         # Rollback
./vendor/bin/drush mrs <migration_id>        # Reset status
```

---

## Best Practices

1. **Always backup before changes**: `./vendor/bin/drush sql:dump --gzip > backup.sql.gz`
2. **Test restores in non-production**: Verify backups are usable
3. **Use transactions for bulk operations**: Wrap manual SQL in BEGIN/COMMIT
4. **Monitor database size**: Check growth trends regularly
5. **Run maintenance during low traffic**: Schedule VACUUM/OPTIMIZE off-peak
6. **Document any manual queries**: Keep a record of ad-hoc changes
7. **Use Drush for portability**: Prefer `drush sql:*` commands over native tools for database-agnostic operations

---

## Troubleshooting

### Connection Issues

```bash
# Check database status via Drush
./vendor/bin/drush status database

# Check PostgreSQL service
systemctl status postgresql

# Check MySQL service
systemctl status mysql
# or
systemctl status mariadb
```

### View Recent Errors

```bash
./vendor/bin/drush ws --count=50 --severity=error
```

### Lock Issues

```sql
-- PostgreSQL: Find blocked queries
SELECT blocked_locks.pid AS blocked_pid,
       blocking_locks.pid AS blocking_pid,
       blocked_activity.query AS blocked_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
WHERE NOT blocked_locks.granted;

-- MySQL: Find locked tables
SHOW OPEN TABLES WHERE In_use > 0;

-- MySQL: Find blocking queries
SELECT * FROM information_schema.innodb_trx;
```

### Repair/Recovery

```bash
# PostgreSQL: Reindex
./vendor/bin/drush sql:query "REINDEX DATABASE current_database"

# MySQL: Check and repair tables
./vendor/bin/drush sql:query "CHECK TABLE node_field_data"
./vendor/bin/drush sql:query "REPAIR TABLE cache_default"
```
