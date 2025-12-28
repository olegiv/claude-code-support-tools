#!/bin/bash
# Validates xcodebuild commands use iPhone 17 Pro simulator

# Read JSON input from stdin
INPUT=$(cat)

# Extract the command from tool_input
COMMAND=$(echo "$INPUT" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('tool_input', {}).get('command', ''))" 2>/dev/null)

# Only validate xcodebuild commands
if [[ "$COMMAND" != *"xcodebuild"* ]]; then
    exit 0
fi

# Check for correct simulator
if [[ "$COMMAND" == *"iPhone 17 Pro"* ]] || [[ "$COMMAND" == *"iPhone 17 Pro Max"* ]]; then
    exit 0
fi

# Check if destination is specified but wrong
if [[ "$COMMAND" == *"-destination"* ]]; then
    echo "BLOCKED: xcodebuild must use 'iPhone 17 Pro' or 'iPhone 17 Pro Max' simulator." >&2
    echo "Found command: $COMMAND" >&2
    exit 2
fi

# If no destination specified, allow (might be a clean or other non-build command)
exit 0
