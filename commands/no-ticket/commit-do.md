Create a git commit with the prepared commit message:

1. Verify there are changes to commit by running `git status`
2. If no commit message was prepared in the conversation, remind the user to run `/prepare-commit` first
3. Stage only the intended files from the prepared commit scope using explicit paths, for example `git add -- path/to/file`; do not use `git add .` or `git add -A`
4. Create the commit using the message prepared by `/prepare-commit`
5. Pass the message to `git commit -F` via a unique temp file. The message
   must NEVER pass through the shell — no heredocs, no `-m "$(...)"`, no
   `printf "$msg"`, no shared/predictable paths.
   - Run `mktemp "${TMPDIR:-/tmp}/claude-commit-msg.XXXXXX"` via Bash and
     capture the printed path. Use the positional template form (not
     `mktemp -t ...`) — `-t` means a literal *prefix* on macOS BSD and
     a *template* on GNU, so it is not portable. `mktemp` creates the
     file atomically with restrictive permissions, so it cannot be
     hijacked by a pre-existing symlink and will not collide with other
     concurrent sessions.
   - Use the `Write` tool to save the verbatim approved commit message to
     that captured path. If the `Write` tool fails for any reason (disk
     full, permission error), `rm -f` the captured path and abort
     before running `git commit` — do not commit a partial/empty
     message file. Example body:
     ```
     Subject line

     Body paragraph explaining what and why.

     - Bullet point if needed
     - Another point
     ```
   - Run the commit using the captured path: `git commit -F <path>`
   - **Always** run `rm -f <path>` afterward as a separate Bash step,
     regardless of whether the commit succeeded or failed. Do not skip
     cleanup on a hook rejection, GPG failure, empty-index error, or any
     other failure path — the temp file must never leak.
6. After successful commit, run `git status` to confirm
7. Do NOT ask the user if they want to push the changes
8. Do NOT push automatically – wait for explicit confirmation
