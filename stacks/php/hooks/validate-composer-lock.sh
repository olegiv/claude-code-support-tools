#!/bin/bash
# Warns if composer.lock is out of sync with composer.json
# Prevents running composer commands with stale dependencies

# Read JSON input from stdin
INPUT=$(cat)

# Extract the command from tool_input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Only check for composer install (not update, require, etc.)
if [[ "$COMMAND" != composer\ install* ]]; then
    exit 0
fi

# Check if both files exist
if [[ ! -f "composer.json" ]] || [[ ! -f "composer.lock" ]]; then
    exit 0
fi

# Check if composer.lock is older than composer.json
if [[ "composer.json" -nt "composer.lock" ]]; then
    echo "WARNING: composer.lock may be out of sync with composer.json" >&2
    echo "Consider running 'composer update' instead of 'composer install'" >&2
    echo "" >&2
    # Warning only, don't block
fi

exit 0
