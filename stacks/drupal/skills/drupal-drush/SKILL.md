---
name: drupal-drush
description: Use this skill when running Drush commands, clearing caches, managing configuration, updating databases, or performing any Drupal CLI operations. Trigger phrases include "drush", "clear cache", "cache clear", "config export", "config import", "database update", "feature revert".
allowed-tools: Bash, Read, Grep
---

# Drupal Drush Command Skill

Comprehensive knowledge of Drush commands for Drupal 10/11 sites.

## Running Drush

**IMPORTANT**: Always run Drush from the Drupal project root directory.

```bash
./vendor/bin/drush <command>
```

## Common Commands Quick Reference

### Cache Operations
```bash
./vendor/bin/drush cr                    # Clear all caches (most common)
./vendor/bin/drush cc render             # Clear render cache only
./vendor/bin/drush cc views              # Clear views cache
./vendor/bin/drush cache:rebuild         # Rebuild cache (alias: cr)
```

### Configuration Management
```bash
./vendor/bin/drush cex -y                # Export config to sync directory
./vendor/bin/drush cim -y                # Import config from sync directory
./vendor/bin/drush cget <config.name>    # View specific config
./vendor/bin/drush cset <name> <key> <val> -y  # Set config value
./vendor/bin/drush config:status         # Show config differences
./vendor/bin/drush config:delete <name>  # Delete a config item
```

### Features (Module Config)
```bash
./vendor/bin/drush fr <module> -y        # Revert feature (code -> DB)
./vendor/bin/drush fl                    # List all features
./vendor/bin/drush fd <module>           # Show feature diff
./vendor/bin/drush features:status       # Status of all features
```

### Database Operations
```bash
./vendor/bin/drush updb -y               # Run database updates
./vendor/bin/drush sqlq "SELECT..."      # Run SQL query
./vendor/bin/drush sql:dump > backup.sql # Dump database
./vendor/bin/drush sql:dump --gzip > backup.sql.gz  # Dump compressed
./vendor/bin/drush sql:cli               # Open database CLI
./vendor/bin/drush sql:query "SQL"       # Execute SQL query
```

### Module Management
```bash
./vendor/bin/drush pm:list               # List all modules
./vendor/bin/drush pm:list --status=enabled  # List enabled only
./vendor/bin/drush en <module> -y        # Enable module
./vendor/bin/drush pmu <module> -y       # Uninstall module
./vendor/bin/drush pm:security           # Check security updates
```

### Theme Management
```bash
./vendor/bin/drush theme:list            # List all themes
./vendor/bin/drush theme:enable <theme>  # Enable theme
./vendor/bin/drush theme:uninstall <theme>  # Uninstall theme
./vendor/bin/drush cset system.theme default <theme> -y  # Set default theme
```

### User Management
```bash
./vendor/bin/drush uli                   # Generate one-time login
./vendor/bin/drush uli --uid=1           # Login as admin
./vendor/bin/drush user:password <name> <pass>  # Set password
./vendor/bin/drush user:block <name>     # Block user
./vendor/bin/drush user:unblock <name>   # Unblock user
./vendor/bin/drush user:role:add <role> <user>  # Add role
./vendor/bin/drush user:role:remove <role> <user>  # Remove role
./vendor/bin/drush user:information <name>  # View user info
```

### Watchdog (Logs)
```bash
./vendor/bin/drush watchdog:show         # Show recent logs
./vendor/bin/drush watchdog:show --count=50     # Show 50 entries
./vendor/bin/drush watchdog:show --severity=error  # Errors only
./vendor/bin/drush watchdog:show --type=php       # PHP errors
./vendor/bin/drush watchdog:delete all   # Delete all log entries
```

### Cron
```bash
./vendor/bin/drush cron                  # Run cron
./vendor/bin/drush core:cron             # Run cron (full command)
```

### Search (Search API / Solr)
```bash
./vendor/bin/drush search-api:status     # Show index status
./vendor/bin/drush search-api:index      # Index pending items
./vendor/bin/drush search-api:clear <index>  # Clear an index
./vendor/bin/drush search-api:reset-tracker <index>  # Reset tracker
```

### Queue Management
```bash
./vendor/bin/drush queue:list            # List all queues
./vendor/bin/drush queue:run <queue>     # Process a queue
./vendor/bin/drush queue:delete <queue>  # Delete a queue
```

### Locale/Translations
```bash
./vendor/bin/drush locale:check          # Check for updates
./vendor/bin/drush locale:update         # Download translations
./vendor/bin/drush locale:import <lang> <file.po> --type=customized --override=all
```

### Maintenance Mode
```bash
./vendor/bin/drush state:set system.maintenance_mode 1 -y  # Enable
./vendor/bin/drush state:set system.maintenance_mode 0 -y  # Disable
```

### State Management
```bash
./vendor/bin/drush state:get <key>       # Get state value
./vendor/bin/drush state:set <key> <val> # Set state value
./vendor/bin/drush state:delete <key>    # Delete state value
```

### PHP Evaluation
```bash
./vendor/bin/drush php:eval "echo PHP_VERSION;"  # Execute PHP code
./vendor/bin/drush php:script path/to/script.php  # Run a PHP script
```

### Site Status
```bash
./vendor/bin/drush core:status           # Full site status
./vendor/bin/drush status                # Short alias
./vendor/bin/drush core:requirements     # Check requirements
```

### Entity Updates
```bash
./vendor/bin/drush entup                 # Update entity definitions
```

### Migration Commands
```bash
./vendor/bin/drush migrate:status        # Migration status
./vendor/bin/drush mim <migration_id>    # Import migration
./vendor/bin/drush mr <migration_id>     # Rollback migration
./vendor/bin/drush mrs <migration_id>    # Reset migration status
```

## Best Practices

1. **Always use `-y`** flag for non-interactive execution
2. **Clear cache** after config changes: `./vendor/bin/drush cr`
3. **Run updb** after code updates: `./vendor/bin/drush updb -y`
4. **Check logs** when debugging: `./vendor/bin/drush watchdog:show`
5. **Export config** before making UI changes you want to keep
6. **Backup database** before running updates: `./vendor/bin/drush sql:dump --gzip > backup.sql.gz`
7. **Use maintenance mode** for major updates or deployments
