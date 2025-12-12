Use the doc-sync-manager agent to synchronize documentation after adding or modifying agents, commands, or workflows.

## Process

1. Detect recent changes:
   - Scan `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/agents/` for new/modified agents
   - Scan `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/.claude/agents/` for new/modified agents
   - Scan `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/.claude/commands/` for new/modified commands
   - Scan `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/commands/` for command templates
   - Check `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/.github/workflows/` for workflow changes

2. Analyze impact:
   - Determine which documentation sections need updates
   - Identify any inconsistencies between docs and actual files
   - Plan synchronization updates

3. Generate updates for:
   - `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/README.md`
   - `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/CLAUDE.md`
   - Any other relevant documentation files

4. Show proposed changes to user for review

5. Apply updates after user approval

6. Verify all documentation is synchronized and consistent
