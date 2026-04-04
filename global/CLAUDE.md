# ⛔ STOP - READ THIS FIRST ⛔

## MANDATORY: Respect the Active Permission Mode

IMPORTANT: You MUST operate in the current mode. In plan mode: NO code, NO file edits, NO commits. Enforced by hooks — violations are automatically detected.

---

## MANDATORY: Git Commit Approval Workflow

**Before ANY `git commit` command, you MUST:**
1. Present the draft commit message to the user
2. Explicitly ask: "Should I proceed with this commit?"
3. WAIT for the user's approval (e.g., "yes", "proceed", "commit it")
4. Only THEN execute the commit

### ❌ WRONG - Never do this:
```
User: "Add the login feature"
Claude: *writes code*
Claude: *immediately runs `git commit`* ← VIOLATION!
```

### ❌ WRONG - Never do this:
```
User: "/commit-prepare"
Claude: "Here's the commit message: ..."
Claude: *immediately runs `git commit`* ← VIOLATION! Must wait for approval!
```

### ✅ CORRECT - Always do this:
```
User: "/commit-prepare"
Claude: "Here's the draft commit message:
         [message]
         Should I proceed with this commit?"
User: "yes"
Claude: *now executes `git commit`*
```

**This rule has NO exceptions. Even if you think it's obvious the user wants a commit, ASK FIRST.**

---

## Commit & PR Formatting

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

## Chrome Extension Testing

**CRITICAL:** When testing UI changes that require visual verification in Chrome:

1. **Check Chrome connection first**: If Chrome extension is not connected, **STOP IMMEDIATELY**
2. **Ask user to fix**: Tell the user to connect the Chrome extension before proceeding
3. **Do NOT fallback to curl**: Visual layout issues cannot be detected with curl - you MUST use Chrome
4. **Wait for connection**: Do not continue testing until Chrome extension is available

### When Chrome Extension is Required
- Layout verification
- CSS/styling checks
- Visual regression testing
- Any task where the user says "look in Chrome"

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