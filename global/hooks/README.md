# Git Pre-Commit Hook

This directory contains git hooks that prevent Claude Code from creating automated commits without explicit user approval.

## Pre-Commit Hook

The `pre-commit` hook blocks all automated commit attempts and requires interactive user confirmation.

### What It Does

- ✅ **Interactive mode**: Prompts user to type "YES" (all caps) to approve commit
- ❌ **Non-interactive mode**: Always blocks automated commits from Claude Code
- 🔒 **Cannot be bypassed**: Physically prevents Claude Code from committing without approval

### Installation

#### Option 1: Install to Single Repository

Copy the hook to a specific git repository:

```bash
# Navigate to your project
cd /path/to/your/project

# Copy the hook
cp /path/to/.claude/shared/global/hooks/pre-commit .git/hooks/pre-commit

# Make it executable
chmod +x .git/hooks/pre-commit
```

#### Option 2: Install Globally (All Future Repos)

Set up global git hooks directory:

```bash
# Create global hooks directory
mkdir -p ~/.git-hooks

# Copy the hook
cp /path/to/.claude/shared/global/hooks/pre-commit ~/.git-hooks/pre-commit

# Make it executable
chmod +x ~/.git-hooks/pre-commit

# Configure git to use global hooks
git config --global core.hooksPath ~/.git-hooks
```

**Note**: This affects all NEW repositories you create or clone. Existing repos need manual installation (Option 1).

#### Option 3: Install to All Existing Repos

Use this script to install the hook to all existing git repositories in a directory:

```bash
#!/bin/bash
# install-to-existing-repos.sh

echo "Enter directory to search for git repos (e.g., ~/Projects):"
read -p "Directory: " search_dir

# Expand ~ to home directory
search_dir="${search_dir/#\~/$HOME}"

if [ ! -d "$search_dir" ]; then
    echo "❌ Directory does not exist: $search_dir"
    exit 1
fi

echo "Searching for git repositories in: $search_dir"
echo ""

found=0
while IFS= read -r git_dir; do
    repo_path=$(dirname "$git_dir")
    hook_path="$git_dir/hooks/pre-commit"

    echo "Found: $repo_path"

    # Copy the hook
    cp ~/.git-hooks/pre-commit "$hook_path"
    chmod +x "$hook_path"

    echo "  ✅ Hook installed"
    ((found++))
done < <(find "$search_dir" -type d -name ".git" 2>/dev/null)

echo ""
echo "Installed hook to $found repositories"
```

### How It Works

When you commit:

```bash
git add .
git commit -m "Your commit message"
```

The hook will prompt:

```
================================================
  GIT COMMIT CONFIRMATION REQUIRED
================================================

A commit is being attempted.

Type 'YES' (all caps) to approve this commit,
or anything else to abort:

Approve commit?
```

Type `YES` to proceed, or anything else to cancel.

### Claude Code Workflow

When the user explicitly requests a commit (e.g., `/commit-do`), Claude Code uses `--no-verify` to bypass the hook. The user's explicit request IS the approval — the hook only blocks unsolicited automated commits.

```bash
# User-requested commit (Claude Code uses this):
git commit --no-verify -m "message"
```

### When Claude Code Tries to Commit Without Approval

If Claude Code attempts an automated commit without `--no-verify`, the hook blocks it:

```
================================================
  ❌ COMMIT BLOCKED - NON-INTERACTIVE MODE
================================================

This commit was attempted in non-interactive mode.
All commits must be approved interactively by the user.

To commit, run 'git commit' manually in your terminal.
```

### Removing the Hook

#### Remove from single repository

```bash
rm .git/hooks/pre-commit
```

#### Remove global configuration

```bash
# Remove global hooks path
git config --global --unset core.hooksPath

# Optionally delete the hooks directory
rm -rf ~/.git-hooks
```

## Why Use This Hook?

This hook provides physical protection against automated commits by AI assistants like Claude Code. It ensures:

1. **User Control**: You explicitly approve every commit
2. **Code Review**: You can review changes before committing
3. **No Surprises**: Claude Code cannot commit without your knowledge
4. **Safety**: Prevents accidental commits of sensitive data or incomplete work

## Compatibility

- ✅ macOS
- ✅ Linux
- ✅ Git Bash (Windows)
- ✅ WSL (Windows Subsystem for Linux)

## License

Copyright (c) 2025-2026 Oleg Ivanchenko

GNU General Public License v3.0 - see LICENSE file for details.
