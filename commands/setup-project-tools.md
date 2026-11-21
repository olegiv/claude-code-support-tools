Analyze the current project and generate tailored Claude Code agents, skills, and commands.

Use the Task tool to launch the project-architect agent with the following prompt:

"Analyze this project's architecture, tools, frameworks, libraries, and development workflows. Then generate customized Claude Code agents, skills, and slash commands tailored to this specific tech stack. Create these in the .claude/ directory structure."

The agent will:
1. Discover the project's tech stack (languages, frameworks, build tools, testing, linting)
2. Identify common development workflows
3. Generate project-specific agents in .claude/agents/
4. Generate slash commands in .claude/commands/
5. Generate skills in .claude/skills/ if needed
6. Document the generated tools where the agent's Document step says: normally `AGENTS.md`, imported by `CLAUDE.md` via `@AGENTS.md`. Projects not yet migrated are updated in place, and the `agents-md` skill is suggested
7. Give a quick start guide for the generated tools
