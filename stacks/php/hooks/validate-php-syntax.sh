#!/bin/bash
set -euo pipefail
# Validates PHP syntax before running php commands
# Catches parse errors early before execution

# Read JSON input from stdin
INPUT=$(cat)

# Extract the command from tool_input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null) || COMMAND=""

# Only validate direct php file execution (php script.php)
if [[ "$COMMAND" != php\ * ]]; then
    exit 0
fi

# Extract the first .php file from the command (handles flags like php -d ... script.php)
PHP_FILE=$(echo "$COMMAND" | grep -oE '\S+\.php' | head -1) || PHP_FILE=""

# Skip if no .php file found
if [[ -z "$PHP_FILE" ]]; then
    exit 0
fi

# Skip if file doesn't exist
if [[ ! -f "$PHP_FILE" ]]; then
    exit 0
fi

# Run syntax check
if ! SYNTAX_CHECK=$(php -l "$PHP_FILE" 2>&1); then
    echo "BLOCKED: PHP syntax error detected in $PHP_FILE" >&2
    echo "$SYNTAX_CHECK" >&2
    echo "" >&2
    echo "Fix the syntax error before running this file." >&2
    exit 2
fi

exit 0
