# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-10-04

### Added

#### Shared workflows

- Shared `pr-fix` skill for Claude Code and Codex, with review-thread triage,
  focused repairs, local Codex diff review, and a two-push repair policy.
  An optional pre-push hook checks recorded readiness, the reviewed tree,
  base freshness, and push count for branches with active skill state.
- `/release-gh-prepare` creates curated GitHub draft releases from the
  default branch, with explicit version, content, commit, and push approvals.
- `/finalize` coordinates tests, translations, and documentation updates.
- Drupal 11 / PHP 8.4 `/code-quality` command and read-only auditor for
  PHPStan, PHPCS, dependency advisories, and deprecated APIs.

### Changed

#### Verification and quality guidance

- Require fresh full-suite results tied to the intended Git tree before
  commits and pushes, preserve review inputs, and guard commit hooks that
  may change the index. Go preparation requires uncached tests and complete
  module/workspace coverage.
- Require direct behavior evidence, including failure and normal cases and
  affected consumers, before publication. Untrusted PR commands require
  authorization and verified isolation. These are workflow requirements;
  the `pr-fix` runner does not provide a sandbox or assess evidence quality.
- Honor project PHPCS rulesets and analyzer scopes, separate changed-file
  findings from existing debt, and preview Drupal coding-standard fixes.
- Expand Go quality guidance with error-handling, test-helper, import-order,
  CSS, JSON-schema, CSP, and DOM-XSS checks.
- Focus automated Claude PR reviews on concrete correctness/security issues
  in changed lines, without repeating existing findings.
- Respect plan mode's prohibition on edits and commits, and clear Chrome's
  cache before visual verification.

### Fixed

#### Tooling

- Match `pr-fix` remotes by host and repository, fetch the correct PR base,
  and handle SSH aliases, narrow fetch refspecs, mirror remotes, Git boolean
  values, SHA-256 deletion refs, and symlinked hooks. `prf.baseRemote`
  selects a remote explicitly; `prf.sshResolve=false` disables SSH resolution.
- Correct `govulncheck` guidance, restore the previous `go.mod`/`go.sum`
  state when backing out dependencies, and handle toolchain paths with spaces.
- Repair command frontmatter, tool permissions, and Fly.io health checks
  (AGT-017–018, AGT-020).

### Security

#### Commands and automation

- Block terminal-control injection in status-line paths while preserving
  Unicode and punctuation; includes a 22-assertion regression suite.
- Write approved commit messages to unique temporary files, handle failures
  and cleanup, and stage only intended paths. Validate release versions,
  sanitize titles, use unique release-notes files, retain notes for retries,
  require tag/release approval, and preserve required commit hooks
  (AGT-006–008, AGT-011, AGT-015).
- Validate each `@claude` event's own actor association; includes 13
  structural regression assertions (GHA-NEW-001).
- Correct shell and SQL validation, reject absolute paths in Drupal/PHP
  commands, and block executable SQL comments. Reject arbitrary SQL/PHP
  execution and automatic-confirmation flags in the generic Drush wrapper
  (AGT-001–005, AGT-009–010).
- Preserve dangerous-mode confirmation by default, pass Go-check filenames
  safely to Python, and quote iOS auditor command placeholders.
- Monitor `OAUTH_TOKEN_ROTATED_AT`: warn after 75 days, fail after 90 days,
  and reject invalid or future dates. Remove unused usage-report write
  permission (SEC-NEW-001, GHA-NEW-002).
- Update SHA-pinned GitHub Actions to `actions/checkout` 7.0.1 and
  `anthropics/claude-code-action` 1.0.235.

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

[Unreleased]: https://github.com/olegiv/claude-code-support-tools/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/olegiv/claude-code-support-tools/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/olegiv/claude-code-support-tools/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/olegiv/claude-code-support-tools/compare/v0.0.0...v0.1.0
[0.0.0]: https://github.com/olegiv/claude-code-support-tools/releases/tag/v0.0.0
