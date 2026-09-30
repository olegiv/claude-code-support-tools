---
description: "Review changes and prepare a commit message"
---

Review changes and prepare a commit message.

**Parameter:** `$ARGUMENTS` - Set to `quality` or `q` to run code quality checks first (default: skip quality checks)

## Step 1: Run the Test Gate (Mandatory)

Run the project's full test suite before anything else: the test-gate command its `CLAUDE.md` names, or `go test ./...` if it names none. Go's test cache re-runs only the packages the change affects, so this is usually fast.

- **If any test fails:**
  1. List every failing test with its output
  2. Do NOT draft a commit message
  3. Stop and report. A test that fails once is a failure even if a re-run passes: report it as a flake instead of re-running until it passes

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

Present the draft commit message to the user for approval, together with the test gate result (for example: "Tests: `go test ./...` passed").

**IMPORTANT:** Do NOT create the commit yet - just prepare the message.
