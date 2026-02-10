---
name: performance-optimization
description: Drupal performance optimization guide covering Redis, caching, database optimization, and asset management.
---

# Performance Optimization Skill

Comprehensive guide for optimizing Drupal performance.

## Stack Overview

| Component | Technology | Purpose |
|-----------|------------|---------|
| Database | PostgreSQL or MySQL/MariaDB | Primary data store |
| Cache | Redis (or Memcached) | Object/session cache |
| Search | Apache Solr (or Elasticsearch) | Full-text search |
| Web Server | Apache or Nginx | HTTP serving |
| PHP | 8.2+ | Application runtime |

## Quick Diagnostics

```bash
# Overall health
./vendor/bin/drush core:status

# Cache status
./vendor/bin/drush cache:list

# Redis stats
redis-cli INFO memory | grep used_memory_human
redis-cli INFO stats | grep -E "keyspace_hits|keyspace_misses"

# Database size (PostgreSQL)
./vendor/bin/drush sql:query "SELECT pg_size_pretty(pg_database_size(current_database()))"

# Database size (MySQL)
./vendor/bin/drush sql:query "SELECT table_schema AS db, ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema = DATABASE() GROUP BY table_schema"
```

---

## 1. Redis Caching

### Configuration Location
`sites/default/settings.redis.php` (or inline in `settings.php`)

### Recommended Settings

```php
// Enable Redis
$settings['redis.connection']['interface'] = 'PhpRedis';
$settings['redis.connection']['host'] = '127.0.0.1';
$settings['redis.connection']['port'] = '6379';

// Cache bins to use Redis
$settings['cache']['default'] = 'cache.backend.redis';

// High-value cache bins
$settings['cache']['bins']['render'] = 'cache.backend.redis';
$settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.redis';
$settings['cache']['bins']['page'] = 'cache.backend.redis';
$settings['cache']['bins']['bootstrap'] = 'cache.backend.redis';
$settings['cache']['bins']['config'] = 'cache.backend.redis';
$settings['cache']['bins']['discovery'] = 'cache.backend.redis';

// Keep some bins in database (rarely accessed)
$settings['cache']['bins']['migrate'] = 'cache.backend.database';
```

### Redis Memory Optimization

```bash
# Check memory
redis-cli INFO memory

# Set max memory (in redis.conf)
# maxmemory 512mb
# maxmemory-policy allkeys-lru

# Monitor real-time
redis-cli MONITOR

# Clear Redis cache
redis-cli FLUSHDB
```

### Hit Rate Analysis

```bash
redis-cli INFO stats | grep -E "keyspace_hits|keyspace_misses"
# Calculate: hits / (hits + misses) * 100 = hit rate %
# Target: > 90%
```

---

## 2. Drupal Caching Layers

### Cache Hierarchy

1. **Page Cache** - Full page for anonymous users
2. **Dynamic Page Cache** - Partial pages for authenticated users
3. **Render Cache** - Individual render elements
4. **Internal Cache** - Discovery, config, bootstrap

### Views Caching

```yaml
# In views configuration
display:
  cache:
    type: tag  # Invalidates on content change
    # OR
    type: time
    options:
      results_lifespan: 3600   # 1 hour
      output_lifespan: 3600

# For static content
display:
  cache:
    type: time
    options:
      results_lifespan: 86400  # 24 hours
      output_lifespan: 86400
```

### Block Caching

```php
// In Block plugin
public function getCacheMaxAge() {
  return 3600; // 1 hour
}

public function getCacheContexts() {
  return ['user.roles', 'url.path'];
}

public function getCacheTags() {
  return ['node_list:article'];
}
```

### BigPipe

```bash
# Enable BigPipe for better perceived performance
./vendor/bin/drush en big_pipe -y
```

---

## 3. Database Optimization

### PostgreSQL Tuning

```sql
-- Check slow queries (requires pg_stat_statements)
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;

-- Table sizes
SELECT relname, pg_size_pretty(pg_total_relation_size(relid))
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 20;

-- Index usage
SELECT indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Unused indexes
SELECT indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0;

-- Vacuum and analyze
VACUUM ANALYZE;
```

### MySQL/MariaDB Tuning

```sql
-- Check slow queries (enable slow_query_log in my.cnf)
-- slow_query_log = 1
-- long_query_time = 2

-- Table sizes
SELECT table_name,
       ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
FROM information_schema.tables
WHERE table_schema = DATABASE()
ORDER BY (data_length + index_length) DESC
LIMIT 20;

-- Index usage
SELECT * FROM sys.schema_unused_indexes
WHERE object_schema = DATABASE();

-- Check for missing indexes
SELECT * FROM sys.statements_with_full_table_scans
WHERE db = DATABASE()
ORDER BY no_index_used_count DESC
LIMIT 10;

-- Optimize tables
OPTIMIZE TABLE cache_default, cache_render, cache_page;
```

### Query Optimization

```php
// BAD: N+1 queries
foreach ($nids as $nid) {
  $node = Node::load($nid);
}

// GOOD: Batch loading
$nodes = Node::loadMultiple($nids);

// BAD: Load all fields
$nodes = $storage->loadMultiple($nids);

// GOOD: Only load needed data
$query = $storage->getQuery()
  ->condition('type', 'article')
  ->condition('status', 1)
  ->range(0, 50);
$nids = $query->execute();
```

### Entity Query Best Practices

```php
// Use accessCheck appropriately
$query = \Drupal::entityQuery('node')
  ->accessCheck(TRUE)  // Required in Drupal 10+
  ->condition('type', 'article')
  ->condition('status', 1)
  ->sort('created', 'DESC')
  ->range(0, 10);

// Add caching tags
$nodes = Node::loadMultiple($query->execute());
$build['#cache']['tags'] = Cache::mergeTags(
  $build['#cache']['tags'] ?? [],
  ['node_list:article']
);
```

---

## 4. Asset Optimization

### CSS/JS Aggregation

```php
// settings.php (production)
$config['system.performance']['css']['preprocess'] = TRUE;
$config['system.performance']['js']['preprocess'] = TRUE;
```

### Image Optimization

```yaml
# responsive_image.style.*.yml
responsive_image_style:
  id: wide
  breakpoints:
    - media: '(min-width: 1200px)'
      image_style: wide_desktop
    - media: '(min-width: 768px)'
      image_style: wide_tablet
    - media: ''
      image_style: wide_mobile
```

### Lazy Loading

```twig
{# In templates #}
<img loading="lazy" src="{{ image_url }}" alt="{{ alt }}">

{# Or via preprocess #}
$variables['attributes']['loading'] = 'lazy';
```

---

## 5. Common Performance Issues

### Issue: Slow Views

**Diagnosis:**
```bash
./vendor/bin/drush views:analyze
```

**Solutions:**
1. Add caching to view display
2. Reduce fields to minimum needed
3. Add appropriate filters
4. Use pager or limit results
5. Consider using Search API instead

### Issue: Heavy Preprocess Functions

**Diagnosis:**
```bash
grep -r "entityTypeManager\|database" themes/custom/*/\*.theme
```

**Solutions:**
1. Move logic to services
2. Cache expensive computations
3. Use lazy builders

### Issue: Too Many Modules

**Diagnosis:**
```bash
./vendor/bin/drush pm:list --status=enabled | wc -l
```

**Solutions:**
1. Disable unused modules
2. Combine functionality
3. Use lazy loading where possible

### Issue: Large Sessions

**Diagnosis:**
```bash
redis-cli --scan --pattern '*session*' | head -10
```

**Solutions:**
1. Reduce session data
2. Clean old sessions
3. Use Redis for sessions

---

## 6. Monitoring & Profiling

### Built-in Tools

```bash
# Enable performance logging
./vendor/bin/drush config:set system.logging error_level verbose -y

# Check recent slow pages
./vendor/bin/drush watchdog:show --severity=warning
```

### Database Query Logging

```php
// settings.local.php (development only)
$settings['container_yamls'][] = DRUPAL_ROOT . '/sites/development.services.yml';
$config['system.logging']['error_level'] = 'verbose';
```

### Memory Profiling

```bash
# PHP memory
php -i | grep memory_limit

# Drupal memory usage
./vendor/bin/drush php:eval "echo 'Memory: ' . round(memory_get_peak_usage() / 1024 / 1024, 2) . 'MB';"
```

---

## 7. Performance Checklist

### Before Deployment

- [ ] CSS/JS aggregation enabled
- [ ] Page cache enabled for anonymous
- [ ] Views have appropriate caching
- [ ] Images use responsive styles
- [ ] Redis (or Memcached) configured and working
- [ ] No development modules enabled
- [ ] Error logging set to production level

### Regular Maintenance

- [ ] Clear stale cache entries
- [ ] Prune old revisions
- [ ] Clean watchdog logs
- [ ] Run database maintenance (VACUUM for PostgreSQL, OPTIMIZE for MySQL)
- [ ] Check Redis memory usage
- [ ] Review slow query log

### Commands

```bash
# Full cache clear
./vendor/bin/drush cr

# Rebuild only specific cache
./vendor/bin/drush cache:rebuild router

# Database maintenance (PostgreSQL)
./vendor/bin/drush sql:query "VACUUM ANALYZE"

# Database maintenance (MySQL)
# Run OPTIMIZE TABLE on large cache/log tables via drush sql:cli

# Clear old logs
./vendor/bin/drush watchdog:delete all
```
