#!/bin/bash
set -euo pipefail
# Validates Go toolchain version matches go.mod before running Go commands
# Prevents builds with mismatched compiler versions

# Read JSON input from stdin
INPUT=$(cat)

# Extract the command from tool_input
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null) || COMMAND=""

# Only validate go commands (build, test, run, install)
if [[ "$COMMAND" != go\ build* ]] && [[ "$COMMAND" != go\ test* ]] && [[ "$COMMAND" != go\ run* ]] && [[ "$COMMAND" != go\ install* ]]; then
    exit 0
fi

# Check if go.mod exists
if [[ ! -f "go.mod" ]]; then
    exit 0
fi

# Get Go version from command
GO_VERSION=$(go version 2>/dev/null | awk '{print $3}') || GO_VERSION=""
if [[ -z "$GO_VERSION" ]]; then
    exit 0
fi

# Get compiler version (format: "compile version go1.X.Y").
# Assign GOTOOLDIR to its own variable before using it as a command path, so
# the outer command substitution quotes a single well-formed token. The raw
# $(go env GOTOOLDIR) expansion is subject to word-splitting even inside
# double quotes, which would fail on paths containing spaces or globs.
GOTOOLDIR="$(go env GOTOOLDIR)"
COMPILE_VERSION=$("$GOTOOLDIR/compile" -V 2>/dev/null | awk '{print $3}') || COMPILE_VERSION=""
if [[ -z "$COMPILE_VERSION" ]]; then
    exit 0
fi

# Compare versions (strip 'go' prefix for comparison)
GO_VER_NUM=${GO_VERSION#go}
COMPILE_VER_NUM=${COMPILE_VERSION#go}

if [[ "$GO_VER_NUM" != "$COMPILE_VER_NUM" ]]; then
    echo "BLOCKED: Go toolchain version mismatch detected." >&2
    echo "  go version: $GO_VERSION" >&2
    echo "  compiler:   go$COMPILE_VER_NUM" >&2
    echo "" >&2
    echo "Fix: Update your Go installation to match the compiler version." >&2
    echo "  brew upgrade go  # or download from https://go.dev/dl/" >&2
    exit 2
fi

exit 0
