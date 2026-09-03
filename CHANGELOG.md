# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `global/commands/release-gh-prepare.md` — slash command
  (`/release-gh-prepare`) that cuts a new version of the host project:
  updates `CHANGELOG.md` (moves `[Unreleased]` → `[X.Y.Z] - DATE`, adds
  the compare link), commits, pushes to `origin/master`, and creates a
  GitHub draft release via `gh`. Hard preconditions on branch, clean
  tree, origin-sync, and CHANGELOG shape; mandatory user-approval gate
  on the proposed version before any edit or git operation. Auto-infers
  the version via semver from the `[Unreleased]` section
  (BREAKING → major, `### Added` → minor, otherwise patch) and the
  release title from the first bold bullet. Does not publish the
  release or create the git tag — those stay in the user's hands via
  the GitHub UI.

### Changed

- Drupal stack `commands/code-quality.md` and `agents/code-quality-auditor.md`
  now detect the project's PHPCS ruleset instead of hardcoding
  `--standard=Drupal,DrupalPractice --extensions=...`. Passing `--standard=`
  disables PHPCS's `phpcs.xml*` auto-discovery — `Config.php` guards the
  search on `overriddenDefaults['standards']` — which silently discarded the
  ruleset's `<arg value="sp"/>` (findings lost their sniff codes), its
  `<exclude-pattern>`s and its cache setting. A short preflight now prefers
  `composer lint*` or bare `./vendor/bin/phpcs` when a ruleset exists, and
  falls back to the explicit standard only when there is none.
- PHPCS is now treated the way PHPStan's baseline already was. PHPCS has no
  baseline mechanism, so both files declare **changed files**
  (`--filter=GitModified`) the gate and report the tree-wide total as
  pre-existing debt excluded from the actionable count. The auditor agent,
  which holds `Edit`, is scoped to the files a change already touches, is
  forbidden from running `phpcbf`/`composer lint-fix` unscoped, and must keep
  any reformatting in a commit separate from the behavioural change.
  `--filter=` is mandatory rather than preferred because it is fail-closed,
  whereas `phpcbf $(git diff --name-only ...)` is fail-open: an empty
  substitution leaves phpcbf with no path and it reformats the whole tree.
- Scope resolution no longer hardcodes `modules/custom`. A named argument
  resolves against `modules/custom/` then `themes/custom/`, and an unscoped
  run passes no path so each tool uses its own config — explicitly *not*
  unified, because `phpstan-baseline.neon` is generated against
  `phpstan.neon` `paths:` only.

### Fixed

- Status line `cwd` validation in `global/settings.json` no longer rejects
  legitimate paths containing `(`, `)`, `+`, `@`, `,`, spaces, or Unicode.
  PR #24 introduced an overly narrow allowlist regex
  (`^[[:alnum:]_./~ -]+$`) that caused such paths to fall back to `unknown`
  and lose the git branch/status indicators. Replaced with a control-character
  denylist (`tr -d '[:cntrl:]'`) that preserves the anti-injection hardening
  while accepting all real-world filesystem paths. Resolves the regression
  flagged in PR #24 review.

### Added

- `global/tests/statusline-cwd-test.sh` — POSIX shell regression suite for
  the status line `cwd` validation. 16 assertions covering shell
  metacharacters, Unicode paths, raw and JSON-escaped ANSI/control-character
  injection attempts, missing paths, and empty input.

## [0.2.0] - 2026-02-11

### Added

#### Kotlin/Android Stack
- Kotlin/Android stack with 3 agents (android-quality-auditor,
  kotlin-refactorer, compose-developer), 5 commands (code-quality,
  lint, detekt, clean, test-instrumented), and Detekt template
- UnusedImports rule for Detekt configuration
- Backtick-quoted function name check for Android tests
- Check for assertions duplicating while loop conditions

#### Swift/Xcode Stack
- Swift/Xcode stack with simulator validation hook (iPhone 17 Pro),
  iOS quality auditor agent, and code-quality command

#### PHP Stack
- PHP stack with 3 agents (composer-manager, security-reviewer,
  php-refactorer), 3 commands (phpstan, update-deps, security-scan),
  2 hooks (validate-php-syntax, validate-composer-lock), and
  security-review skill

#### Drupal Stack
- Drupal stack with 7 agents, 23 commands, 2 hooks, 8 skills,
  and 2 templates (phpunit.xml.dist, phpstan.neon)

#### Go Stack Enhancements
- Nilaway nil safety analysis to code quality checks
- Dupl duplicate code detection (mandatory in auditor agent)
- Duplicate string literal detection
- Redundant COALESCE detection
- Resource leak detection
- Unused type parameter check
- Toolchain and test validation hooks
- Fly.io deployment command with Docker prerequisite check
- gopls LSP plugin support
- Optional code quality parameter in commit-prepare
- golangci-lint migration for code-quality tooling

#### Global Configuration
- Pre-commit hook to block unsolicited automated commits
- Chrome extension testing rules
- Context window usage indicator in status line
- Update-submodule command for shared tools

### Changed

- Rename `lang/` directory to `stacks/` for broader scope
- Change license from MIT to GNU GPL v3
- Improve commit approval workflow documentation
- Bump anthropics/claude-code-action from 1.0.27 to 1.0.46
- Bump actions/checkout from 6.0.1 to 6.0.2

### Fixed

- Fix Go toolchain validation and remove spinnerVerbs
- Fix drush hook substring matching and PostgreSQL-only SQL handling
- Fix SQL injection and command injection in Drupal commands and
  security audit
- Harden input validation across all stacks (jq migration, expanded
  metacharacter blocklists)
- Replace hardcoded absolute paths with relative paths

## [0.1.0] - 2025-12-22

### Added

- Go code quality tools for Claude Code global config
- File permission rules to global config
- QA and package installation rules to global config

### Changed

- Bump anthropics/claude-code-action from 1.0.23 to 1.0.27

## [0.0.0] - 2025-12-12

### Added

#### Core Agents
- Security auditor agent for comprehensive vulnerability analysis
- Project architect agent for analyzing projects and generating Claude Code extensions

#### Repository Maintenance Agents
- Markdown linter agent for validating agent and command files
- Doc sync manager agent for synchronizing documentation
- Template validator agent for ensuring best practices
- Release manager agent for versioning and changelog generation

#### Slash Commands
- `/setup-project-tools` - Analyze project and generate tailored extensions
- `/security-audit` - Perform comprehensive security audit
- `/validate-agents` - Validate all agent files
- `/validate-commands` - Validate all command files
- `/sync-docs` - Synchronize documentation
- `/test-workflows` - Validate GitHub Actions workflows
- `/new-agent` - Scaffold new agent files
- `/new-command` - Scaffold new command files
- `/commit-prepare` - Review and prepare commit messages
- `/commit-do` - Create commits with prepared messages

#### Global Configuration
- Global CLAUDE.md with strict git workflow rules
- Global settings.json with custom status line and alwaysThinking mode
- macOS/BSD command compatibility rules

#### GitHub Actions Integration
- Claude PR Assistant workflow for @claude mentions
- Claude Code Review workflow for automated PR reviews
- Dependabot configuration for GitHub Actions

#### Security
- SECURITY.md with vulnerability disclosure policy
- Threat model documentation
- Supply chain security policy
- Pre-commit secret scanning configuration
- Debug mode protection against secret exposure
- Security-sensitive gitignore patterns
- Secret access audit logging
- Hardened GitHub Actions against prompt injection
- Pinned GitHub Actions to commit SHAs

[0.2.0]: https://github.com/olegiv/claude-code-support-tools/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/olegiv/claude-code-support-tools/compare/v0.0.0...v0.1.0
[0.0.0]: https://github.com/olegiv/claude-code-support-tools/releases/tag/v0.0.0
