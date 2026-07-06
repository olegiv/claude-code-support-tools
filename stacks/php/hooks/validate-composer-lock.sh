#!/bin/bash
set -euo pipefail
# Warns if composer.lock is out of sync with composer.json
# Uses composer validate for accurate hash-based comparison

# Read JSON input from stdin
INPUT=$(cat)

# Extract the command from tool_input
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null) || COMMAND=""

# Only check for composer install (not update, require, etc.)
if [[ "$COMMAND" != "composer install"* ]]; then
    exit 0
fi

# Check if both files exist
if [[ ! -f "composer.json" ]] || [[ ! -f "composer.lock" ]]; then
    exit 0
fi

# Check if composer is available
if ! command -v composer &>/dev/null; then
    exit 0
fi

# Use composer validate for accurate hash-based lock file check
if ! composer validate --check-lock --no-check-publish 2>/dev/null; then
    echo "WARNING: composer.lock is out of sync with composer.json" >&2
    echo "Consider running 'composer update' instead of 'composer install'" >&2
    echo "" >&2
    # Warning only, don't block
fi

exit 0
