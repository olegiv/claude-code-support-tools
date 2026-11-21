---
description: "Check and update Composer dependencies (optional: package name)"
argument-hint: [package-name]
allowed-tools: Bash, Read
---

Check and update dependencies: $ARGUMENTS

**Check the arguments before running anything.** The command arguments are inserted into this prompt before any shell runs, so the shell checks below cannot protect a command that contains them. Check them yourself first: they must be empty or one package name matching `^[a-zA-Z0-9_./-]+$` that contains no `..` and starts with neither `/` nor `-`. The whole value must match, on a single line; if you are unsure whether it matches, treat it as invalid. If it does not match, stop and report the invalid argument without running any command. Run the steps below only with arguments that passed this check; their shell blocks read the value from `ARGS`.

1. Validate input if provided:
   ```bash
   ARGS='$ARGUMENTS'  # passed the argument check above, so it contains no '
   if [ -n "${ARGS}" ]; then
     if [ ${#ARGS} -gt 128 ]; then
       echo "ERROR: Input too long (max 128 characters)"
       exit 1
     fi
     if printf '%s' "$ARGS" | grep -qE '\.\.'; then
       echo "ERROR: Path traversal not allowed"
       exit 1
     fi
     if printf '%s' "$ARGS" | grep -qE '^/'; then
       echo "ERROR: Absolute paths not allowed"
       exit 1
     fi
     if ! printf '%s' "$ARGS" | grep -qE '^[a-zA-Z0-9_./-]+$'; then
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
   ARGS='$ARGUMENTS'  # passed the argument check above, so it contains no '
   composer show -- "$ARGS"
   composer why -- "$ARGS"
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
