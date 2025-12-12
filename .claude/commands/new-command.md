Create a new slash command with proper template and structure.

## Process

1. Ask the user for command details:
   - Command name (will be converted to kebab-case for filename)
   - Brief description of what the command does
   - Step-by-step workflow
   - Any agents or tools it should use
   - Whether it's a template or active command

2. Generate the command file with clear instructions:
   - Optional YAML frontmatter if description is needed
   - Clear, numbered steps
   - Specific file paths (absolute paths)
   - Tool usage (Read, Edit, Write, Bash, agent invocations)
   - Expected outcomes

3. Structure the command content:
   ```markdown
   [Brief description of what this command does]

   ## Process

   1. [First step with specific actions]
   2. [Second step]
   3. [Continue with clear steps]
   4. [Final step]

   [Any additional notes or warnings]
   ```

4. Choose the appropriate location:
   - For commands specific to this repo: `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/.claude/commands/`
   - For template commands (to be copied to other projects): `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/commands/`

5. Create the command file with the generated content

6. Validate the created command using the markdown-linter agent

7. Remind user to update documentation:
   - Run `/sync-docs` to update README.md and CLAUDE.md
   - Or manually add the command to documentation files

8. Provide usage example showing how to invoke the command:
   ```
   /command-name
   ```
