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

## Code Compilation Rules

**Always fix SASS and TS compilation deprecation warnings.** When compiling SCSS/SASS or TypeScript and deprecation warnings appear, address them immediately rather than ignoring them.

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
