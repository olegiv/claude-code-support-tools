# Security Policy

## Reporting Security Vulnerabilities

If you discover a security vulnerability in this repository, please report it responsibly:

1. **Do NOT create a public GitHub issue** for security vulnerabilities
2. Use [GitHub Security Advisories](https://github.com/olegiv/claude-code-support-tools/security/advisories/new) to report privately
3. Include detailed steps to reproduce the vulnerability
4. Allow reasonable time for fixes before public disclosure

We aim to respond to security reports within 48 hours and provide fixes within 7 days for critical issues.

## Security Measures

This repository implements the following security controls:

### GitHub Actions Security

- **Trusted User Restriction**: Only repository OWNER, MEMBER, and COLLABORATOR can trigger Claude workflows
- **Tool Restrictions**: Claude's capabilities are limited via `--allowed-tools` to prevent unauthorized actions
- **Pinned Actions**: All GitHub Actions are pinned to commit SHAs to prevent supply chain attacks
- **Concurrency Controls**: Prevents race conditions and abuse via concurrent workflow runs
- **Timeout Limits**: 15-minute maximum to prevent runaway workflows

### OAuth Token Security (GHA-003 Mitigation)

The `CLAUDE_CODE_OAUTH_TOKEN` secret is a long-lived OAuth token that requires manual rotation. Since the Claude Code Action does not currently support OIDC token exchange, we implement the following compensating controls:

#### Token Rotation Policy

**Required rotation schedule:**
- **Every 90 days** (maximum) under normal circumstances
- **Every 30 days** for high-security environments
- **Immediately** after any security incident or suspected compromise
- **Before** any team member with access leaves the organization

#### How to Rotate the Token

1. Generate a new OAuth token at [Claude Code Settings](https://console.anthropic.com/)
2. Update the `CLAUDE_CODE_OAUTH_TOKEN` secret in GitHub:
   - Go to Repository Settings > Secrets and variables > Actions
   - Update the `CLAUDE_CODE_OAUTH_TOKEN` secret with the new value
3. Revoke the old token in the Anthropic console
4. Document the rotation in your security log

#### Token Scope Requirements

The OAuth token should have **minimal required scopes** only:
- Repository read access (for code review)
- Issue/PR comment write access (for responses)

**Do NOT grant:**
- Repository write access (unless explicitly needed)
- Organization admin access
- Workflow modification access

#### Monitoring

- Review GitHub Actions workflow logs regularly for anomalies
- Monitor Claude API usage for unexpected patterns
- Set up alerts for failed authentication attempts

### Workflow Log Protection (SEC-002 Mitigation)

GitHub Actions workflows can accidentally expose secrets in logs. We implement the following protections:

#### Debug Mode Prevention

- Workflows abort if `RUNNER_DEBUG=1` is detected
- This prevents verbose logging that could expose secrets
- Debug mode should only be enabled for non-sensitive workflows

#### Secret Masking

GitHub automatically masks secrets in logs, but this can be bypassed. Our protections:

- **No direct shell interpolation**: Secrets passed via `with:` parameters, not `${{ }}` in shell commands
- **Environment variable isolation**: Secrets not exported to shell environment where possible
- **Tool restrictions**: AI agent cannot execute arbitrary commands that might dump env vars

#### What NOT to Do

If you fork or modify these workflows, avoid:

```yaml
# DANGEROUS - Secret may appear in logs
- run: echo "Token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}"

# DANGEROUS - Base64 encoding bypasses masking
- run: echo "${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}" | base64

# DANGEROUS - Error messages may contain secrets
- run: curl -H "Authorization: Bearer ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}" https://invalid-url
```

#### Safe Practices

```yaml
# SAFE - Secret passed via action input, not shell
- uses: anthropics/claude-code-action@sha
  with:
    claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
```

### Secret Management

- **Never commit secrets**: All secrets stored in GitHub Secrets
- **Local settings gitignored**: `.claude/settings.local.json` is never committed
- **Audit reports gitignored**: `.audit/` directory excluded from version control

## Security Audit

This repository undergoes regular security audits. See `.audit/README.md` for:
- Current security posture
- Open findings and remediation status
- Audit methodology and standards

**Last audit**: 2025-12-12
**Next scheduled audit**: 2026-01-12

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |
| < main  | :x:                |

Only the latest version on the `main` branch receives security updates.

## Security Contacts

For security-related questions or concerns:
- Open a [GitHub Discussion](https://github.com/olegiv/claude-code-support-tools/discussions) (non-sensitive)
- Use [Security Advisories](https://github.com/olegiv/claude-code-support-tools/security/advisories) (sensitive)
