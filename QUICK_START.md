# Quick Start Guide - Repository Maintenance Tools

This guide helps you use the newly generated Claude Code extensions for maintaining this repository.

## Overview

This repository now has specialized agents and commands for:
- Validating agent and command files
- Synchronizing documentation
- Quality assurance and best practices
- Release management
- Scaffolding new tools

## Available Agents

### markdown-linter
**When to use:** After creating or modifying agent/command files

**How to invoke:**
```
Use the markdown-linter agent to validate all agent and command files.
```

**What it does:**
- Validates YAML frontmatter syntax
- Checks required fields (name, description, model)
- Verifies kebab-case naming conventions
- Offers automated fixes for common issues

### doc-sync-manager
**When to use:** After adding new agents, commands, or workflows

**How to invoke:**
```
Use the doc-sync-manager agent to update documentation after my recent changes.
```

**What it does:**
- Detects new/modified tools
- Updates README.md and CLAUDE.md
- Ensures consistency across documentation
- Validates cross-references

### template-validator
**When to use:** Before releases or when reviewing contributions

**How to invoke:**
```
Use the template-validator agent to perform a quality review of all templates.
```

**What it does:**
- Validates agent and command quality
- Checks best practice compliance
- Performs security review
- Provides quality scores and recommendations

### release-manager
**When to use:** When preparing a new release

**How to invoke:**
```
Use the release-manager agent to prepare a new release.
```

**What it does:**
- Determines version number (semantic versioning)
- Generates CHANGELOG.md entries
- Creates release notes
- Runs pre-release quality checks
- Guides through git tagging and GitHub release

## Available Slash Commands

### /security-audit
**Purpose:** Perform comprehensive security audit of the project

**Usage:**
```
/security-audit
```

**What it does:**
- Invokes the security-auditor agent
- Analyzes application code for OWASP Top 10 vulnerabilities
- Audits dependencies for known CVEs
- Reviews configurations, authentication, APIs, and secrets
- Generates detailed reports in `.audit/` directory (never committed)

---

### /validate-agents
**Purpose:** Validate all agent files for proper structure

**Usage:**
```
/validate-agents
```

**What it does:**
- Scans `agents/` and `.claude/agents/` directories
- Validates YAML frontmatter and structure
- Reports errors with specific fixes

### /validate-commands
**Purpose:** Validate all command files for proper structure

**Usage:**
```
/validate-commands
```

**What it does:**
- Scans `.claude/commands/` and `commands/` directories
- Validates file structure and naming
- Reports errors with specific fixes

### /sync-docs
**Purpose:** Update documentation after adding/modifying tools

**Usage:**
```
/sync-docs
```

**What it does:**
- Updates README.md with new tools
- Updates CLAUDE.md with new tools
- Ensures documentation consistency

### /test-workflows
**Purpose:** Validate GitHub Actions workflow files

**Usage:**
```
/test-workflows
```

**What it does:**
- Validates YAML syntax in `.github/workflows/`
- Checks workflow structure
- Reviews security and permissions
- Verifies Claude Code Action usage

### /new-agent
**Purpose:** Create a new agent file with proper template

**Usage:**
```
/new-agent
```

**Interactive prompts:**
- Agent name
- Description and purpose
- Primary use cases
- Model preference (sonnet/opus/haiku)
- Location (template vs repository-specific)

**What it creates:**
- Properly formatted agent file
- Comprehensive agent prompt
- Validates the created file
- Reminds to run `/sync-docs`

### /new-command
**Purpose:** Create a new slash command file with proper template

**Usage:**
```
/new-command
```

**Interactive prompts:**
- Command name
- Description
- Step-by-step workflow
- Location (template vs repository-specific)

**What it creates:**
- Properly formatted command file
- Clear step-by-step instructions
- Validates the created file
- Reminds to run `/sync-docs`

## Common Workflows

### Adding a New Agent

1. **Create the agent:**
   ```
   /new-agent
   ```
   Follow the prompts to create the agent file.

2. **Validate the agent:**
   ```
   /validate-agents
   ```

3. **Update documentation:**
   ```
   /sync-docs
   ```

4. **Review documentation changes and commit:**
   ```
   /commit-prepare
   /commit-do
   ```

### Adding a New Command

1. **Create the command:**
   ```
   /new-command
   ```
   Follow the prompts to create the command file.

2. **Validate the command:**
   ```
   /validate-commands
   ```

3. **Update documentation:**
   ```
   /sync-docs
   ```

4. **Review documentation changes and commit:**
   ```
   /commit-prepare
   /commit-do
   ```

### Preparing a Release

1. **Run quality checks:**
   ```
   /validate-agents
   /validate-commands
   /test-workflows
   ```

2. **Ensure documentation is synchronized:**
   ```
   /sync-docs
   ```

3. **Prepare the release:**
   ```
   Use the release-manager agent to prepare version X.Y.Z
   ```

4. **Follow release manager guidance:**
   - Review generated CHANGELOG.md entry
   - Update version numbers
   - Create git tag
   - Create GitHub release

5. **Commit release changes:**
   ```
   /commit-prepare
   /commit-do
   ```

### Quality Assurance

1. **Validate all files:**
   ```
   /validate-agents
   /validate-commands
   /test-workflows
   ```

2. **Run comprehensive quality review:**
   ```
   Use the template-validator agent to perform a full quality audit
   ```

3. **Fix any issues found**

4. **Verify documentation is current:**
   ```
   /sync-docs
   ```

### Security Audit

1. **Run comprehensive security audit:**
   ```
   /security-audit
   ```

2. **Review generated reports in `.audit/` directory:**
   - `security-audit-application-code.md`
   - `security-audit-dependencies.md`
   - `security-audit-configuration.md`
   - `security-audit-authentication.md`
   - `security-audit-api.md`
   - `security-audit-secrets.md`
   - `security-audit-summary.md`

3. **Address high/critical findings**

4. **Update audit documentation after fixes:**
   - Modify relevant `.audit/*.md` files to reflect fix status
   - Document changes made to address vulnerabilities

5. **Re-run audit to verify fixes:**
   ```
   /security-audit
   ```

**Note:** The `.audit/` directory is gitignored and should never be committed.

## Best Practices

### Before Committing
- Run `/validate-agents` if you modified agent files
- Run `/validate-commands` if you modified command files
- Run `/sync-docs` if you added new tools
- Use `/commit-prepare` to review changes

### Before Opening a PR
- Run all validation commands
- Ensure documentation is synchronized
- Review changes for consistency

### Before Releasing
- Use `template-validator` agent for quality audit
- Use `release-manager` agent for release preparation
- Run all validation commands
- Update CHANGELOG.md
- Test that examples in documentation work

## File Locations

All commands and agents use absolute paths:

**Agent directories:**
- `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/agents/`
- `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/.claude/agents/`

**Command directories:**
- `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/.claude/commands/`
- `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/commands/`

**Workflow directory:**
- `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/.github/workflows/`

**Documentation files:**
- `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/README.md`
- `/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/CLAUDE.md`

## Troubleshooting

### Agent not recognized?
Run `/validate-agents` to check for YAML frontmatter errors.

### Command not showing up?
- Ensure the file is in `.claude/commands/` directory
- Check that the filename is kebab-case
- Run `/validate-commands` to check for issues

### Documentation out of sync?
Run `/sync-docs` to update all documentation files.

### Workflow failing on GitHub?
Run `/test-workflows` to validate workflow syntax locally.

## Additional Resources

- [Claude Code Documentation](https://code.claude.com/docs)
- [Agent SDK Documentation](https://code.claude.com/docs/agent-sdk)
- [GitHub Actions with Claude](https://github.com/anthropics/claude-code-action)

---

For more detailed information, see:
- [README.md](/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/README.md) - User-facing documentation
- [CLAUDE.md](/Users/olegiv/Desktop/Projects/AI/claude-code-support-tools/CLAUDE.md) - Repository guidance for Claude Code
