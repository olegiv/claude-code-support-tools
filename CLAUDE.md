# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains Claude Code support tools including autonomous agents, slash commands, and global configuration files. These tools extend Claude Code functionality for development workflows, security auditing, and git operations.

## Repository Structure

### Directory Organization

- **`agents/`** - Custom autonomous agents for specialized tasks
  - `security-auditor.md` - Elite security auditing agent for comprehensive vulnerability analysis
- **`.claude/commands/`** - Project-specific slash commands for Claude Code
  - `commit-prepare.md` - Reviews changes and drafts commit messages
  - `commit-do.md` - Creates commits using prepared messages
- **`commands/`** - Alternative command structures (e.g., `no-ticket/` for workflows without ticket references)
- **`global/`** - Global configuration files meant to be copied to user's `~/.claude/` directory
  - `CLAUDE.md` - Global development rules applied to all projects
  - `settings.json` - Global settings including custom status line and alwaysThinking mode
- **`.github/workflows/`** - GitHub Actions workflows for CI/CD automation
  - `claude.yml` - Responds to @claude mentions in issues/PRs
  - `claude-code-review.yml` - Automated PR reviews using Claude Code

## Agent System

### security-auditor Agent

The security auditor is an elite Application Security Engineer agent that performs comprehensive security audits. Use it for:

- Pre-release security audits
- Analyzing new dependencies or vendor code
- Periodic security reviews
- Investigating potential security incidents
- Pre-production deployment checks

**Key capabilities:**
- OWASP Top 10 vulnerability detection
- CVE database checking (NVD, GitHub Advisory)
- Static Application Security Testing (SAST)
- Dependency analysis (SCA)
- Configuration security auditing
- Secrets detection

**Report generation:** Creates structured markdown reports for each audit area:
- `security-audit-application-code.md`
- `security-audit-dependencies.md`
- `security-audit-configuration.md`
- `security-audit-authentication.md`
- `security-audit-api.md`
- `security-audit-secrets.md`
- `security-audit-summary.md`

## Slash Commands

### Commit Workflow Commands

Two-step commit workflow enforcing the repository's strict git policies:

1. **`/commit-prepare`** - Review and prepare commit message
   - Runs `git status` and `git diff`
   - Reviews recent commit style
   - Drafts commit message following best practices
   - Does NOT create the commit yet

2. **`/commit-do`** - Create commit with prepared message
   - Verifies changes exist
   - Stages all changes with `git add .`
   - Creates commit using HEREDOC format
   - Does NOT push automatically

**Commit message format enforced:**
- Subject line: max 50 chars, imperative mood, no period
- Body: wrapped at 72 chars, explains what and why
- No AI attribution footers (no Claude Code branding)

## GitHub Actions Integration

### PR Review Workflow (`claude-code-review.yml`)

Automatically runs on PR open/sync events. Claude performs code review checking:
- Code quality and best practices
- Potential bugs or issues
- Performance considerations
- Security concerns
- Test coverage

**Allowed tools:** Limited to GitHub CLI commands for viewing and commenting on PRs.

### Mention Response Workflow (`claude.yml`)

Triggers when `@claude` is mentioned in:
- Issue comments
- PR review comments
- PR reviews
- New issues (title or body)

Claude responds with full repository access and can perform requested tasks.

## Global Configuration Files

The `global/` directory contains templates for user-level configuration:

### global/CLAUDE.md

Enforces strict git workflow rules across all projects:

**Critical policies:**
- Never commit or push unless explicitly instructed
- No automatic commits after completing tasks
- User controls when and what to commit
- Clean commit messages without AI attribution
- Separate `.claude/settings.json` (team, committed) from `.claude/settings.local.json` (personal, gitignored)

**Platform compatibility:**
- macOS-specific command syntax when `Platform: darwin`
- BSD-compatible tools instead of GNU equivalents

### global/settings.json

Global Claude Code settings:
- **Custom status line** - Shows project name, directory, git branch, git status, and model
- **alwaysThinkingEnabled** - Enables continuous thinking mode

## Development Workflow

When working with this repository:

1. **Adding new agents:** Create markdown files in `agents/` with YAML frontmatter defining name, description, model, and agent prompt
2. **Adding slash commands:** Create markdown files in `.claude/commands/` with command instructions
3. **Testing configurations:** Use `.claude/settings.local.json` for personal testing (never commit)
4. **Team configurations:** Use `.claude/settings.json` for shared settings (commit these)
5. **GitHub Actions:** Test workflows with the anthropics/claude-code-action integration

## File Naming Conventions

- Agent files: `kebab-case.md` in `agents/`
- Command files: `kebab-case.md` in `.claude/commands/`
- Global files: Uppercase `CLAUDE.md`, lowercase `settings.json`

## Important Notes

- This is a tools repository, not an application - there are no build, test, or run commands
- All functionality is defined in markdown agent definitions and command files
- The repository itself serves as templates and examples for Claude Code extensions
- Security auditor agent has comprehensive vulnerability detection capabilities - review its methodology before use
