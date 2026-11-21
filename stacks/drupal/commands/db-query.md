---
description: "Run safe SELECT query on the database"
argument-hint: "<sql-query>"
allowed-tools: Bash, Write
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
- Stay within plain SQL on one line of printable ASCII: single-quoted strings
  only, and no double quotes, backticks, dollar signs, backslashes, comments,
  semicolons, line breaks or non-ASCII characters (such as `é`)

**REFUSE to run:**
- Any data modification queries
- Any schema modification queries
- Multiple statements
- Queries without explicit column selection (SELECT * on large tables)

## Security Warning

This command's checks are best-effort and must not be the only protection. The real boundary is a database user with SELECT-only grants on the tables you need:

1. **Production**: Use a read-only database user
2. **Logs**: All queries are logged in drush output
3. **Audit**: Review query logs regularly
4. **Limit access**: Restrict this command to authorized users only

## Instructions

The command arguments are inserted into this prompt before any shell runs, so
never put the query into a shell command, not even inside quotes: SQL contains
quotes and other characters a shell acts on. Pass it through a file instead.

### 1. Save the Query to a File

Create a private temporary file:

```bash
f=$(mktemp "${TMPDIR:-/tmp}/db-query.XXXXXX") && echo "QUERY_FILE=$f"
```

Continue only if this printed a `QUERY_FILE=` line; otherwise stop and report
the error. Use the Write tool to save the query (the command arguments,
verbatim, without a trailing line break) to that path. If the Write tool fails
or is refused, remove the file with `rm -f -- '<path>'`, then stop and report
it; never write the file another way, such as with `echo`, `printf` or a
heredoc.

### 2. Check and Run the Query

Run this as one Bash call, with the printed path in place of `PATH_FROM_STEP_1`.
It removes the file when it exits, and it ends with drush's exit status:

```bash
QUERY_FILE='PATH_FROM_STEP_1'
trap 'rm -f -- "$QUERY_FILE"' EXIT

[ -s "$QUERY_FILE" ] || { echo "ERROR: The query was not saved to $QUERY_FILE"; exit 1; }

# Check the file's bytes before the shell reads them ($(cat) drops trailing
# line breaks): printable characters only, so one line with no tabs, control
# characters or NUL bytes. drush passes the file to the database client, and
# psql and mysql run backslash and line-start commands instead of SQL.
if [ "$(LC_ALL=C tr -d '[:print:]' < "$QUERY_FILE" | wc -c)" -ne 0 ]; then
  echo "ERROR: The query must be one line of printable ASCII (no line breaks, tabs or non-ASCII characters such as é)"
  exit 1
fi
QUERY=$(cat -- "$QUERY_FILE") || { echo "ERROR: Cannot read $QUERY_FILE"; exit 1; }

if [ ${#QUERY} -gt 2000 ]; then
  echo "ERROR: Query too long (max 2000 characters)"
  exit 1
fi

# Raw-input checks. Validation pipelines use printf, not echo: under zsh the
# builtin echo decodes backslash escapes before grep inspects the string.
if printf '%s' "$QUERY" | grep -qF '\'; then
  echo "ERROR: Backslashes are not allowed"
  exit 1
fi
if printf '%s' "$QUERY" | grep -qF ';'; then
  echo "ERROR: Semicolons not allowed (prevents multiple statements)"
  exit 1
fi
# Only single-quoted strings: double quotes (MySQL strings), backticks and $$
# (PostgreSQL dollar quoting) would let a stray ' hide text from the checks
# below while the database still runs it.
if printf '%s' "$QUERY" | grep -qE '["`$]'; then
  echo "ERROR: Double quotes, backticks and dollar signs are not allowed"
  exit 1
fi
# Comments are rejected anywhere, even inside strings: databases disagree on
# what starts one (MySQL needs whitespace after --, /*! runs as code).
if printf '%s' "$QUERY" | grep -qE -- '--|/\*|#'; then
  echo "ERROR: Comments (--, /* */, #) are not allowed"
  exit 1
fi

# Keyword checks run on the query without its single-quoted strings (doubled
# quotes first), so words inside string literals do not trigger them. This
# list is best-effort and can never be complete; the real boundary is a
# database user with SELECT-only grants.
CLEAN_QUERY=$(printf '%s' "$QUERY" | sed "s/''//g" | sed "s/'[^']*'//g")
if printf '%s' "$CLEAN_QUERY" | grep -iqE "\b(INSERT|UPDATE|DELETE|DROP|TRUNCATE|ALTER|CREATE|GRANT|REVOKE|EXECUTE|CALL|LOAD|LOAD_FILE|INTO|OUTFILE|INFILE|DUMPFILE|REPLACE|MERGE|HANDLER|UNION|COPY|SLEEP|BENCHMARK|GET_LOCK|PG_SLEEP|PG_READ_FILE|PG_READ_BINARY_FILE|PG_STAT_FILE|PG_LS_DIR|LO_IMPORT|LO_EXPORT|LO_GET|DBLINK|QUERY_TO_XML|PG_TERMINATE_BACKEND|PG_CANCEL_BACKEND|SET_CONFIG|SETVAL|NEXTVAL)\b"; then
  echo "ERROR: Only plain SELECT queries are allowed"
  exit 1
fi
# Function families, matched as calls so names such as pg_statio_user_tables
# still work: sleeps, advisory locks, dblink, large objects, file access.
if printf '%s' "$CLEAN_QUERY" | grep -iqE "\b(PG_SLEEP[A-Z0-9_]*|PG_ADVISORY[A-Z0-9_]*|PG_TRY_ADVISORY[A-Z0-9_]*|DBLINK[A-Z0-9_]*|LO_[A-Z0-9_]+|PG_READ[A-Z0-9_]*|PG_LS[A-Z0-9_]*|PG_STAT_FILE)[[:space:]]*\("; then
  echo "ERROR: Only plain SELECT queries are allowed"
  exit 1
fi
if printf '%s' "$CLEAN_QUERY" | grep -iqE "\b(FOR\s+UPDATE|FOR\s+SHARE|LOCK\s+IN\s+SHARE\s+MODE|LOCK\s+TABLES)\b"; then
  echo "ERROR: Query contains forbidden locking operations"
  exit 1
fi
if ! printf '%s' "$CLEAN_QUERY" | grep -iqE "^\s*SELECT\b"; then
  echo "ERROR: Query must start with SELECT"
  exit 1
fi

./vendor/bin/drush sql:query --file="$QUERY_FILE" 2>&1
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
