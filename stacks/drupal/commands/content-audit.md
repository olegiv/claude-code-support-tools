---
description: "Find orphaned, unpublished, or stale content"
argument-hint: "[content-type]"
allowed-tools: Bash
---

# Content Audit

Audit content for issues: orphaned references, unpublished items, stale content.

## Arguments

- `$ARGUMENTS` - Optional content type filter (e.g., article, page, event)

## Instructions

### 1. Content Overview
```bash
./vendor/bin/drush sql:query "
SELECT
  type,
  status,
  COUNT(*) as count
FROM node_field_data
GROUP BY type, status
ORDER BY type, status;
"
```

### 2. Unpublished Content (older than 30 days)

**PostgreSQL:**
```bash
TYPE_FILTER="${ARGUMENTS:-}"
if [ -n "$TYPE_FILTER" ]; then
  ./vendor/bin/drush sql:query "
  SELECT nid, title, type, to_timestamp(changed) as last_changed
  FROM node_field_data
  WHERE status = 0
    AND type = '$TYPE_FILTER'
    AND changed < EXTRACT(EPOCH FROM NOW() - INTERVAL '30 days')
  ORDER BY changed ASC
  LIMIT 20;
  "
else
  ./vendor/bin/drush sql:query "
  SELECT nid, title, type, to_timestamp(changed) as last_changed
  FROM node_field_data
  WHERE status = 0
    AND changed < EXTRACT(EPOCH FROM NOW() - INTERVAL '30 days')
  ORDER BY changed ASC
  LIMIT 20;
  "
fi
```

**MySQL:**
```bash
TYPE_FILTER="${ARGUMENTS:-}"
if [ -n "$TYPE_FILTER" ]; then
  ./vendor/bin/drush sql:query "
  SELECT nid, title, type, FROM_UNIXTIME(changed) as last_changed
  FROM node_field_data
  WHERE status = 0
    AND type = '$TYPE_FILTER'
    AND changed < UNIX_TIMESTAMP(NOW() - INTERVAL 30 DAY)
  ORDER BY changed ASC
  LIMIT 20;
  "
else
  ./vendor/bin/drush sql:query "
  SELECT nid, title, type, FROM_UNIXTIME(changed) as last_changed
  FROM node_field_data
  WHERE status = 0
    AND changed < UNIX_TIMESTAMP(NOW() - INTERVAL 30 DAY)
  ORDER BY changed ASC
  LIMIT 20;
  "
fi
```

### 3. Stale Published Content (not updated in 1 year)

**PostgreSQL:**
```bash
./vendor/bin/drush sql:query "
SELECT nid, title, type, to_timestamp(changed) as last_changed
FROM node_field_data
WHERE status = 1
  AND changed < EXTRACT(EPOCH FROM NOW() - INTERVAL '365 days')
ORDER BY changed ASC
LIMIT 20;
"
```

**MySQL:**
```bash
./vendor/bin/drush sql:query "
SELECT nid, title, type, FROM_UNIXTIME(changed) as last_changed
FROM node_field_data
WHERE status = 1
  AND changed < UNIX_TIMESTAMP(NOW() - INTERVAL 365 DAY)
ORDER BY changed ASC
LIMIT 20;
"
```

### 4. Content Without Author
```bash
./vendor/bin/drush sql:query "
SELECT n.nid, n.title, n.type
FROM node_field_data n
LEFT JOIN users_field_data u ON n.uid = u.uid
WHERE u.uid IS NULL OR u.status = 0
LIMIT 20;
"
```

### 5. Orphaned Media/Files
```bash
./vendor/bin/drush sql:query "
SELECT COUNT(*) as orphaned_files
FROM file_managed f
WHERE f.fid NOT IN (
  SELECT DISTINCT fid FROM file_usage
);
"
```

### 6. Broken Internal Links (if linkchecker enabled)
```bash
./vendor/bin/drush pm:list --filter=linkchecker --status=enabled --format=list 2>&1
```

### 7. Revision Bloat

**PostgreSQL:**
```bash
./vendor/bin/drush sql:query "
SELECT type, COUNT(*) as revision_count, COUNT(DISTINCT nr.nid) as node_count,
  ROUND(COUNT(*)::numeric / COUNT(DISTINCT nr.nid), 2) as avg_revisions
FROM node_revision nr
JOIN node_field_data n ON nr.nid = n.nid
GROUP BY type
ORDER BY avg_revisions DESC;
"
```

**MySQL:**
```bash
./vendor/bin/drush sql:query "
SELECT type, COUNT(*) as revision_count, COUNT(DISTINCT nr.nid) as node_count,
  ROUND(COUNT(*) / COUNT(DISTINCT nr.nid), 2) as avg_revisions
FROM node_revision nr
JOIN node_field_data n ON nr.nid = n.nid
GROUP BY type
ORDER BY avg_revisions DESC;
"
```

## Output Format

### Content Summary

| Type | Published | Unpublished | Total |
|------|-----------|-------------|-------|
| article | N | N | N |

### Issues Found

#### Stale Content (> 1 year old)
| NID | Title | Type | Last Updated |
|-----|-------|------|--------------|

#### Long-term Unpublished (> 30 days)
| NID | Title | Type | Last Changed |
|-----|-------|------|--------------|

#### Orphaned Items
- Files without usage: N
- Content without valid author: N

### Recommendations

1. **Review unpublished content**: Decide to publish or delete
2. **Update stale content**: Review for accuracy
3. **Clean orphaned files**: Consider using `./vendor/bin/drush file:delete-orphans` if available
4. **Prune revisions**: Consider revision limit per content type

### Quick Actions

```bash
# Process a specific content type
./vendor/bin/drush entity:delete node --bundle=<type> ...

# Bulk operations via Drush
./vendor/bin/drush php:eval "..."
```
