# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.1.0]: https://github.com/olegiv/claude-code-support-tools/compare/v0.0.0...v0.1.0
[0.0.0]: https://github.com/olegiv/claude-code-support-tools/releases/tag/v0.0.0
