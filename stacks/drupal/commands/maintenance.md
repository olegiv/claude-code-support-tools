---
description: Toggle maintenance mode
argument-hint: "[on|off]"
allowed-tools: Bash
---

# Maintenance Mode

Toggle Drupal maintenance mode on or off.

## Arguments

- `$ARGUMENTS` - Action: `on` or `off`

## Instructions

### 1. Enable Maintenance Mode

If "on" is specified:

```bash
./vendor/bin/drush state:set system.maintenance_mode 1 -y
./vendor/bin/drush cr
```

Warn the user that the site will be unavailable to anonymous visitors.

### 2. Disable Maintenance Mode

If "off" is specified:

```bash
./vendor/bin/drush state:set system.maintenance_mode 0 -y
./vendor/bin/drush cr
```

Confirm the site is accessible to visitors again.

### 3. No Argument

If no argument is provided, check the current status first:

```bash
./vendor/bin/drush state:get system.maintenance_mode 2>&1
```

Then ask the user whether to enable or disable maintenance mode.

### 4. Verify

After the change, confirm the current state:

```bash
./vendor/bin/drush state:get system.maintenance_mode 2>&1
```

Report the current maintenance mode status.
