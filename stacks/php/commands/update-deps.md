---
description: "Check and update Composer dependencies (optional: package name)"
argument-hint: [package-name]
allowed-tools: Bash(composer:*), Read
---

Check and update dependencies: $ARGUMENTS

1. Validate input if provided:
   ```bash
   if [ -n "${ARGUMENTS:-}" ]; then
     if [ ${#ARGUMENTS} -gt 128 ]; then
       echo "ERROR: Input too long (max 128 characters)"
       exit 1
     fi
     if printf '%s' "$ARGUMENTS" | grep -qE '\.\.'; then
       echo "ERROR: Path traversal not allowed"
       exit 1
     fi
     if printf '%s' "$ARGUMENTS" | grep -qE '^/'; then
       echo "ERROR: Absolute paths not allowed"
       exit 1
     fi
     if ! printf '%s' "$ARGUMENTS" | grep -qE '^[a-zA-Z0-9_./-]+$'; then
       echo "ERROR: Invalid package name. Only alphanumeric, dots, slashes, hyphens, underscores allowed."
       exit 1
     fi
   fi
   ```

2. First, check for outdated packages:
   ```bash
   composer outdated
   ```

3. Run security audit:
   ```bash
   composer audit
   ```

4. If a package name is provided, show details:
   ```bash
   composer show -- "$ARGUMENTS"
   composer why -- "$ARGUMENTS"
   ```

5. Report:
   - Outdated packages list
   - Security vulnerabilities found
   - Recommended updates
   - Breaking changes to watch for

6. Ask the user if they want to proceed with updates before running:
   ```bash
   composer update <package-name>
   ```

IMPORTANT: Do NOT automatically run updates. Always ask for user confirmation first.
