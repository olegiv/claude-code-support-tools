Use the markdown-linter agent to validate all agent files in the repository.

## Process

1. Scan for agent files in:
   - `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/agents/`
   - `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/.claude/agents/`

2. Validate each agent file for:
   - Valid YAML frontmatter
   - Required fields (name, description, model)
   - Proper field values
   - Kebab-case naming
   - Content after frontmatter

3. Provide a validation report with:
   - Total agents checked
   - Errors found (with file paths and specific issues)
   - Warnings and improvement suggestions
   - Success status or fix recommendations

4. If errors are found, offer to fix them automatically after showing proposed changes.
