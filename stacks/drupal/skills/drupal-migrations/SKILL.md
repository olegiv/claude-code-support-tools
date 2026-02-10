---
name: drupal-migrations
description: Guide for Drupal migrations including content imports, data transformations, and migration debugging.
---

# Drupal Migrations Skill

Comprehensive guide for building and debugging Drupal migrations.

## Migration Basics

### Migration Components

1. **Source Plugin** - Where data comes from (CSV, JSON, database, API)
2. **Process Plugins** - Transform data during migration
3. **Destination Plugin** - Where data goes (entity types)

### File Structure

```
modules/custom/mymodule_migrate/
├── mymodule_migrate.info.yml
├── mymodule_migrate.module
├── migrations/
│   ├── mymodule_users.yml
│   ├── mymodule_content.yml
│   └── mymodule_terms.yml
├── src/
│   └── Plugin/
│       └── migrate/
│           ├── source/
│           │   └── CustomSource.php
│           └── process/
│               └── CustomProcess.php
└── config/
    └── install/
        └── migrate_plus.migration.mymodule_users.yml
```

---

## Migration YAML Templates

### CSV Source

```yaml
id: mymodule_articles_csv
label: 'Import articles from CSV'
migration_group: mymodule_content

source:
  plugin: csv
  path: data/imports/articles.csv
  ids:
    - id
  header_row_count: 1
  # Optional: define columns
  column_names:
    0:
      id: 'Unique ID'
    1:
      title: 'Article title'
    2:
      body: 'Article body'
    3:
      date: 'Publication date'

process:
  type:
    plugin: default_value
    default_value: article
  title: title
  body/value: body
  body/format:
    plugin: default_value
    default_value: full_html
  created:
    plugin: format_date
    source: date
    from_format: 'Y-m-d'
    to_format: 'U'
  uid:
    plugin: default_value
    default_value: 1

destination:
  plugin: 'entity:node'
```

### JSON Source

```yaml
id: mymodule_events_json
label: 'Import events from JSON API'
migration_group: mymodule_content

source:
  plugin: url
  data_fetcher_plugin: http
  data_parser_plugin: json
  urls:
    - 'https://api.example.com/events'
  item_selector: data
  ids:
    id:
      type: integer
  fields:
    - name: id
      label: 'Event ID'
      selector: id
    - name: title
      label: 'Event Title'
      selector: attributes/title
    - name: start_date
      label: 'Start Date'
      selector: attributes/start

process:
  type:
    plugin: default_value
    default_value: event
  title: title
  field_event_date/value:
    plugin: format_date
    source: start_date
    from_format: 'Y-m-d\TH:i:s'
    to_format: 'Y-m-d\TH:i:s'

destination:
  plugin: 'entity:node'
```

### Database Source (SQL)

```yaml
id: mymodule_legacy_users
label: 'Import users from legacy database'
migration_group: mymodule_users

source:
  plugin: mymodule_legacy_users
  # Custom source plugin handles connection

process:
  name: username
  mail: email
  status:
    plugin: static_map
    source: active
    map:
      1: 1
      0: 0
    default_value: 0
  roles:
    plugin: explode
    source: role_names
    delimiter: ','

destination:
  plugin: 'entity:user'
```

---

## Common Process Plugins

### Value Transformation

```yaml
# Default value
field_type:
  plugin: default_value
  default_value: 'article'

# Static mapping
field_status:
  plugin: static_map
  source: status_code
  map:
    A: 'active'
    I: 'inactive'
    P: 'pending'
  default_value: 'unknown'

# Callback function
field_slug:
  plugin: callback
  callable: strtolower
  source: title

# Multiple callbacks
field_clean_title:
  - plugin: callback
    callable: trim
  - plugin: callback
    callable: strip_tags
  source: raw_title

# Concatenation
field_full_name:
  plugin: concat
  source:
    - first_name
    - last_name
  delimiter: ' '
```

### Date Handling

```yaml
# Format conversion
field_date:
  plugin: format_date
  source: date_string
  from_format: 'm/d/Y'
  to_format: 'Y-m-d'

# Timestamp to date
field_created:
  plugin: format_date
  source: timestamp
  from_format: 'U'
  to_format: 'Y-m-d\TH:i:s'

# Handle multiple formats
field_date:
  plugin: format_date
  source: date
  from_format:
    - 'Y-m-d'
    - 'm/d/Y'
    - 'd.m.Y'
  to_format: 'Y-m-d'
```

### Entity References

```yaml
# Migration lookup (reference migrated entity)
field_author:
  plugin: migration_lookup
  migration: mymodule_users
  source: author_id
  no_stub: true

# Entity lookup by field value
field_category:
  plugin: entity_lookup
  entity_type: taxonomy_term
  bundle_key: vid
  bundle: categories
  value_key: name
  source: category_name

# Entity generate (create if not exists)
field_tags:
  plugin: entity_generate
  entity_type: taxonomy_term
  bundle_key: vid
  bundle: tags
  value_key: name
  source: tag_names
```

### Array/Multiple Values

```yaml
# Explode string to array
field_tags:
  plugin: explode
  source: tags_string
  delimiter: ','

# Iterate and transform
field_images:
  plugin: sub_process
  source: images
  process:
    target_id:
      plugin: migration_lookup
      migration: mymodule_files
      source: file_id

# Skip empty values
field_optional:
  plugin: skip_on_empty
  source: optional_field
  method: process
```

### Conditional Logic

```yaml
# Skip row if condition met
source_filter:
  plugin: skip_on_value
  source: status
  value: 'deleted'
  method: row

# Skip process if empty
field_optional:
  plugin: skip_on_empty
  source: maybe_empty
  method: process

# Default if null
field_count:
  plugin: null_coalesce
  source:
    - count
    - '@default_count'
  default_value: 0
```

---

## Custom Source Plugin

```php
<?php

namespace Drupal\mymodule_migrate\Plugin\migrate\source;

use Drupal\migrate\Plugin\migrate\source\SqlBase;
use Drupal\migrate\Row;

/**
 * Source plugin for legacy users.
 *
 * @MigrateSource(
 *   id = "mymodule_legacy_users",
 *   source_module = "mymodule_migrate"
 * )
 */
class LegacyUsers extends SqlBase {

  /**
   * {@inheritdoc}
   */
  public function query() {
    return $this->select('legacy_users', 'u')
      ->fields('u', [
        'id',
        'email',
        'first_name',
        'last_name',
        'status',
        'created_at',
      ])
      ->condition('u.status', 'active');
  }

  /**
   * {@inheritdoc}
   */
  public function fields() {
    return [
      'id' => $this->t('User ID'),
      'email' => $this->t('Email address'),
      'first_name' => $this->t('First name'),
      'last_name' => $this->t('Last name'),
      'status' => $this->t('Status'),
      'created_at' => $this->t('Created date'),
    ];
  }

  /**
   * {@inheritdoc}
   */
  public function getIds() {
    return [
      'id' => [
        'type' => 'integer',
        'alias' => 'u',
      ],
    ];
  }

  /**
   * {@inheritdoc}
   */
  public function prepareRow(Row $row) {
    // Generate username from email
    $email = $row->getSourceProperty('email');
    $username = explode('@', $email)[0];
    $row->setSourceProperty('username', $username);

    // Format full name
    $fullName = trim(
      $row->getSourceProperty('first_name') . ' ' .
      $row->getSourceProperty('last_name')
    );
    $row->setSourceProperty('full_name', $fullName);

    return parent::prepareRow($row);
  }

}
```

---

## Custom Process Plugin

```php
<?php

namespace Drupal\mymodule_migrate\Plugin\migrate\process;

use Drupal\migrate\MigrateExecutableInterface;
use Drupal\migrate\ProcessPluginBase;
use Drupal\migrate\Row;

/**
 * Transforms legacy codes to a new format.
 *
 * @MigrateProcessPlugin(
 *   id = "mymodule_code_transform"
 * )
 *
 * Usage:
 * @code
 * process:
 *   field_code:
 *     plugin: mymodule_code_transform
 *     source: legacy_code
 * @endcode
 */
class CodeTransform extends ProcessPluginBase {

  /**
   * {@inheritdoc}
   */
  public function transform($value, MigrateExecutableInterface $migrate_executable, Row $row, $destination_property) {
    if (empty($value)) {
      return NULL;
    }

    // Transform legacy codes to new format
    // Example: "OLD-12345" -> "NEW-12345"
    $prefix = $this->configuration['prefix'] ?? 'NEW';
    if (preg_match('/^[A-Z]+-(.+)$/', $value, $matches)) {
      $value = $prefix . '-' . $matches[1];
    }

    return strtoupper($value);
  }

}
```

---

## Drush Commands

```bash
# List all migrations
./vendor/bin/drush migrate:status

# Run migration
./vendor/bin/drush migrate:import mymodule_users

# Run with limit
./vendor/bin/drush migrate:import mymodule_users --limit=100

# Run with feedback
./vendor/bin/drush migrate:import mymodule_users --feedback=50

# Update existing (re-import changed)
./vendor/bin/drush migrate:import mymodule_users --update

# Rollback
./vendor/bin/drush migrate:rollback mymodule_users

# Reset stuck migration
./vendor/bin/drush migrate:reset-status mymodule_users

# View messages/errors
./vendor/bin/drush migrate:messages mymodule_users

# Stop running migration
./vendor/bin/drush migrate:stop mymodule_users

# Run group
./vendor/bin/drush migrate:import --group=mymodule_content

# Rollback group
./vendor/bin/drush migrate:rollback --group=mymodule_content
```

---

## Debugging Migrations

### Check Source Data

```bash
./vendor/bin/drush php:eval "
  \$migration = \Drupal::service('plugin.manager.migration')
    ->createInstance('mymodule_users');
  \$source = \$migration->getSourcePlugin();
  \$count = 0;
  foreach (\$source as \$row) {
    print_r(\$row->getSource());
    if (++\$count >= 3) break;
  }
"
```

### Check Processed Row

```bash
./vendor/bin/drush php:eval "
  \$migration = \Drupal::service('plugin.manager.migration')
    ->createInstance('mymodule_users');
  \$source = \$migration->getSourcePlugin();
  \$executable = new \Drupal\migrate\MigrateExecutable(\$migration);

  foreach (\$source as \$row) {
    \$executable->processRow(\$row);
    print_r(\$row->getDestination());
    break;
  }
"
```

### View Migration Map

```bash
# PostgreSQL
./vendor/bin/drush sql:query "SELECT * FROM migrate_map_mymodule_users LIMIT 10"

# MySQL
./vendor/bin/drush sql:query "SELECT * FROM migrate_map_mymodule_users LIMIT 10"
```

### Common Error Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| Source not found | Wrong path/URL | Check `path` or `urls` in source |
| Destination entity not found | Missing bundle | Check destination `plugin` type |
| Process plugin not found | Typo in plugin name | Check plugin ID spelling |
| Required field missing | Empty source | Add `skip_on_empty` or default |
| Entity reference invalid | Target not migrated | Add `migration_lookup` with dependency |

---

## Migration Dependencies

```yaml
id: mymodule_articles
label: 'Articles'
migration_dependencies:
  required:
    - mymodule_users      # Authors must exist
    - mymodule_categories # Terms must exist
  optional:
    - mymodule_files      # Files can be added later

process:
  uid:
    plugin: migration_lookup
    migration: mymodule_users
    source: author_id
```
