Use the markdown-linter agent to validate all slash command files in the repository.

## Process

1. Scan for command files in:
   - `.claude/commands/`
   - `commands/`

2. Validate each command file for:
   - Valid YAML frontmatter (if present)
   - Kebab-case naming
   - Clear step-by-step instructions
   - Content quality
   - Proper markdown formatting

3. Provide a validation report with:
   - Total commands checked
   - Errors found (with file paths and specific issues)
   - Warnings and improvement suggestions
   - Success status or fix recommendations

4. If errors are found, offer to fix them automatically after showing proposed changes.
