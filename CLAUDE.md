# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains Claude Code support tools including autonomous agents, slash commands, and global configuration files. These tools extend Claude Code functionality for development workflows, security auditing, and git operations.

## Repository Structure

### Directory Organization

- **`agents/`** - Custom autonomous agents for specialized tasks
  - `security-auditor.md` - Elite security auditing agent for comprehensive vulnerability analysis
  - `project-architect.md` - Project analysis agent that generates tailored Claude Code extensions
- **`.claude/agents/`** - Repository-specific agents for maintaining this project
  - `markdown-linter.md` - Validates agent and command files for proper structure and syntax
  - `doc-sync-manager.md` - Synchronizes documentation across README.md and CLAUDE.md
  - `template-validator.md` - Ensures templates follow Claude Code best practices
  - `release-manager.md` - Manages versioning, changelog generation, and releases
- **`.claude/commands/`** - Project-specific slash commands for Claude Code
  - `commit-prepare.md` - Reviews changes and drafts commit messages
  - `commit-do.md` - Creates commits using prepared messages
  - `security-audit.md` - Performs comprehensive security audit of the project
  - `validate-agents.md` - Validates all agent files for proper structure
  - `validate-commands.md` - Validates all command files for proper structure
  - `sync-docs.md` - Synchronizes documentation after adding/modifying tools
  - `test-workflows.md` - Validates GitHub Actions workflow syntax
  - `new-agent.md` - Scaffolds new agent files with proper template
  - `new-command.md` - Scaffolds new command files with proper template
  - `finalize.md` - Reviews session changes and runs tests, translations, or docs updates
- **`commands/`** - Template commands for copying to projects
  - `setup-project-tools.md` - Analyzes project and generates tailored Claude Code extensions
  - `no-ticket/` - Alternative command structures for workflows without ticket references
- **`stacks/`** - Stack-specific configurations and hooks
  - `go/` - Go project tools
    - `settings.json` - Hook configuration for Go command validation
    - `hooks/validate-go-toolchain.sh` - Blocks builds on version mismatch
    - `hooks/validate-go-test.sh` - Recommends race detection for tests
    - `agents/code-quality-auditor.md` - Comprehensive code quality scanning
    - `commands/code-quality.md` - Run quality checks command
    - `commands/commit-prepare.md` - Commit with quality integration
    - `commands/fly-deploy.md` - Deploy Go app to Fly.io
  - `swift/` - Swift/Xcode project tools
    - `settings.json` - Hook configuration for xcodebuild validation
    - `hooks/validate-xcodebuild.sh` - Ensures correct simulator target (iPhone 17 Pro)
  - `kotlin/` - Kotlin/Android project tools
    - `agents/android-quality-auditor.md` - Comprehensive Android code quality scanning
    - `agents/kotlin-refactorer.md` - Kotlin refactoring and best practices
    - `agents/compose-developer.md` - Jetpack Compose UI development
    - `commands/code-quality.md` - Run quality checks command
    - `commands/lint.md` - Run Android Lint command
    - `commands/detekt.md` - Run Detekt static analysis command
    - `commands/clean.md` - Clean build artifacts command
    - `commands/test-instrumented.md` - Run instrumented tests command
    - `templates/detekt.yml` - Detekt configuration template for Android/Compose projects
  - `php/` - PHP project tools
    - `settings.json` - Hook configuration for PHP command validation
    - `hooks/validate-php-syntax.sh` - Validates PHP syntax before execution
    - `hooks/validate-composer-lock.sh` - Ensures composer.lock stays in sync with composer.json
    - `agents/composer-manager.md` - Composer dependency management agent
    - `agents/security-reviewer.md` - PHP security scanning and code review agent
    - `agents/php-refactorer.md` - PHP refactoring and modern best practices agent
    - `commands/phpstan.md` - Run PHPStan static analysis command
    - `commands/update-deps.md` - Update Composer dependencies command
    - `commands/security-scan.md` - PHP security scanning command
    - `skills/security-review/SKILL.md` - PHP security review skill
  - `drupal/` - Drupal project tools
    - `settings.json` - Hook configuration for Drupal command validation
    - `hooks/validate-drush.sh` - Validates drush command execution context
    - `hooks/validate-drupal-root.sh` - Ensures commands run from Drupal root directory
    - `agents/drupal-debugger.md` - Debug errors, test failures, configuration issues
    - `agents/drush-helper.md` - Drush commands and system administration
    - `agents/config-reviewer.md` - Configuration safety and deployment readiness
    - `agents/performance-tuner.md` - Redis, caching, database optimization
    - `agents/test-creator.md` - Generate PHPUnit tests for Drupal modules
    - `agents/api-developer.md` - REST/JSON:API development, external integrations
    - `agents/migration-expert.md` - Content migrations, CRM sync, data transformations
    - `agents/code-quality-auditor.md` - Scan PHPStan/PHPCS/deprecation issues, offer fixes (read-only)
    - `commands/cache-clear.md` - Clear all Drupal caches
    - `commands/code-quality.md` - Comprehensive code quality checks (PHPStan, PHPCS, deprecations)
    - `commands/config-diff.md` - Show configuration differences (database vs code)
    - `commands/config-export.md` - Export Drupal configuration
    - `commands/config-import.md` - Import Drupal configuration
    - `commands/backup-db.md` - Create database backup
    - `commands/db-query.md` - Execute safe SELECT queries
    - `commands/db-update.md` - Run database updates
    - `commands/drush.md` - Execute drush commands
    - `commands/feature-revert.md` - Revert feature configuration
    - `commands/health-check.md` - Site health: DB, Redis, Solr, cron
    - `commands/logs.md` - View watchdog logs
    - `commands/module-status.md` - Module status information
    - `commands/test-run.md` - Run PHPUnit tests
    - `commands/content-audit.md` - Find orphaned, unpublished, or stale content
    - `commands/cron-status.md` - Cron job and scheduled task status
    - `commands/deploy-check.md` - Pre-deployment readiness checklist
    - `commands/maintenance.md` - Toggle maintenance mode
    - `commands/queue-status.md` - Queue items and workers status
    - `commands/scaffold.md` - Generate Drupal boilerplate code
    - `commands/test-coverage.md` - Check test coverage for modules
    - `commands/test-create.md` - Generate PHPUnit tests for classes or modules
    - `commands/translate-check.md` - Translation status and coverage
    - `commands/user-info.md` - User details and roles lookup
    - `skills/api-development/` - REST/JSON:API development skill
    - `skills/config-management/` - Features workflow, config splits, deployment
    - `skills/database-operations/` - PostgreSQL backup/restore operations
    - `skills/drupal-drush/` - Comprehensive Drush command reference
    - `skills/drupal-hooks/` - Hook and event subscriber patterns
    - `skills/drupal-migrations/` - Migration YAMLs, source/process plugins
    - `skills/drupal-testing/` - PHPUnit tests, mocking, assertions
    - `skills/performance-optimization/` - Redis, caching, PostgreSQL tuning
    - `templates/phpunit.xml.dist` - Standard PHPUnit configuration for custom module testing
    - `templates/phpstan.neon` - Base PHPStan configuration for Drupal projects
- **`global/`** - Global configuration files meant to be copied to user's `~/.claude/` directory
  - `CLAUDE.md` - Global development rules applied to all projects
  - `settings.json` - Global settings including custom status line and alwaysThinking mode
  - `commands/` - Global slash command templates
    - `finalize.md` - Reviews session changes and runs tests, translations, or docs updates
    - `release-gh-prepare.md` - Cuts a new version: updates CHANGELOG.md, commits, pushes, and creates a GitHub draft release. Mandatory user approval of the proposed version.
  - `tests/` - Self-contained POSIX shell tests for global configuration
    - `statusline-cwd-test.sh` - Tests status line `cwd` validation (anti-injection + valid path acceptance)
- **`.github/workflows/`** - GitHub Actions workflows for CI/CD automation
  - `claude.yml` - Responds to @claude mentions in issues/PRs
  - `claude-code-review.yml` - Automated PR reviews using Claude Code
- **`.github/`** - Security documentation
  - `THREAT_MODEL.md` - Security threat model with attack scenarios and mitigations
  - `SUPPLY_CHAIN_SECURITY.md` - Supply chain security policy and dependency inventory
- **`SECURITY.md`** - Vulnerability disclosure policy and incident response procedures

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

### project-architect Agent

The project architect is an elite Software Architect agent that analyzes projects and generates tailored Claude Code extensions. Use it for:

- Setting up Claude Code for a new project
- Understanding project architecture and tooling
- Creating project-specific development workflows
- After major tech stack changes to update Claude Code extensions

**Key capabilities:**
- Detects programming languages, frameworks, and libraries
- Identifies build tools, test frameworks, and linters
- Analyzes CI/CD configuration and workflows
- Generates custom agents for project-specific tasks
- Creates slash commands for common development workflows
- Produces skills for reusable capabilities

**Generated extensions:** Creates files in `.claude/` directory:
- Custom agents in `.claude/agents/` (test-runner, build-manager, linter-helper, deploy-assistant, etc.)
- Slash commands in `.claude/commands/` (/test, /build, /lint, /deploy, etc.)
- Skills in `.claude/skills/` if applicable
- **Updates existing documentation** (CLAUDE.md, README.md, etc.) to document new tools
- Quick start guide for using the generated extensions

### Repository Maintenance Agents

These agents help maintain this Claude Code support tools repository:

#### markdown-linter Agent

Validates agent and command markdown files for proper YAML frontmatter and structure. Use it for:
- Validating agent files after creation or modification
- Checking command files for proper formatting
- Troubleshooting why agents/commands aren't recognized
- Pre-commit validation of markdown files

**Key capabilities:**
- YAML frontmatter syntax validation
- Required field verification (name, description, model)
- Kebab-case naming convention checks
- Content structure validation
- Automated fix suggestions

#### doc-sync-manager Agent

Synchronizes documentation across README.md and CLAUDE.md when tools are added or modified. Use it for:
- Updating documentation after adding new agents
- Updating documentation after adding new commands
- Ensuring consistency across documentation files
- Preparing documentation for releases

**Key capabilities:**
- Detects new/modified agents and commands
- Analyzes documentation impact
- Generates consistent documentation updates
- Validates cross-references
- Maintains documentation standards

#### template-validator Agent

Validates that agent and command templates follow Claude Code best practices. Use it for:
- Reviewing contributions before merging
- Quality assurance before releases
- Ensuring templates meet standards
- Identifying common anti-patterns

**Key capabilities:**
- Structure and content quality validation
- Best practice compliance checking
- Security and safety review
- Consistency verification across files
- Quality scoring and recommendations

#### release-manager Agent

Manages versioning, changelog generation, and release preparation. Use it for:
- Preparing new releases
- Generating changelogs from git history
- Creating release notes
- Managing git tags and versions
- Post-release verification

**Key capabilities:**
- Semantic versioning analysis
- CHANGELOG.md generation
- Documentation update verification
- Pre-release quality checks
- GitHub release creation guidance

## Slash Commands

### Project Setup Command

**`/setup-project-tools`** - Automatically analyze project and generate tailored extensions
- Invokes the project-architect agent
- Analyzes the current project's tech stack
- Generates custom agents, skills, and commands
- Creates documentation for the generated tools

### Security Audit Command

**`/security-audit`** - Perform comprehensive security audit of the project
- Invokes the security-auditor agent
- Analyzes application code for OWASP Top 10 vulnerabilities
- Audits dependencies for known CVEs
- Reviews configurations, authentication, APIs, and secrets
- Generates detailed reports in .audit/ directory (never committed)

### Repository Maintenance Commands

Commands for maintaining this Claude Code support tools repository:

**`/validate-agents`** - Validate all agent files
- Scans agents/ and .claude/agents/ directories
- Checks YAML frontmatter syntax and required fields
- Verifies kebab-case naming conventions
- Reports errors and suggests fixes

**`/validate-commands`** - Validate all command files
- Scans .claude/commands/ and commands/ directories
- Checks optional YAML frontmatter if present
- Verifies file naming and structure
- Reports errors and suggests fixes

**`/sync-docs`** - Synchronize documentation
- Detects new/modified agents and commands
- Updates README.md and CLAUDE.md
- Ensures consistency across documentation
- Validates cross-references

**`/test-workflows`** - Validate GitHub Actions workflows
- Checks YAML syntax in .github/workflows/
- Validates workflow structure and fields
- Verifies Claude Code Action usage
- Reviews security and best practices

**`/new-agent`** - Create new agent file
- Interactive scaffolding for new agents
- Generates proper YAML frontmatter
- Creates comprehensive agent prompt
- Validates created file
- Reminds to update documentation

**`/new-command`** - Create new command file
- Interactive scaffolding for new commands
- Generates clear step-by-step instructions
- Follows proper markdown structure
- Validates created file
- Reminds to update documentation

### Session Finalization Command

**`/finalize`** - Review all session changes and run quality actions
- Accepts parameter: `all`, `tests`, `translations`, `docs` (comma-separated)
- **tests**: Checks test coverage for modified files, adds/updates tests
- **translations**: Scans for new user-facing strings, adds missing translation keys
- **docs**: Updates README, API docs, inline docs, and config references
- Defaults to `all` if no parameter provided

### Release Command

**`/release-gh-prepare`** - Cut a new version with a GitHub draft release
- Optional argument: a version override like `0.12.0` or `v0.12.0`, validated against a semver regex before it reaches `git`/`gh`
- Hard preconditions: on the repository's default branch (resolved dynamically, not hardcoded), clean tree, in sync with `origin/<default-branch>`, `CHANGELOG.md` exists, at least one commit since the last tag, `gh` authenticated
- Drafts release notes from the commit history since the last tag (does NOT require a populated `[Unreleased]` section)
- Proposes the version via AskUserQuestion using semver (BREAKING → major, Added → minor, otherwise patch); infers the release title from the drafted notes
- **Mandatory approval gates**: the version/notes content, the commit, and the push each require explicit user approval
- Inserts a new `## [X.Y.Z] - YYYY-MM-DD` section in `CHANGELOG.md` and updates the compare links, leaving the `[Unreleased]` stub in place
- Commits, pushes to `origin/<default-branch>`, and creates a `gh release create --draft` targeting the commit SHA
- Does NOT publish the release or create the git tag — user does that from the GitHub UI

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
   - Writes the approved message to a temp file via the `Write` tool and commits with `git commit -F` to avoid shell interpolation
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

## Security Documentation

The repository includes comprehensive security documentation:

### SECURITY.md

Root-level security policy including:
- Vulnerability disclosure process via GitHub Security Advisories
- 48-hour response SLA for security reports
- Token rotation policy (90 days for OAuth tokens)
- Incident response procedures with escalation paths

### .github/THREAT_MODEL.md

Comprehensive threat model documenting:
- **Assets**: Primary (tokens, repo contents) and secondary assets
- **Threat Actors**: External attackers, malicious contributors, compromised dependencies
- **Attack Scenarios**: Expression injection, prompt injection, supply chain, log exposure
- **Trust Boundaries**: Visual diagram of nested trust levels
- **Implemented Controls**: Preventive, detective, and corrective controls
- **Residual Risks**: Accepted risks with rationale

### .github/SUPPLY_CHAIN_SECURITY.md

Supply chain security policy covering:
- GitHub Actions dependency inventory with pinned commit SHAs
- Verification process for adding new dependencies
- Pre-merge checklist for workflow changes
- Incident response for supply chain compromises
- Compliance alignment (NIST SSDF, SLSA Level 1)

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

The status line command validates `.workspace.current_dir` against terminal escape injection using a `jq` codepoint predicate (`explode | all(. >= 32 and . != 127 and (. < 128 or . > 159))`) that rejects C0 controls, DEL, and the full C1 range (U+0080–U+009F), and falls back to `unknown` on mismatch or non-existent paths. All git operations use `git -C "$safe_cwd"` so a malicious `cwd` cannot leak metadata from the calling process directory.

### global/tests/

Self-contained POSIX shell tests for the files in `global/`. Run with plain `sh` — no test framework, only `jq` and `git` required.

- **`statusline-cwd-test.sh`** - Regression coverage for the status line `cwd` validation: asserts that paths with shell metacharacters (`(`, `)`, `+`, `@`, `,`, spaces) and Unicode render normally, while control characters (raw ESC, JSON-escaped `\u001b`, CR, LF, TAB, DEL), missing paths, and empty input all fall back to `unknown` without echoing the attacker payload.

Run from the repository root:
```bash
sh global/tests/statusline-cwd-test.sh
```

### global/hooks/

Git hooks that protect against unsolicited automated commits:

**pre-commit hook:**
- Blocks automated commits in non-interactive mode (e.g., Claude Code committing on its own)
- Requires user to type "YES" (all caps) to approve commits in interactive terminal mode
- When the user explicitly requests a commit (e.g., `/commit-do`), Claude Code uses `--no-verify` — the user's request IS the approval

**Installation options:**
1. **Single repository**: Copy to `.git/hooks/pre-commit` in specific project
2. **Global (all new repos)**: Set `git config --global core.hooksPath ~/.git-hooks`
3. **All existing repos**: Use installation script (see `global/hooks/README.md`)

See `global/hooks/README.md` for detailed installation instructions and usage examples.

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
