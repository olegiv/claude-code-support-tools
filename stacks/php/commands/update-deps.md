---
description: Check and update Composer dependencies (optional: package name)
argument-hint: [package-name]
allowed-tools: Bash, Read
---

Check and update dependencies: $ARGUMENTS

1. First, check for outdated packages:
   ```bash
   composer outdated
   ```

2. Run security audit:
   ```bash
   composer audit
   ```

3. If a package name is provided, show details:
   ```bash
   composer show $1
   composer why $1
   ```

4. Report:
   - Outdated packages list
   - Security vulnerabilities found
   - Recommended updates
   - Breaking changes to watch for

5. Ask the user if they want to proceed with updates before running:
   ```bash
   composer update <package-name>
   ```

IMPORTANT: Do NOT automatically run updates. Always ask for user confirmation first.
