# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `global/skills/pr-fix/` — a shared skill for Claude Code and Codex
  (`/pr-fix <PR>` / `$pr-fix <PR>`) that repairs automated pull-request
  review findings in at most two fix pushes. One bash+jq runner,
  `scripts/pr-fix.sh`, exposes `collect` (paginated unresolved review
  threads with badge priority, round counter and pending detection),
  `triage` (FIX / REJECT / DEFER / DUP dispositions), `check`
  (deterministic checks recorded with exit codes), `review` (the local
  gate: `codex exec review --base` in an ephemeral read-only process with
  a working-tree fingerprint, review lock and per-round limit), `status`
  (`ready` / `needs-fix` / `incomplete` / `stale` /
  `escalation-required`), `close` (reply and resolve threads through
  GraphQL variables, batch mode) and `pre-push` (the gate body). State
  lives in `.audit/pr-<N>/` so both tools share counters. References
  cover the triage rules with the P2 rule (one-line fix or reply, never
  a rewrite), reply templates, the state schema, the developer
  instructions handed to the local reviewer, a `## Code Review Rules`
  block for a target repository's AGENTS.md, and a paragraph for
  `~/.codex/AGENTS.md`. Motivated by ocms-go PR 170, where five pushes
  produced 5 → 3 → 1 → 2 → 2 connector findings; a measured local review
  of its first commit caught 3 of the 5 findings of the pass it replaced
  in 105 seconds.
- `global/hooks/pre-push` — git pre-push wrapper that runs
  `pr-fix.sh pre-push`, armed only for branches with a `pr-fix` state.
  It refuses a push whose commit tree was not the one the local review
  saw, or that would exceed the two-push cap, records allowed pushes,
  fails open without gh/jq/runner, and chains to the repository's own
  pre-push hook that `core.hooksPath` would otherwise hide.
- `global/tests/pr-fix-test.sh` — 206 offline assertions for the runner
  and the hook using stub `gh`/`codex` binaries and fixtures under
  `global/tests/fixtures/pr-fix/`.
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

### Fixed

- `pr-fix` remote matching (#57): SSH host aliases are resolved with
  `ssh -G` before comparing hosts, the push gate uses the same host-aware
  match as the review (a same-named mirror on another host is neither
  gated nor counted), and `git config prf.baseRemote` names the pull
  request's remote explicitly.
- `pr-fix` follow-ups from PR #53's third review pass (#55): the local
  gate reviews against the fetched `origin/<base>` ref; `--dry-run`
  never runs `git add -N`; `record-push --undo` derives `pending` from
  the connector's latest reviewed commit; the push gate skips all-zero
  object names of any length (SHA-256 repositories) and matches the
  remote repository slug exactly; the hook wrapper compares file
  identity (`-ef`) so a symlinked copy of itself is never chained.

### Changed

- `global/CLAUDE.md` gains a `## MANDATORY: Tests Pass Before Commit and
  Push` section: run the project's full test suite before presenting any
  commit message and again before any push, stop on any failure, count a
  test that fails once as a failure even if a re-run passes, and never
  `git push --no-verify` unless the user explicitly asks for it.
- Go stack `commands/commit-prepare.md` runs the project's test gate as a
  mandatory Step 1 (the command the project's `CLAUDE.md` names, else
  `go test -count=1 ./...`, uncached) and drafts no message when a test
  fails.
- `global/CLAUDE.md` gains a `## PR Review Findings` section: use `pr-fix`,
  two fix pushes then triage-only, the P2 rule, defect-family mapping, no
  whole-repository audits during a findings fix, one push per round, close
  every thread.
- `.github/workflows/claude-code-review.yml` prompt now asks for
  high-confidence correctness/security problems in changed lines only,
  with `file:line` and a failing scenario, no style or speculative
  hardening, and no repetition of existing review comments.
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
- The `code-quality-auditor` agent is now **read-only**: `Edit` is removed from its
  tool list and it is barred from running `phpcbf`, `composer lint-fix*` or any other
  writing command. It shows the mechanical fixes with `phpcs --report=diff` and offers
  the command instead of applying it. Testing the previous revision showed why: asked
  to "clean up coding standards" in one module it rewrote all 11 files, because the
  guardrail permitted `phpcbf` with "an explicit path" while a neighbouring rule said
  only the files a change touches may be reformatted - a directory argument satisfied
  the first and violated the second. Whether to reformat a whole module is the user's
  call, so the agent now only ever proposes it.
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
