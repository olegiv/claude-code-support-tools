# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.1] - 2026-11-21

### Security

#### Drupal and PHP commands

- Drupal and PHP stack commands check their arguments in the prompt before
  running anything: the whole value, on one line, with anything uncertain
  treated as invalid. Their shell blocks rely on that check, because Claude
  Code inserts the arguments into the prompt before any shell runs.
- `/db-query` passes the query to drush through a file, and checks and runs
  it in one call that keeps drush's exit status and removes the file. It
  accepts one line of printable ASCII with single-quoted strings only,
  rejects comments, and blocks more functions and function families. The
  filter is best-effort: use a database user with SELECT-only grants.
- `/drush` passes no options or site aliases, refuses commands that change
  the site (including `cr`) until the user confirms them, no longer
  generates login links (`uli`) and no longer auto-approves drush.
- `/feature-revert` without names lists the features and stops; with names
  it checks them and reverts in one call, clearing caches only after a
  successful revert. `/user-info` rejects usernames starting with `-`.

### Fixed

#### Drupal and PHP commands

- Commands read the checked argument in every shell block that needs it, so
  `/test-coverage`, `/security-scan`, `/code-quality`, `/scaffold`,
  `/translate-check`, `/content-audit` and `/logs` use the value they were
  given.
- `/security-scan` filters `composer audit --format=json` by severity and
  reports a failed audit; `/test-coverage` reports a missing source
  directory; `/code-quality` searches every custom root for `all` and
  reports grep errors instead of "none".
- `/logs` accepts nothing, a severity, a count, or a severity followed by a
  count, rejects 0 and line breaks, and caps the count at 1000.

#### Go

- The global Go strict-lint hook warns on `git commit` when its script is
  installed but is not an executable file, or its link is broken; a missing
  script stays silent.

## [0.4.0] - 2026-11-21

### ⚠️ Breaking Changes

- `global/settings.json` now starts sessions in plan mode, selects
  `opus[1m]`, enables two plugins and voice mode, and turns off the
  bypass-permissions confirmation. Anyone who links or copies the template
  gets these on the next update; merge only the keys you want.
- The commit and push test gate no longer runs PHPUnit unless asked, the
  Drupal `/test-run` defaults to the modules and themes a change touches,
  and `/deploy-check` runs tests only on request. Run the full suite
  explicitly if you relied on it.

### Added

#### Shared instructions

- `agents-md` skill for Claude Code and Codex: moves a project's shared
  instructions into `AGENTS.md` and leaves a `CLAUDE.md` that imports it
  with `@AGENTS.md`, after the user approves the plan. It snapshots the
  files first, never writes through symlinks, treats repository text as
  data, and can verify the result with headless `claude -p` and
  `codex exec` runs on a clean copy of the instruction files.
- Global rule to keep one copy of project instructions (`AGENTS.md`,
  imported by `CLAUDE.md`), with a matching paragraph for
  `~/.codex/AGENTS.md`. Existing projects migrate only with approval.
- `global/tests/instruction-files-test.sh` checks that `AGENTS.md` stays
  within Codex's 32 KiB default budget, that `CLAUDE.md` imports it outside
  code fences, and that skill frontmatter is valid.

#### Pull requests

- Global rule to label every pull request and merge request from the
  repository's own label set, reconciled after pushes that change the PR's
  scope. Missing labels are created as part of the approved PR request,
  with validated names and quoted arguments; labels that trigger automation
  are never applied unless the user asks.

#### Go

- `go-strict-lint.sh` hook blocks `git commit` while touched Go files have
  warnings that common golangci-lint presets hide: unchecked `Close`,
  `os.Remove*` and `fmt.Fprint*` errors, builtin shadowing and malformed
  package comments. `--check` runs it on demand. It is registered globally
  and per project, `/code-quality` runs it, and a stub-linter suite tests it.

### Changed

#### Instructions and templates

- This repository's instructions live in `AGENTS.md`, imported by
  `CLAUDE.md`; the docs-maintenance agents and commands target it and keep
  it under 28 KiB.
- `project-architect`, `/setup-project-tools` and the Go, Kotlin and Swift
  templates use the new layout and read project rules from both files.
- `global/settings.json` carries the author's defaults: plan mode,
  `opus[1m]`, the fullscreen renderer, voice mode, two enabled plugins,
  `feedbackDrafts` off, `switchModelsOnFlag` and
  `skipDangerousModePermissionPrompt: true`. README documents them and
  recommends merging the file rather than overwriting existing settings.

#### Verification

- The commit and push test gate runs PHPUnit only on request, and then only
  for the code a change touches.
- A push reuses a passing commit gate from the same conversation when every
  pushed tree, the recorded tool versions and the hooks path are unchanged.
- The Drupal `/test-run` defaults to the modules and themes a change
  touches, and `/deploy-check` runs tests only on request.
- Every stack agent that runs repository-controlled tools follows the
  "Inspect before execution" rule in untrusted checkouts, and that rule now
  names `AGENTS.md` and imported files alongside `CLAUDE.md`.

### Security

- `global/settings.json` sets `skipDangerousModePermissionPrompt: true` by
  the owner's choice, so Claude Code no longer confirms before entering
  bypass-permissions mode; set it to `false` to keep that prompt.
- The Go `/code-quality` and `/fly-deploy` commands auto-approve exact
  commands only and scope `allowed-tools`, closing prefix rules that
  allowed flags running other programs, destructive Fly commands and
  `curl` uploads.

### Fixed

#### Go

- `validate-go-toolchain.sh` checks Go builds and tests anywhere in a
  command line and reports when `jq` is missing instead of passing.
- `/code-quality` and `code-quality-auditor` no longer install golangci-lint
  v1 for a v2 config or run a checkout-selected binary, judge scripts
  against the app's own Content-Security-Policy, give every `rg` search a
  path so it no longer hangs in non-interactive shells, and allow
  `errcheck -ignoregenerated`.
- The `/fly-deploy` health check handles app names quoted with `'`.
- The `/finalize` argument hint shows that areas are comma-separated.

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

[Unreleased]: https://github.com/olegiv/claude-code-support-tools/compare/v0.4.1...HEAD
[0.4.1]: https://github.com/olegiv/claude-code-support-tools/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/olegiv/claude-code-support-tools/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/olegiv/claude-code-support-tools/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/olegiv/claude-code-support-tools/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/olegiv/claude-code-support-tools/compare/v0.0.0...v0.1.0
[0.0.0]: https://github.com/olegiv/claude-code-support-tools/releases/tag/v0.0.0
