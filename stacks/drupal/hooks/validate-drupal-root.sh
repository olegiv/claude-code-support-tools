#!/bin/bash
# Validates that drush/phpunit commands run from the Drupal root directory
# Prevents "Drupal not found" errors when running from wrong directory

# Read JSON input from stdin
INPUT=$(cat)

# Extract the command from tool_input
COMMAND=$(echo "$INPUT" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('tool_input', {}).get('command', ''))" 2>/dev/null)

# Only validate drush and phpunit commands
if [[ "$COMMAND" != *drush* ]] && [[ "$COMMAND" != *phpunit* ]]; then
    exit 0
fi

# Check if we're in a Drupal root (core/lib/Drupal.php exists)
if [[ -f "core/lib/Drupal.php" ]]; then
    exit 0
fi

# Also check one level up (in case running from a subdirectory)
if [[ -f "../core/lib/Drupal.php" ]]; then
    echo "WARNING: You appear to be in a subdirectory. Drush/PHPUnit should run from the Drupal root." >&2
    # Warning only, don't block
    exit 0
fi

echo "WARNING: Current directory may not be a Drupal root (core/lib/Drupal.php not found)." >&2
echo "Drush and PHPUnit commands should be run from the Drupal project root directory." >&2
# Warning only, don't block - the user may have a non-standard layout
exit 0
