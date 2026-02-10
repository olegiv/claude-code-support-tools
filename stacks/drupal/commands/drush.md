---
description: Execute a drush command with documentation
argument-hint: <command> [arguments]
allowed-tools: Bash
---

Execute drush command: $ARGUMENTS

1. Validate the command is safe to run (no destructive operations without confirmation)

2. Execute the drush command:
   ```bash
   ./vendor/bin/drush $ARGUMENTS
   ```

3. Common drush commands for reference:
   - `cr` - Clear all caches
   - `status` - Show system status
   - `updb -y` - Run database updates
   - `cex -y` - Export configuration
   - `cim -y` - Import configuration
   - `fr <module> -y` - Revert feature
   - `en <module> -y` - Enable module
   - `pmu <module> -y` - Uninstall module
   - `uli` - Generate login link
   - `ws --count=50` - Show watchdog logs

4. Report the command output and any relevant next steps
