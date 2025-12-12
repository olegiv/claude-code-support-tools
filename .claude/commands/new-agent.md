Create a new Claude Code agent with proper template and structure.

## Process

1. Ask the user for agent details:
   - Agent name (will be converted to kebab-case)
   - Brief description of the agent's purpose
   - Primary use cases and when to invoke
   - Model preference (sonnet, opus, or haiku)

2. Generate the agent file with proper YAML frontmatter:
   ```yaml
   ---
   name: agent-name
   description: Clear description of when to use this agent with examples
   model: sonnet
   ---
   ```

3. Create a comprehensive agent prompt including:
   - Role and expertise statement
   - Key responsibilities and capabilities
   - Process/workflow steps
   - Output format specifications
   - Best practices and guidelines
   - Example scenarios

4. Choose the appropriate location:
   - For meta-tools (agents that work on this repo): `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/.claude/agents/`
   - For template agents (to be copied to other projects): `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/agents/`

5. Create the agent file with the generated content

6. Validate the created agent using the markdown-linter agent

7. Remind user to update documentation:
   - Run `/sync-docs` to update README.md and CLAUDE.md
   - Or manually add the agent to documentation files

8. Provide usage example for the new agent
