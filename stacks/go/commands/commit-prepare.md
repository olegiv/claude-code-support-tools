---
description: "Review changes and prepare a commit message"
---

Review changes and prepare a commit message.

**Parameter:** `$ARGUMENTS` - Set to `quality` or `q` to run code quality checks first (default: skip quality checks)

## Step 1: Run the Test Gate (Mandatory)

Before drafting a message, prepare and run the project's full test gate:

1. Inspect the intended diff, test command, and code it executes before running it. For an untrusted checkout, select and show the exact command and obtain explicit approval unless the user already authorized that command and code. Run it only in an isolated environment without host credentials, unrelated host files, or network access; if that is unavailable, stop. This also applies to default Go tests.
2. Assemble only the intended content in a temporary index or disposable checkout and record its `git write-tree`; leave the real index and worktree unchanged for later review steps. Inspect staged and unstaged scope and retain the intended diff for drafting. Run the gate in a newly populated isolated checkout of that tree, without copying ignored/untracked source, configuration, or artifacts from the developer checkout. Provision dependencies/generated inputs only through declared reproducible setup in the snapshot; missing inputs or setup failures block the gate. Resolve workspace/config paths within the snapshot or declared dependencies and verify tracked content is unchanged after setup and tests. After approval, stage exactly the tested content; edits or quality-tool changes require a fresh gate.
3. Before committing, require the real index tree to match the passing tree and inspect the effective `pre-commit`, `prepare-commit-msg`, and `commit-msg` hooks, including `core.hooksPath`. Each potentially index-mutating or unknown hook requires a project-provided guard after its original handler, before returning to Git, that aborts on a tree mismatch and preserves handler failures. Without those guards, stop. A final `commit-msg` check alone cannot detect an earlier changed tree cached by Git and then restored in the index. Never bypass required guards with `--no-verify`, even when another command permits it. Re-run the gate after correcting a mismatch before retrying.
4. Use the test-gate command the project's `CLAUDE.md` names. Disable Go test-result caching even for a project-defined script or Make target: use `-count=1` on each `go test`, or run `go clean -testcache` immediately before the gate in the same Go environment/cache it uses. Disable any wrapper-level result cache too; if fresh execution cannot be established, stop.
5. If no gate is named, discover repository-owned `go.mod` files throughout the candidate tree, excluding vendored dependencies, and check `go env GOWORK` in the snapshot. With no workspace, run `go test -count=1 ./...` from the module root only if exactly one module exists. With a workspace, use `go list -m -json`, verify all repository-owned modules are included, and run the uncached command from every main module's `Dir`, preserving spaces in paths. Multiple standalone modules, incomplete workspace coverage, ambiguous ownership, or no usable module/workspace require a documented project-wide gate. Discovery errors, unavailable modules, and failing runs block preparation; never silently skip a module.

- **If any test fails:**
  1. List every failing test with its output
  2. Do NOT draft a commit message
  3. Stop and preserve the failure output. A later pass without a relevant code, test, or environment correction is a flake, not a passing gate. After fixing the cause, explain the correction and restart Step 1 against the corrected tree; a fresh full pass can unblock preparation

- **If all tests pass:** Continue to Step 2.

## Step 2: Code Quality Checks (Optional)

**If `$ARGUMENTS` contains "quality" or "q":**

Run the `/code-quality` command.

- **If any warnings or errors are found:**
  1. List all warnings/errors clearly
  2. Ask the user: "Code quality issues found. Do you want to proceed with commit anyway?"
  3. Wait for user confirmation before continuing
  4. If user declines, stop and suggest fixes

- **If no warnings:** Continue to Step 3.

**If `$ARGUMENTS` is empty or doesn't contain "quality"/"q":** Skip to Step 3.

## Step 3: Review Changes

1. Run `git status` to see all changed files
2. Run `git diff` to see the changes
3. Run `git log -5 --oneline` to see recent commit style

## Step 4: Prepare Commit Message

Analyze all changes and draft a commit message following these rules:
- Subject line format: `Brief description`
- Subject line max 50 characters
- Use imperative mood ("Add feature" not "Added feature")
- No period at end of subject
- Blank line between subject and body
- Body lines wrapped at 72 characters
- Explain *what* and *why*, not *how*
- Never include "Bump module version" in commit messages
- Never add AI attribution footers

## Step 5: Present for Approval

Present the draft commit message to the user for approval, together with the actual test command(s), tested tree hash, and result (for a single-module fallback: "Tests: `go test -count=1 ./...` passed for tree `<hash>`"). If Step 2 or later edits changed the tested tree, rerun Step 1 first.

**IMPORTANT:** Do NOT create the commit yet - just prepare the message.
