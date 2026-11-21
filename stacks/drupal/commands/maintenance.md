---
description: Toggle maintenance mode
argument-hint: "[on|off]"
allowed-tools: Bash
---

# Maintenance Mode

**Check the arguments before running anything.** The command arguments are inserted into this prompt before any shell runs, so the shell checks below cannot protect a command that contains them. Check them yourself first: they must be empty, `on` or `off`. The whole value must match, on a single line; if you are unsure whether it matches, treat it as invalid. If it does not match, stop and report the invalid argument without running any command. Run the steps below only with arguments that passed this check; their shell blocks read the value from `ARGS`.

Toggle Drupal maintenance mode on or off.

## Arguments

- `$ARGUMENTS` - Action: `on` or `off`

## Instructions

### 0. Validate Input
```bash
ARGS='$ARGUMENTS'  # passed the argument check above, so it contains no '
if [ -n "${ARGS}" ]; then
  if [ ${#ARGS} -gt 10 ]; then
    echo "ERROR: Input too long (max 10 characters)"
    exit 1
  fi
  if ! printf '%s' "$ARGS" | grep -qE '^(on|off)$'; then
    echo "ERROR: Invalid argument '$ARGS'. Use 'on' or 'off'"
    exit 1
  fi
fi
```

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
