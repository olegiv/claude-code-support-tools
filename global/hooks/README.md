# Git Hooks

This directory contains git hooks that keep the human in control of commits and pushes: a `pre-commit` approval gate and a `pre-push` gate for the `pr-fix` review-repair workflow.

## Pre-Commit Hook

The `pre-commit` hook blocks all automated commit attempts and requires interactive user confirmation.

### What It Does

- ✅ **Interactive mode**: Prompts user to type "YES" (all caps) to approve commit
- ❌ **Non-interactive mode**: Always blocks automated commits from Claude Code
- 🔒 **Strong default barrier**: Blocks accidental non-interactive commits and requires typed confirmation interactively. This is not a cryptographic guarantee — it relies on `git commit --no-verify` being reserved for genuinely user-approved commits (a behavioral convention, since `--no-verify` is a standard flag available to any caller), and a deliberately-instructed or compromised agent could in principle allocate a pseudo-terminal to satisfy the interactive check.

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

## Pre-Push Hook (pr-fix push gate)

`pre-push` is a thin wrapper around the `pr-fix` skill's runner
(`global/skills/pr-fix/scripts/pr-fix.sh pre-push`). It enforces the two-push
repair workflow mechanically, for Claude Code, Codex and the human alike.

### What It Does

- **Armed only when a findings round has started**: it acts on a branch only if
  `<repo>/.audit/pr-<N>/state.json` exists for that branch's pull request.
  Ordinary pushes and repositories without `pr-fix` state are untouched.
- **Refuses** a push when the commit's tree is not the tree the last local
  Codex review saw, when the merge base moved since that review, when
  `pr-fix.sh status` is not `ready`, or when the branch already has the
  maximum number of fix pushes (`PRF_MAX_PUSHES`, default 2).
- **Records** every allowed push in the state, so the round counter survives
  tool switches even if the agent forgets to log it.
- **Makes no network calls.** A pushed branch is matched against saved state by
  branch name; branches without state are unarmed. Fails open with a notice when
  `jq` or the runner is missing.
- **Gates only pushes to the pull request's repository.** The remote URL must name
  the PR's base or head repository on the PR's host. For SSH URLs the destination
  is resolved with `ssh -G user@host` (`CanonicalizeHostname=no`, so no DNS), which
  evaluates your own `~/.ssh/config`, including any `Match exec` you wrote; set
  `git config prf.sshResolve false` to compare hosts as written instead. HTTP(S)
  hosts are compared as written. A same-named mirror on another host is neither
  gated nor counted. `git config prf.baseRemote <name>` names the PR remote
  explicitly when detection cannot.
- **Chains** to the repository's own `.git/hooks/pre-push` afterwards, feeding
  it the same ref list, because `core.hooksPath` hides per-repository hooks.
- Performs no AI review itself; the review happens earlier via
  `pr-fix.sh review`.
- Known limitation: git has no post-push hook, so the push is recorded when the
  gate allows it. If git then fails to complete the push (remote rejection,
  network error), run `pr-fix.sh record-push --undo` before retrying so the
  attempt does not consume the two-push budget.

### Bypasses

```bash
PRF_SKIP_PUSH_GATE=1 git push        # one push
git config prf.pushGate false        # this repository
git push --no-verify                 # git's own bypass
```

### Runner Lookup

`$PRF_RUNNER`, then `git config prf.runner`, then
`~/.claude/skills/pr-fix/scripts/pr-fix.sh`, then
`~/.codex/skills/pr-fix/scripts/pr-fix.sh`.

### Installation

```bash
mkdir -p ~/.git-hooks
ln -s "$PWD/global/hooks/pre-push" ~/.git-hooks/pre-push
git config --global core.hooksPath ~/.git-hooks
```

`core.hooksPath` makes git ignore each repository's `.git/hooks`; the wrapper's
chain step restores them for `pre-push`. A repository that sets its own
`core.hooksPath` (for example `make install-hooks` → `.githooks`) overrides the
global one, so git will not run this wrapper there; copy or symlink it into that
directory instead. Install the skill itself with the symlinks described in the
README ("Using Global Skills") so the runner is found.

### Tests

```bash
sh global/tests/pr-fix-test.sh
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
