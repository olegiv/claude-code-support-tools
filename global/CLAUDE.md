# Global Development Rules for Claude Code

This file contains user-level instructions that apply to ALL projects.

## Git Workflow Rules

**CRITICAL:** Never create commits or push changes unless explicitly instructed by the user.

### Rules
1. **No automatic commits**: Do NOT commit changes automatically after completing tasks
2. **No automatic pushes**: Do NOT push to remote repositories unless explicitly asked
3. **Wait for instruction**: After completing work, inform the user and wait for them to ask for a commit
4. **User controls git**: The user decides when and what to commit

### When to Create Commits
- **Only when explicitly asked**: "commit these changes", "create a commit", "git commit", etc.
- **Never proactively**: Even after completing major features or fixes
- **Let user review first**: User may want to test or review changes before committing

### Commit Message Formatting
**CRITICAL:** Never add these lines to commit messages:
```
🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

Keep commit messages clean and professional without AI attribution footers.

### Commit Message Best Practices

#### Structure and Limits

**Subject line (first line):**
- **Format**: `Brief description`
- **Maximum length**: 50 characters (hard limit: 72 characters)
- **Style**: Use imperative mood ("Add feature" not "Added feature")
- **No period** at the end

**Body (optional, after blank line):**
- **Maximum line length**: 72 characters per line
- **Content**: Explain *what* and *why*, not *how*
- Use bullet points for multiple changes
- No limit on number of lines (typically 5-15 lines)

#### Example Format

```
Add dynamic arrow colors to DW3 widget

Update the DW3 widget to support custom arrow colors based on
the arrows color field. The SVG data URIs are now generated
dynamically with the selected color.

- Add arrowPrevImage and arrowNextImage to Dw3Settings
- Generate URL-encoded SVG data URIs in Dw3Helper
- Fix quote encoding in SVG attributes (%27)
```

#### Rules

1. **Subject under 50 chars**
2. **Blank line** between subject and body
3. **Wrap body at 72 chars**: For readability in terminals and git tools
4. **Use imperative mood**: "Add", "Fix", "Update", not "Added", "Fixed", "Updated"
5. **Focus on why**: Explain the reason for changes, not just what changed

### Pull Request Formatting

**CRITICAL:** Never add these lines to pull request messages:
```
🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Keep pull request messages clean and professional without AI attribution footers.

## Claude Code Permissions

**IMPORTANT:** Understand the difference between shared and local permissions files:

### Permission Files
- **`.claude/settings.json`** - Shared team permissions may be checked into git
- **`.claude/settings.local.json`** - Personal local permissions, **NEVER commit** (gitignored)

### Rules
1. **Never commit `.claude/settings.local.json`**: This file is for personal/local testing and is automatically gitignored
2. **Commit `.claude/settings.json`**: Use this for team-wide permissions that everyone needs
3. When adding new scripts:
   - For personal testing → add to `.claude/settings.local.json`
   - For team use → add to `.claude/settings.json` and commit

## Security Audit Files

**IMPORTANT:** Security audit results and status files are stored in the `.audit` directory in the project root.

### Rules
1. **Always gitignored**: The `.audit` directory must always be in `.gitignore`
2. **Never commit**: Do NOT commit security audit results or status files
3. **Local only**: These files are for local security testing and analysis only
4. **Update after fixes**: After fixing security issues mentioned in `.audit` files, ALWAYS update the relevant audit documentation to reflect the fix status and changes made

## Quality Assurance Rules

**CRITICAL:** Always test what you do before giving the result to the user.

### Rules
1. **Test before presenting**: After making changes, verify they work by running appropriate commands (build, compile, lint, curl, etc.)
2. **Verify package installations**: After `npm install` or `composer require`, confirm the installation succeeded without errors
3. **Check generated files**: After generating files, verify they exist and contain expected content
4. **Validate configurations**: After modifying config files, test that the application still works
5. **Test endpoints**: After configuring URLs or APIs, use `curl` to verify they respond correctly
6. **Never assume success**: Always verify commands completed successfully before reporting completion

## Package Installation Rules

**CRITICAL:** When installing new packages, always verify version and security status.

### Golden Rules
1. **NEVER trust your memory for versions**: Always check the latest stable version online using `npm view`, `composer show`, or web search - NEVER guess or assume versions from memory
2. **NEVER trust your memory for dates**: When you need current date, year, or time - ALWAYS get it from the system using `date` command, NEVER use dates from memory
3. **Use latest stable**: Always install the latest stable version, not alpha/beta/rc versions unless explicitly requested
4. **Check for vulnerabilities**: Run security audit after installation
5. **ASK if no safe version**: If no safe version is available, ASK the user what to do before proceeding

### npm Packages
```bash
# Check versions first - ALWAYS do this
npm view <package> versions --json | tail -10

# Install specific version
npm install <package>@<version>

# Verify no vulnerabilities
npm audit
```

### Composer (PHP) Packages
```bash
# Check available versions - ALWAYS do this
composer show <package> --available

# Install
composer require <package>:<version>

# Security audit
composer audit
```

### Go Packages

**CRITICAL:** NEVER downgrade the Go version in `go.mod`. If a package requires a newer Go version, inform the user.

```bash
# Check latest version - ALWAYS do this
go list -m -versions <module>

# Check for vulnerabilities before adding
govulncheck -mode=module <module>

# Add the package
go get <module>@<version>

# Run vulnerability check on project
govulncheck ./...
```

## Code Compilation Rules

**Always fix SASS and TS compilation deprecation warnings.** When compiling SCSS/SASS or TypeScript and deprecation warnings appear, address them immediately rather than ignoring them.

## File Permissions

When creating files or directories, always set appropriate permissions:
- **Files**: `644` (rw-r--r--)
- **Directories**: `755` (rwxr-xr-x)

## Command Compatibility

**⚠️ IMPORTANT: This section applies ONLY when running on macOS systems. ⚠️**

**CRITICAL:** When the environment indicates `Platform: darwin` (macOS), ALWAYS use macOS/BSD-compatible commands. When running shell commands on macOS, use BSD-compatible syntax and tools, NOT GNU/Linux syntax.

### macOS-Specific Command Syntax (ONLY for Platform: darwin)
- Use `sed -i ''` instead of `sed -i` (GNU)
- Use `shasum -a 256` instead of `sha256sum`
- Use `stat -f %m` instead of `stat -c %Y`
- Use `date -r <timestamp>` instead of `date -d @<timestamp>`
- Prefer `grep -E` over `egrep` (deprecated)
- Use `mktemp` without template argument or with macOS-compatible format

**Note:** On Linux systems, use standard GNU commands instead.

---

*This file applies globally to all your projects. Project-specific CLAUDE.md files can add additional context.*
