---
description: "Review changes and prepare a commit message"
---

Review changes and prepare a commit message.

**Parameter:** `$ARGUMENTS` - Set to `quality` or `q` to run code quality checks first (default: skip quality checks)

## Step 1: Run the Test Gate (Mandatory)

Before drafting a message, prepare and run the project's full test gate:

1. Inspect the intended diff, test command, and code it executes before running it. For an untrusted checkout, select and show the exact command and obtain explicit approval unless the user already authorized that command and code. Run it only in an isolated environment without host credentials, unrelated host files, or network access; if that is unavailable, stop. This also applies to default Go tests.
2. Stage only the intended paths and record `git write-tree`. Run tests with no unstaged tracked changes or non-ignored untracked files; preserve unrelated work and use an isolated copy of the index tree if needed. Verify the test checkout still matches that tree after testing. Recheck the index immediately before committing and verify the resulting commit tree; changes from later quality tools, edits, or hooks invalidate the pass and require a fresh gate.
3. Use the test-gate command the project's `CLAUDE.md` names. Disable Go test-result caching even for a project-defined script or Make target: use `-count=1` on each `go test`, or run `go clean -testcache` immediately before the gate in the same Go environment/cache it uses. Disable any wrapper-level result cache too; if fresh execution cannot be established, stop.
4. If no gate is named, check `go env GOWORK`. For an active workspace, enumerate all main modules with `go list -m -json` and run `go test -count=1 ./...` from every module's `Dir`, preserving spaces in paths. Otherwise run it from the module root. A discovery error, unavailable module, or failed module run blocks the gate; never silently skip a module. Without a usable module/workspace, ask for the project's test command instead of claiming a pass.

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
