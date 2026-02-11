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

## Security Warning

This command attempts to prevent data modification but should not be relied upon as the sole security measure:

1. **Production**: Use a read-only database user
2. **Logs**: All queries are logged in drush output
3. **Audit**: Review query logs regularly
4. **Limit access**: Restrict this command to authorized users only

## Instructions

### 1. Validate the Query

```bash
QUERY="$ARGUMENTS"

# Input length check
if [ ${#QUERY} -gt 2000 ]; then
  echo "ERROR: Query too long (max 2000 characters)"
  exit 1
fi

# Block semicolons on RAW input to prevent all stacked queries
# regardless of comment/string escaping tricks
if echo "$QUERY" | grep -qE ";"; then
  echo "ERROR: Semicolons not allowed (prevents multiple statements)"
  exit 1
fi

# Flatten to single line FIRST, then strip strings (handle doubled
# quotes before removal), then strip comments
CLEAN_QUERY=$(echo "$QUERY" | tr '\n' ' ' | sed "s/''//g" | sed "s/'[^']*'//g" | sed 's/--.*//g' | sed -E "s|/\*([^*]|\*[^/])*\*/||g")

# Check for dangerous keywords (DML/DDL/UNION)
if echo "$CLEAN_QUERY" | grep -iqE "\b(INSERT|UPDATE|DELETE|DROP|TRUNCATE|ALTER|CREATE|GRANT|REVOKE|EXECUTE|CALL|LOAD|OUTFILE|INFILE|DUMPFILE|REPLACE|MERGE|HANDLER|UNION)\b"; then
  echo "ERROR: Only SELECT queries are allowed"
  exit 1
fi

# Check for locking operations
if echo "$CLEAN_QUERY" | grep -iqE "\b(FOR\s+UPDATE|LOCK\s+TABLES)\b"; then
  echo "ERROR: Query contains forbidden locking operations"
  exit 1
fi

# Verify query starts with SELECT
if ! echo "$CLEAN_QUERY" | grep -iqE "^\s*SELECT\b"; then
  echo "ERROR: Query must start with SELECT"
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
