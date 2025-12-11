# Claude Code Support Tools

A collection of powerful extensions for [Claude Code](https://claude.ai/code) including autonomous agents, slash commands, global configurations, and GitHub Actions workflows.

## What's Inside

### 🤖 Autonomous Agents

**Security Auditor** (`agents/security-auditor.md`)
- Elite Application Security Engineer with 15+ years of simulated expertise
- Comprehensive vulnerability scanning (OWASP Top 10, CVE databases)
- Static Application Security Testing (SAST) and dependency analysis
- Generates structured security audit reports with remediation guidance
- Use for pre-release audits, dependency checks, and security reviews

### ⚡ Slash Commands

**Commit Workflow Commands**
- `/commit-prepare` - Review changes and draft commit messages following best practices
- `/commit-do` - Create commits with proper formatting and HEREDOC syntax

Both commands enforce strict commit message standards:
- Subject line: max 50 chars, imperative mood
- Body: wrapped at 72 chars, explains what and why
- Clean messages without AI attribution footers

### 🌐 Global Configuration Templates

Located in `global/` directory - copy these to your `~/.claude/` directory:

**`global/CLAUDE.md`**
- Strict git workflow rules (no automatic commits/pushes)
- Commit message formatting standards
- Platform-specific command compatibility (macOS/Linux)
- Permission file management guidelines

**`global/settings.json`**
- Custom status line showing project, git branch, and model
- Always-thinking mode enabled
- Template for team-wide settings

### 🔄 GitHub Actions Workflows

**Automated PR Reviews** (`.github/workflows/claude-code-review.yml`)
- Runs on PR open/synchronize events
- Reviews code quality, security, performance, and test coverage
- Posts feedback as PR comments

**@claude Mention Response** (`.github/workflows/claude.yml`)
- Triggers when `@claude` is mentioned in issues or PRs
- Responds to requests with full repository access
- Supports issue comments, PR reviews, and new issues

## Installation

### Using Agents

Copy agent files to your project's `.claude/agents/` directory:

```bash
cp agents/security-auditor.md /path/to/your/project/.claude/agents/
```

Then invoke in Claude Code:
```bash
# In Claude Code conversation
Please use the security-auditor agent to audit this codebase
```

### Using Slash Commands

Copy command files to your project's `.claude/commands/` directory:

```bash
cp .claude/commands/commit-prepare.md /path/to/your/project/.claude/commands/
cp .claude/commands/commit-do.md /path/to/your/project/.claude/commands/
```

Then use in Claude Code:
```bash
/commit-prepare
/commit-do
```

### Using Global Configurations

Copy global files to your `~/.claude/` directory:

```bash
# Create directory if it doesn't exist
mkdir -p ~/.claude

# Copy global configuration
cp global/CLAUDE.md ~/.claude/
cp global/settings.json ~/.claude/
```

These will apply to all your Claude Code sessions across all projects.

### Setting Up GitHub Actions

1. **Generate Claude Code OAuth Token**
   - Visit [Claude Code settings](https://claude.ai/code/settings)
   - Generate a new OAuth token for GitHub Actions

2. **Add Secret to Repository**
   - Go to your repository Settings > Secrets and variables > Actions
   - Add new secret: `CLAUDE_CODE_OAUTH_TOKEN`
   - Paste your OAuth token

3. **Copy Workflow Files**
   ```bash
   mkdir -p .github/workflows
   cp .github/workflows/claude-code-review.yml .github/workflows/
   cp .github/workflows/claude.yml .github/workflows/
   ```

4. **Customize as Needed**
   - Edit `claude_args` to restrict or expand allowed tools
   - Modify triggers and filters for your workflow
   - Adjust review prompts and criteria

## Usage Examples

### Security Audit

```bash
# In Claude Code
Use the security-auditor agent to perform a comprehensive security audit
of this codebase, focusing on authentication and API endpoints.
```

The agent will generate multiple markdown reports:
- `security-audit-application-code.md`
- `security-audit-dependencies.md`
- `security-audit-authentication.md`
- `security-audit-api.md`
- `security-audit-summary.md`

### Commit Workflow

```bash
# Step 1: Review changes and prepare message
/commit-prepare

# Step 2: Create the commit
/commit-do
```

### GitHub Actions PR Review

Simply open a PR and the security-auditor will automatically:
1. Analyze the changes
2. Check for bugs, security issues, and code quality
3. Post a review comment with findings

### @claude Mentions

In any issue or PR comment:
```
@claude can you add unit tests for the new authentication module?
```

Claude will respond and complete the task with full repository access.

## Directory Structure

```
.
├── agents/                    # Autonomous agent definitions
│   └── security-auditor.md
├── .claude/
│   └── commands/              # Project-specific slash commands
│       ├── commit-prepare.md
│       └── commit-do.md
├── commands/
│   └── no-ticket/             # Alternative command structures
├── global/                    # User-level configuration templates
│   ├── CLAUDE.md
│   └── settings.json
└── .github/
    └── workflows/             # GitHub Actions workflows
        ├── claude.yml
        └── claude-code-review.yml
```

## Contributing

Feel free to add your own:
- **Agents** - Create specialized agents for different domains (testing, refactoring, documentation, etc.)
- **Commands** - Build workflow-specific slash commands
- **Workflows** - Share GitHub Actions configurations for different use cases

## Resources

- [Claude Code Documentation](https://code.claude.com/docs)
- [Claude Code GitHub Action](https://github.com/anthropics/claude-code-action)
- [Agent SDK Documentation](https://code.claude.com/docs/agent-sdk)

## License

MIT License - see [LICENSE](LICENSE) file for details.
