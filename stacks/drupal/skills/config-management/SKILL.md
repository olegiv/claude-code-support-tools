---
name: config-management
description: Guide for Drupal configuration management including Features, config splits, environment handling, and deployment workflows.
---

# Configuration Management Skill

Comprehensive guide for managing Drupal configuration.

## Configuration Systems

| System | Use Case | Location |
|--------|----------|----------|
| **Config Sync** | Full site config export/import | `config/sync/` |
| **Features** | Module-specific config bundles | `modules/*/config/install/` |
| **Config Split** | Environment-specific config | Per-split directories |

---

## 1. Features (Module-Level Config)

### Structure

```
modules/custom/mymodule/
├── config/
│   ├── install/           # Config installed with module
│   │   ├── field.storage.node.field_example_date.yml
│   │   ├── field.field.node.example.field_example_date.yml
│   │   └── views.view.example_listing.yml
│   └── optional/          # Config installed if dependencies exist
│       └── block.block.example_sidebar.yml
├── mymodule.info.yml
└── mymodule.module
```

### Feature Commands

```bash
# Check feature status
./vendor/bin/drush features:status

# List overridden features
./vendor/bin/drush features:list --status=overridden

# Revert feature (code -> database)
./vendor/bin/drush fr <module> -y

# Revert multiple features
./vendor/bin/drush fr mymodule_news mymodule_events -y

# Export feature changes (database -> code)
# Use config:export then move files manually
./vendor/bin/drush config:export --diff
```

### Feature Info File

```yaml
# mymodule.info.yml
name: 'My Module'
type: module
description: 'Content type and functionality'
package: Custom
core_version_requirement: ^10 || ^11

dependencies:
  - drupal:node
  - drupal:views
  - drupal:datetime

# Feature-specific
features:
  bundle: example
  excluded:
    - system.site  # Never export site config
```

### config/install Rules

**DO include:**
- Field storage definitions
- Field instance configurations
- View configurations
- Content type configurations
- Taxonomy vocabulary configurations
- Image styles
- Custom block types

**DO NOT include:**
- UUIDs (remove them!)
- Site-specific config (system.site)
- User accounts
- Environment-specific paths
- API keys or secrets

### Removing UUIDs

```bash
# Find UUIDs in config/install
grep -r "^uuid:" modules/custom/*/config/install/*.yml

# Remove UUIDs from a file
sed -i '/^uuid:/d' modules/custom/mymodule/config/install/*.yml
```

---

## 2. Configuration Export/Import

### Full Export

```bash
# Export all config
./vendor/bin/drush config:export -y

# Export to specific directory
./vendor/bin/drush config:export --destination=/tmp/config-export
```

### Single Config Export

```bash
# Export single config item
./vendor/bin/drush config:get views.view.example_listing --include-overridden > example_view.yml

# View config without saving
./vendor/bin/drush config:get views.view.example_listing
```

### Import

```bash
# Import all config
./vendor/bin/drush config:import -y

# Import single item
./vendor/bin/drush config:set views.view.example_listing -y < example_view.yml
```

### Config Status

```bash
# Show differences
./vendor/bin/drush config:status

# Show specific diff
./vendor/bin/drush config:diff views.view.example_listing
```

---

## 3. Environment-Specific Configuration

### Settings Per Environment

```php
// settings.local.php (not in repo, outside docroot)

// Development
$config['system.logging']['error_level'] = 'verbose';
$config['system.performance']['css']['preprocess'] = FALSE;
$config['system.performance']['js']['preprocess'] = FALSE;

// Production
$config['system.logging']['error_level'] = 'hide';
$config['system.performance']['css']['preprocess'] = TRUE;
$config['system.performance']['js']['preprocess'] = TRUE;
```

### Config Overrides in Settings

```php
// Disable modules in production
$config['core.extension']['module']['devel'] = 0;
$config['core.extension']['module']['kint'] = 0;

// Override API endpoints per environment
$config['mymodule.settings']['api_url'] = getenv('API_URL');
$config['mymodule.settings']['api_key'] = getenv('API_KEY');

// Environment indicator
$config['environment_indicator.indicator']['bg_color'] = '#ff0000';
$config['environment_indicator.indicator']['name'] = 'PRODUCTION';
```

### Using Config Split

```yaml
# config/split/development.yml
id: development
label: Development
status: true
folder: ../config/split/development
blacklist:
  - system.logging
  - system.performance
graylist: []
graylist_dependents: true
graylist_skip_equal: true
```

---

## 4. Configuration Validation

### Pre-Deployment Checklist

```bash
# 1. Check config status
./vendor/bin/drush config:status

# 2. Check feature status
./vendor/bin/drush features:status

# 3. Look for UUIDs in feature config
grep -r "^uuid:" modules/custom/*/config/install/

# 4. Check for environment-specific values
grep -rE "(localhost|127\.0\.0\.1|dev\.|test\.)" modules/custom/*/config/install/

# 5. Validate YAML syntax
find modules/custom -name "*.yml" -exec php -r "yaml_parse_file('{}');" \;
```

### Common Issues

| Issue | Symptom | Solution |
|-------|---------|----------|
| UUID conflict | "Config already exists" | Remove UUIDs from config/install |
| Missing dependency | Import fails | Add to module's dependencies |
| Schema mismatch | Warnings on import | Update config schema |
| Overridden feature | Changes lost on revert | Export changes to code |

---

## 5. Configuration Schema

### Schema Definition

```yaml
# mymodule.schema.yml
mymodule.settings:
  type: config_object
  label: 'My Module settings'
  mapping:
    enabled:
      type: boolean
      label: 'Enable feature'
    api_url:
      type: string
      label: 'API URL'
    items_per_page:
      type: integer
      label: 'Items per page'
    allowed_types:
      type: sequence
      label: 'Allowed content types'
      sequence:
        type: string
```

### Validate Schema

```bash
# Check for schema errors
./vendor/bin/drush config:inspect

# Check specific config
./vendor/bin/drush config:inspect mymodule.settings
```

---

## 6. Deployment Workflow

### Standard Deployment

```bash
# 1. Enable maintenance mode
./vendor/bin/drush state:set system.maintenance_mode 1 -y

# 2. Backup database
./vendor/bin/drush sql:dump --gzip > backup-$(date +%Y%m%d-%H%M%S).sql.gz

# 3. Run database updates
./vendor/bin/drush updb -y

# 4. Revert features (if using Features module)
./vendor/bin/drush fr <module_1> <module_2> -y

# 5. Import configuration (if using Config Sync)
./vendor/bin/drush cim -y

# 6. Clear caches
./vendor/bin/drush cr

# 7. Disable maintenance mode
./vendor/bin/drush state:set system.maintenance_mode 0 -y
```

---

## 7. Configuration Best Practices

### Module Configuration

```php
<?php
// Store settings in config, not state

// Get config (read-only)
$config = \Drupal::config('mymodule.settings');
$value = $config->get('api_url');

// Update config (editable)
$config = \Drupal::configFactory()->getEditable('mymodule.settings');
$config->set('api_url', 'https://api.example.com');
$config->save();
```

### State vs Config

| Use Config For | Use State For |
|----------------|---------------|
| Settings that deploy | Runtime data |
| User-configurable options | Temporary values |
| Feature behavior | Cron timestamps |
| API endpoints | Last sync time |

```php
// State example (not exported, environment-specific runtime data)
\Drupal::state()->set('mymodule.last_sync', time());
$lastSync = \Drupal::state()->get('mymodule.last_sync');
```

### Config Dependencies

```yaml
# In config file
dependencies:
  config:
    - field.storage.node.field_example
    - node.type.article
  module:
    - node
    - datetime
  enforced:
    module:
      - mymodule  # Delete config if module uninstalled
```

---

## 8. Troubleshooting

### Config Won't Import

```bash
# Check for errors
./vendor/bin/drush config:import --preview

# Force import (careful!)
./vendor/bin/drush config:import --partial -y
```

### Feature Won't Revert

```bash
# Check status
./vendor/bin/drush features:status <module>

# Clear cache and retry
./vendor/bin/drush cr
./vendor/bin/drush fr <module> -y
```

### Find Config Changes

```bash
# Export current state
./vendor/bin/drush config:export -y

# Use git to see changes
git diff config/sync/
```

### Reset Config to Code

```bash
# Delete active config, reinstall from code
./vendor/bin/drush config:delete views.view.example_listing
./vendor/bin/drush cr
./vendor/bin/drush fr <module> -y
```
