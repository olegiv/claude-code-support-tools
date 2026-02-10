#!/bin/bash
# Validates go test commands include recommended flags
# Warns if -race flag is missing for non-short tests

# Read JSON input from stdin
INPUT=$(cat)

# Extract the command from tool_input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Only validate go test commands
if [[ "$COMMAND" != go\ test* ]]; then
    exit 0
fi

# Skip validation for short tests or benchmarks
if [[ "$COMMAND" == *"-short"* ]] || [[ "$COMMAND" == *"-bench"* ]]; then
    exit 0
fi

# Skip if already has -race flag
if [[ "$COMMAND" == *"-race"* ]]; then
    exit 0
fi

# Skip for coverage-only runs
if [[ "$COMMAND" == *"-coverprofile"* ]] || [[ "$COMMAND" == *"-cover"* ]]; then
    exit 0
fi

# Warn but don't block - race detection is recommended but not required
echo "NOTE: Consider adding -race flag for race condition detection." >&2
echo "  Command: $COMMAND" >&2
echo "  Suggested: $COMMAND -race" >&2

# Exit 0 to allow the command (just a warning)
exit 0
