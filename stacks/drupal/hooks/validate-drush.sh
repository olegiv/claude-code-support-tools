#!/bin/bash
set -euo pipefail
# Validates that drush is available before running drush commands
# Prevents confusing "command not found" errors

# Read JSON input from stdin
INPUT=$(cat)

# Extract the command from tool_input
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null) || COMMAND=""

# Only validate actual drush command invocations (not substrings like "drush/drush")
if ! printf '%s' "$COMMAND" | grep -qE '(^|[;&|[:space:]])(\.\/)?vendor/bin/drush\b|(^|[;&|[:space:]])drush\b'; then
    exit 0
fi

# Check if drush exists
if [[ -f "./vendor/bin/drush" ]]; then
    exit 0
fi

# Check if drush is in PATH
if command -v drush &>/dev/null; then
    exit 0
fi

echo "BLOCKED: Drush not found." >&2
echo "  Expected: ./vendor/bin/drush" >&2
echo "" >&2
echo "Fix: Run 'composer install' or check that you're in the Drupal project root." >&2
exit 2
