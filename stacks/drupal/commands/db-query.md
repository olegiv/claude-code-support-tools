---
description: "Run safe SELECT query on the database"
argument-hint: "<sql-query>"
allowed-tools: Bash
---

# Database Query

Run a safe read-only SQL query against the Drupal database.

## Arguments

- `$ARGUMENTS` - The SQL SELECT query to execute

## Safety Rules

**ONLY execute queries that:**
- Start with SELECT
- Do not contain INSERT, UPDATE, DELETE, DROP, TRUNCATE, ALTER, CREATE
- Do not contain semicolons followed by additional statements

**REFUSE to run:**
- Any data modification queries
- Any schema modification queries
- Multiple statements
- Queries without explicit column selection (SELECT * on large tables)

## Instructions

### 1. Validate the Query

```bash
QUERY="$ARGUMENTS"
if echo "$QUERY" | grep -iE "(INSERT|UPDATE|DELETE|DROP|TRUNCATE|ALTER|CREATE|GRANT|REVOKE)" > /dev/null; then
  echo "ERROR: Only SELECT queries are allowed"
  exit 1
fi
```

### 2. Execute the Query

```bash
./vendor/bin/drush sql:query "$ARGUMENTS" 2>&1
```

### 3. Useful Query Examples

**Node counts by type:**
```sql
SELECT type, COUNT(*) as count FROM node GROUP BY type ORDER BY count DESC
```

**Recent content:**
```sql
SELECT nid, title, created FROM node_field_data WHERE status = 1 ORDER BY created DESC LIMIT 20
```

**User counts by role:**
```sql
SELECT roles_target_id as role, COUNT(*) as count FROM user__roles GROUP BY roles_target_id
```

**Large tables (PostgreSQL):**
```sql
SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC LIMIT 10
```

**Large tables (MySQL):**
```sql
SELECT table_name, ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb FROM information_schema.tables WHERE table_schema = DATABASE() ORDER BY (data_length + index_length) DESC LIMIT 10
```

## Output Format

Display results in a readable format. For large result sets, summarize or limit output.
