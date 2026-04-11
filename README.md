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

**Project Architect** (`agents/project-architect.md`)
- Elite Software Architect that analyzes any project's tech stack
- Automatically detects languages, frameworks, build tools, testing infrastructure
- Generates custom Claude Code agents, skills, and commands tailored to the project
- Creates workflow-specific extensions (test-runner, build-manager, linter-helper, etc.)
- **Updates existing documentation** (CLAUDE.md, README.md) to document new tools
- Use when setting up Claude Code for a new project or after major tech stack changes

**Repository Maintenance Agents** (`.claude/agents/`)
- **markdown-linter** - Validates agent and command files for proper YAML frontmatter and structure
- **doc-sync-manager** - Synchronizes documentation across README.md and CLAUDE.md
- **template-validator** - Ensures templates follow Claude Code best practices
- **release-manager** - Manages versioning, changelog generation, and releases

### ⚡ Slash Commands

**Project Setup Command**
- `/setup-project-tools` - Automatically analyze project and generate tailored agents, skills, and commands

**Security Audit Command**
- `/security-audit` - Perform comprehensive security audit of the project (invokes security-auditor agent)

**Repository Maintenance Commands**
- `/validate-agents` - Validate all agent files for proper structure and syntax
- `/validate-commands` - Validate all command files for proper structure and syntax
- `/sync-docs` - Synchronize documentation after adding/modifying agents or commands
- `/test-workflows` - Validate GitHub Actions workflow syntax and best practices
- `/new-agent` - Scaffold a new agent file with proper template
- `/new-command` - Scaffold a new command file with proper template

**Session Finalization Command**
- `/finalize` - Review session changes and run quality actions (tests, translations, docs)

**Commit Workflow Commands**
- `/commit-prepare` - Review changes and draft commit messages following best practices
- `/commit-do` - Create commits with proper formatting using a safe temp-file + `git commit -F` flow

Both commit commands enforce strict commit message standards:
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

**`global/commands/`** - Global slash command templates
- `finalize.md` - Review session changes and run quality actions (tests, translations, docs)

**`global/hooks/`** - Git hooks for commit protection
- `pre-commit` - Prevents Claude Code from committing without explicit user approval
- Blocks all automated commits in non-interactive mode
- Requires typing "YES" to approve commits in interactive mode
- Can be installed per-repo, globally, or across all existing repos
- See `global/hooks/README.md` for installation instructions

### 🔄 GitHub Actions Workflows

**Automated PR Reviews** (`.github/workflows/claude-code-review.yml`)
- Runs on PR open/synchronize events
- Reviews code quality, security, performance, and test coverage
- Posts feedback as PR comments

**@claude Mention Response** (`.github/workflows/claude.yml`)
- Triggers when `@claude` is mentioned in issues or PRs
- Responds to requests with full repository access
- Supports issue comments, PR reviews, and new issues

### 🛠️ Stack-Specific Configurations

Located in `stacks/` directory - copy these to your project's `.claude/` directory:

**Go** (`stacks/go/`)
- Pre-configured hooks, agents, and commands for Go development
- `validate-go-toolchain.sh` - Blocks builds when Go version mismatches compiler
- `validate-go-test.sh` - Recommends race detection for test commands
- `code-quality-auditor` agent - Comprehensive code quality scanning
- `/code-quality`, `/commit-prepare`, and `/fly-deploy` commands

**Swift/Xcode** (`stacks/swift/`)
- Pre-configured hooks for Xcode project development
- `validate-xcodebuild.sh` - Ensures xcodebuild commands use correct simulator (iPhone 17 Pro)
- Prevents build failures from incorrect simulator targets

**Kotlin/Android** (`stacks/kotlin/`)
- Pre-configured agents and commands for Android/Kotlin development
- `android-quality-auditor` agent - Comprehensive Android code quality scanning (SDK, Gradle, dependencies, lint, Compose)
- `kotlin-refactorer` agent - Kotlin refactoring and best practices
- `compose-developer` agent - Jetpack Compose UI development
- `/code-quality`, `/lint`, `/detekt`, `/clean`, `/test-instrumented` commands
- `templates/detekt.yml` - Ready-to-use Detekt configuration for Android/Compose projects

**PHP** (`stacks/php/`)
- Pre-configured agents, commands, and hooks for PHP development
- `composer-manager` agent - Dependency management with Composer
- `security-reviewer` agent - PHP security scanning and code review
- `php-refactorer` agent - PHP refactoring and modern best practices
- `/phpstan`, `/update-deps`, `/security-scan` commands
- `skills/security-review` - Security review skill for PHP projects
- `hooks/validate-php-syntax.sh` - Validates PHP syntax before execution
- `hooks/validate-composer-lock.sh` - Ensures composer.lock stays in sync

**Drupal** (`stacks/drupal/`)
- Pre-configured agents, commands, skills, hooks, and templates for Drupal development
- `drupal-debugger` agent - Debug errors, test failures, configuration issues
- `drush-helper` agent - Drush commands and system administration
- `config-reviewer` agent - Configuration safety and deployment readiness
- `performance-tuner` agent - Redis, caching, database optimization
- `test-creator` agent - Generate PHPUnit tests for modules
- `api-developer` agent - REST/JSON:API development, external integrations
- `migration-expert` agent - Content migrations, CRM sync, data transformations
- 23 commands: `/backup-db`, `/cache-clear`, `/config-diff`, `/config-export`, `/config-import`, `/content-audit`, `/cron-status`, `/db-query`, `/db-update`, `/deploy-check`, `/drush`, `/feature-revert`, `/health-check`, `/logs`, `/maintenance`, `/module-status`, `/queue-status`, `/scaffold`, `/test-coverage`, `/test-create`, `/test-run`, `/translate-check`, `/user-info`
- 8 skills: api-development, config-management, database-operations, drupal-drush, drupal-hooks, drupal-migrations, drupal-testing, performance-optimization
- `hooks/validate-drush.sh` - Validates drush command execution context
- `hooks/validate-drupal-root.sh` - Ensures commands run from Drupal root
- `templates/phpunit.xml.dist` - Standard PHPUnit configuration for custom module testing
- `templates/phpstan.neon` - Base PHPStan configuration for Drupal projects

### 🔒 Security Documentation

**Security Policy** ([SECURITY.md](SECURITY.md))
- Vulnerability disclosure via GitHub Security Advisories
- 48-hour response SLA for security reports
- Token rotation policy (90 days for OAuth tokens)
- Incident response procedures

**Threat Model** ([.github/THREAT_MODEL.md](.github/THREAT_MODEL.md))
- Attack scenarios (expression injection, prompt injection, supply chain)
- Trust boundaries and security assumptions
- Implemented controls (preventive, detective, corrective)
- Residual risks and user recommendations

**Supply Chain Security** ([.github/SUPPLY_CHAIN_SECURITY.md](.github/SUPPLY_CHAIN_SECURITY.md))
- GitHub Actions dependency inventory with pinned SHAs
- Verification process for adding new dependencies
- Incident response for supply chain compromises

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
# Project setup command
cp commands/setup-project-tools.md /path/to/your/project/.claude/commands/

# Commit workflow commands
cp .claude/commands/commit-prepare.md /path/to/your/project/.claude/commands/
cp .claude/commands/commit-do.md /path/to/your/project/.claude/commands/
```

Then use in Claude Code:
```bash
/setup-project-tools
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

### Using Global Commands

Copy global command templates to your `~/.claude/commands/` directory:

```bash
mkdir -p ~/.claude/commands
cp global/commands/finalize.md ~/.claude/commands/
```

These commands will be available as slash commands in all Claude Code sessions.

### Using Git Hooks

Install the pre-commit hook to prevent Claude Code from committing without your approval:

```bash
# Option 1: Install to current repository only
cp global/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Option 2: Install globally for all future repositories
mkdir -p ~/.git-hooks
cp global/hooks/pre-commit ~/.git-hooks/pre-commit
chmod +x ~/.git-hooks/pre-commit
git config --global core.hooksPath ~/.git-hooks
```

See `global/hooks/README.md` for detailed installation instructions and additional options.

### Using Stack-Specific Configurations

Copy stack-specific tools to your project:

```bash
# For Go projects
cp stacks/go/settings.json /path/to/your/project/.claude/
mkdir -p /path/to/your/project/.claude/hooks
cp stacks/go/hooks/*.sh /path/to/your/project/.claude/hooks/
chmod +x /path/to/your/project/.claude/hooks/*.sh
# Optional: Copy agents and commands
cp -r stacks/go/agents /path/to/your/project/.claude/
cp -r stacks/go/commands /path/to/your/project/.claude/

# For Swift/Xcode projects
cp stacks/swift/settings.json /path/to/your/project/.claude/
mkdir -p /path/to/your/project/.claude/hooks
cp stacks/swift/hooks/validate-xcodebuild.sh /path/to/your/project/.claude/hooks/
chmod +x /path/to/your/project/.claude/hooks/validate-xcodebuild.sh

# For Kotlin/Android projects
cp -r stacks/kotlin/agents /path/to/your/project/.claude/
cp -r stacks/kotlin/commands /path/to/your/project/.claude/

# For PHP projects
cp stacks/php/settings.json /path/to/your/project/.claude/
mkdir -p /path/to/your/project/.claude/hooks
cp stacks/php/hooks/*.sh /path/to/your/project/.claude/hooks/
chmod +x /path/to/your/project/.claude/hooks/*.sh
# Optional: Copy agents, commands, and skills
cp -r stacks/php/agents /path/to/your/project/.claude/
cp -r stacks/php/commands /path/to/your/project/.claude/
cp -r stacks/php/skills /path/to/your/project/.claude/

# For Drupal projects
cp stacks/drupal/settings.json /path/to/your/project/.claude/
mkdir -p /path/to/your/project/.claude/hooks
cp stacks/drupal/hooks/*.sh /path/to/your/project/.claude/hooks/
chmod +x /path/to/your/project/.claude/hooks/*.sh
# Optional: Copy agents, commands, skills, and templates
cp -r stacks/drupal/agents /path/to/your/project/.claude/
cp -r stacks/drupal/commands /path/to/your/project/.claude/
cp -r stacks/drupal/skills /path/to/your/project/.claude/
cp -r stacks/drupal/templates /path/to/your/project/.claude/
```

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

> **Security Note**: These workflows include security hardening (pinned actions,
> tool restrictions, trusted user checks). Before deploying, review
> [SECURITY.md](SECURITY.md) for token rotation requirements and best practices.

## Usage Examples

### Project Setup

```bash
# In Claude Code - Option 1: Use slash command
/setup-project-tools

# Option 2: Invoke agent directly
Use the project-architect agent to analyze this project and generate
tailored Claude Code extensions for my tech stack.
```

The agent will:
1. Analyze your project (languages, frameworks, build tools, testing, etc.)
2. Generate custom agents in `.claude/agents/` (e.g., test-runner, build-manager)
3. Generate slash commands in `.claude/commands/` (e.g., /test, /build, /lint)
4. Create skills in `.claude/skills/` if needed
5. **Update existing documentation** (CLAUDE.md, README.md, etc.) with new tools
6. Provide quick start guide for using the generated extensions

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
├── agents/                        # Autonomous agent definitions
│   ├── security-auditor.md       # Security vulnerability scanning
│   └── project-architect.md      # Project analysis & tool generation
├── .claude/
│   ├── agents/                    # Repository-specific agents
│   │   ├── markdown-linter.md    # Validate agent/command files
│   │   ├── doc-sync-manager.md   # Synchronize documentation
│   │   ├── template-validator.md # Validate template quality
│   │   └── release-manager.md    # Manage releases and versioning
│   └── commands/                  # Repository-specific slash commands
│       ├── commit-prepare.md     # Review changes
│       ├── commit-do.md          # Create commits
│       ├── finalize.md           # Session finalization
│       ├── security-audit.md     # Security audit command
│       ├── validate-agents.md    # Validate agent files
│       ├── validate-commands.md  # Validate command files
│       ├── sync-docs.md          # Update documentation
│       ├── test-workflows.md     # Validate workflows
│       ├── new-agent.md          # Scaffold new agent
│       └── new-command.md        # Scaffold new command
├── commands/                      # Template commands for copying to projects
│   ├── setup-project-tools.md
│   └── no-ticket/                 # Alternative command structures
├── stacks/                        # Stack-specific configurations
│   ├── go/                        # Go project tools
│   │   ├── settings.json          # Hook configuration for Go commands
│   │   ├── hooks/
│   │   │   ├── validate-go-toolchain.sh  # Toolchain version validation
│   │   │   └── validate-go-test.sh       # Test command recommendations
│   │   ├── agents/
│   │   │   └── code-quality-auditor.md   # Code quality scanning agent
│   │   └── commands/
│   │       ├── code-quality.md    # Run quality checks
│   │       ├── commit-prepare.md  # Commit with quality integration
│   │       └── fly-deploy.md      # Deploy Go app to Fly.io
│   ├── swift/                     # Swift/Xcode project tools
│   │   ├── settings.json          # Hook configuration for xcodebuild
│   │   └── hooks/
│   │       └── validate-xcodebuild.sh  # Simulator validation hook
│   ├── kotlin/                    # Kotlin/Android project tools
│   │   ├── agents/
│   │   │   ├── android-quality-auditor.md  # Android code quality auditor
│   │   │   ├── kotlin-refactorer.md        # Kotlin refactoring agent
│   │   │   └── compose-developer.md        # Jetpack Compose development
│   │   ├── commands/
│   │   │   ├── code-quality.md    # Run quality checks
│   │   │   ├── lint.md            # Run Android Lint
│   │   │   ├── detekt.md          # Run Detekt static analysis
│   │   │   ├── clean.md           # Clean build artifacts
│   │   │   └── test-instrumented.md  # Run instrumented tests
│   │   └── templates/
│   │       └── detekt.yml         # Detekt config for Android/Compose
│   ├── php/                       # PHP project tools
│   │   ├── settings.json          # Hook configuration for PHP commands
│   │   ├── hooks/
│   │   │   ├── validate-php-syntax.sh     # PHP syntax validation
│   │   │   └── validate-composer-lock.sh  # Composer lock sync check
│   │   ├── agents/
│   │   │   ├── composer-manager.md        # Composer dependency management
│   │   │   ├── security-reviewer.md       # PHP security scanning
│   │   │   └── php-refactorer.md          # PHP refactoring agent
│   │   ├── commands/
│   │   │   ├── phpstan.md         # Run PHPStan static analysis
│   │   │   ├── update-deps.md     # Update Composer dependencies
│   │   │   └── security-scan.md   # PHP security scanning
│   │   └── skills/
│   │       └── security-review/   # PHP security review skill
│   │           └── SKILL.md
│   └── drupal/                    # Drupal project tools
│       ├── settings.json          # Hook configuration for Drupal commands
│       ├── hooks/
│       │   ├── validate-drush.sh          # Drush command validation
│       │   └── validate-drupal-root.sh    # Drupal root directory check
│       ├── agents/
│       │   ├── drupal-debugger.md         # Debug errors and config issues
│       │   ├── drush-helper.md            # Drush commands and sysadmin
│       │   ├── config-reviewer.md         # Configuration safety review
│       │   ├── performance-tuner.md       # Redis, caching, DB optimization
│       │   ├── test-creator.md            # PHPUnit test generation
│       │   ├── api-developer.md           # REST/JSON:API development
│       │   └── migration-expert.md        # Content migrations and data sync
│       ├── commands/
│       │   ├── cache-clear.md     # Clear all caches
│       │   ├── config-diff.md     # Config differences
│       │   ├── config-export.md   # Export Drupal configuration
│       │   ├── config-import.md   # Import Drupal configuration
│       │   ├── backup-db.md       # Create database backup
│       │   ├── db-query.md        # Safe SELECT queries
│       │   ├── db-update.md       # Run database updates
│       │   ├── drush.md           # Execute drush command
│       │   ├── feature-revert.md  # Revert feature configuration
│       │   ├── health-check.md    # Site health check
│       │   ├── logs.md            # View watchdog logs
│       │   ├── module-status.md   # Module status information
│       │   └── test-run.md        # Run PHPUnit tests
│       ├── skills/
│       │   ├── api-development/   # REST/JSON:API skill
│       │   ├── config-management/ # Features workflow and config splits
│       │   ├── database-operations/ # PostgreSQL backup/restore
│       │   ├── drupal-drush/      # Comprehensive Drush reference
│       │   ├── drupal-hooks/      # Hook and event subscriber patterns
│       │   ├── drupal-migrations/ # Migration YAMLs and plugins
│       │   ├── drupal-testing/    # PHPUnit tests and mocking
│       │   └── performance-optimization/ # Redis, caching, tuning
│       └── templates/
│           ├── phpunit.xml.dist   # PHPUnit config for custom modules
│           └── phpstan.neon       # PHPStan config for Drupal projects
├── global/                        # User-level configuration templates
│   ├── CLAUDE.md
│   ├── settings.json
│   ├── commands/                  # Global slash command templates
│   │   └── finalize.md            # Session finalization command
│   └── hooks/                     # Git hooks for commit protection
│       ├── README.md              # Installation instructions
│       └── pre-commit             # Prevents automated commits
├── .github/
│   ├── workflows/                 # GitHub Actions workflows
│   │   ├── claude.yml
│   │   └── claude-code-review.yml
│   ├── THREAT_MODEL.md            # Security threat model
│   └── SUPPLY_CHAIN_SECURITY.md   # Supply chain security policy
└── SECURITY.md                    # Vulnerability disclosure policy
```

## Dependencies

This repository has no runtime dependencies. It consists entirely of:
- Markdown documentation and agent definition files
- YAML configuration files for GitHub Actions
- JSON configuration files

If dependencies are added in the future, they must:
- Use lockfiles (package-lock.json, go.sum, etc.)
- Be scanned for vulnerabilities with Dependabot
- Follow semantic versioning
- Have versions pinned in production

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

Copyright (C) 2025-2026 Oleg Ivanchenko

GNU General Public License v3.0 - see [LICENSE](LICENSE) file for details.
