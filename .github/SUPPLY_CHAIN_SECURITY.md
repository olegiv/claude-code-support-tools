# Supply Chain Security Policy

**Last Updated**: 2025-12-12
**Repository**: claude-code-support-tools

## Overview

This document defines the supply chain security controls for this repository. As a documentation and configuration-only project with no runtime dependencies, the primary supply chain risk comes from GitHub Actions.

## Dependency Inventory

### GitHub Actions Dependencies

| Action | Version | Commit SHA | Source | Verified |
|--------|---------|------------|--------|----------|
| actions/checkout | v4 | `8e8c483db84b4bee98b60c0593521ed34d9990e8` | GitHub Official | Yes |
| anthropics/claude-code-action | v1 | `f0c8eb29807907de7f5412d04afceb5e24817127` | Anthropic Official | Yes |

### Runtime Dependencies

**None** - This repository contains only markdown documentation and YAML configuration files.

## Security Controls

### Implemented Controls

| Control | Status | Details |
|---------|--------|---------|
| SHA Pinning | ✅ Implemented | All GitHub Actions pinned to full commit SHA |
| Dependabot | ✅ Enabled | Monitors GitHub Actions for updates |
| Vendor Verification | ✅ Completed | Anthropic action reviewed (open source, MIT) |
| Permission Restrictions | ✅ Implemented | `--allowed-tools` limits AI agent capabilities |
| Security Policy | ✅ Present | SECURITY.md with incident response |

### Acceptance of Residual Risk

The following risks are accepted given the repository's scope:

- **No SLSA attestations**: GitHub Actions don't provide signed provenance
- **No formal SBOM**: Not applicable for documentation-only repository
- **Trust in GitHub/Anthropic**: Inherent platform trust required

## Dependency Management

### Adding New GitHub Actions

Before adding any new GitHub Action:

1. **Verify Publisher**
   - Must be from verified organization (GitHub, official vendors)
   - Check repository for security policy (SECURITY.md)
   - Review recent commits and maintainer activity

2. **Pin to Commit SHA**
   ```yaml
   # Correct - pinned to SHA
   uses: actions/checkout@8e8c483db84b4bee98b60c0593521ed34d9990e8  # v4

   # Incorrect - mutable tag
   uses: actions/checkout@v4
   ```

3. **Add Version Comment**
   - Include version tag as comment for readability
   - Enables Dependabot to suggest updates

4. **Update This Document**
   - Add to dependency inventory table
   - Document verification performed

### Updating Dependencies

1. **Dependabot PRs**: Review and test before merging
2. **Manual Updates**: Verify new SHA before updating
3. **Security Patches**: Apply within 48 hours for critical CVEs

## Verification Process

### Pre-Merge Checklist

For PRs modifying `.github/workflows/`:

- [ ] All actions pinned to full commit SHA (40 hex characters)
- [ ] Version comments present for readability
- [ ] No new unverified actions introduced
- [ ] Permissions follow least-privilege principle
- [ ] This document updated if dependencies changed

### Verification Commands

```bash
# Check for unpinned actions (should return no results)
grep -r "uses:.*@v[0-9]" .github/workflows/ | grep -v "#"

# Verify all actions are pinned to SHA
grep -rh "uses:" .github/workflows/ | grep -E "@[a-f0-9]{40}"
```

## Incident Response

### Supply Chain Compromise Detected

If a GitHub Action is compromised:

1. **Immediate** (within 1 hour)
   - Disable affected workflows
   - Revoke any exposed credentials
   - Pin to known-good SHA

2. **Short-term** (within 24 hours)
   - Assess blast radius
   - Review workflow run history
   - Notify stakeholders

3. **Recovery** (within 1 week)
   - Update to patched version
   - Document incident
   - Review and strengthen controls

### Reporting

Report supply chain security concerns to repository maintainers or via the process outlined in SECURITY.md.

## Compliance

This policy aligns with:

- **NIST SSDF** (SP 800-218): Secure Software Development Framework
- **SLSA Framework**: Level 1 compliance (source integrity)
- **GitHub Security Best Practices**: Action pinning, Dependabot

## Review Schedule

This policy is reviewed:
- Quarterly (routine review)
- After any security incident
- When adding new dependencies
- When GitHub Actions security guidance changes

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-12-12 | Security Audit | Initial policy creation |
