Create a git commit with the prepared commit message:

1. Verify there are changes to commit by running `git status`
2. If no commit message was prepared in the conversation, remind the user to run `/prepare-commit` first
3. Add all changed files to staging: `git add .`
4. Create the commit using the message prepared by `/prepare-commit`
5. Write the approved message to a temporary file using the `Write` tool, then
   commit with `git commit -F` so the message is treated strictly as data and
   never parsed by the shell. Do NOT use a shell heredoc — any fixed delimiter
   can collide with a line in the commit body and re-introduce injection.
   - Use the `Write` tool to save the verbatim approved message to
     `/tmp/claude-commit-msg.txt`. Example body:
     ```
     Subject line

     Body paragraph explaining what and why.

     - Bullet point if needed
     - Another point
     ```
   - Run the commit: `git commit -F /tmp/claude-commit-msg.txt`
   - Always remove the temp file afterward, on both success AND failure
     (e.g., `rm -f /tmp/claude-commit-msg.txt`), so a failed commit cannot
     leak the message file.
6. After successful commit, run `git status` to confirm
7. Do NOT ask the user if they want to push the changes
8. Do NOT push automatically – wait for explicit confirmation