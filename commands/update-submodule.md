Update the shared Claude Code submodule to latest version.

Execute the following steps:

1. Show current submodule status:
   ```bash
   git submodule status
   ```

2. Pull latest changes for the submodule:
   ```bash
   git submodule update --remote --merge
   ```

3. Show new submodule status:
   ```bash
   git submodule status
   ```

4. Report what changed:
   - Show commit hash before and after
   - Indicate if submodule was already up to date

5. If changes were pulled, remind user:
   - Changes to submodule reference are not committed
   - To keep the update: stage and commit the submodule change
   - To revert: `git submodule update`

This updates the `.claude/shared` submodule which contains shared Claude Code support tools (agents, commands, skills) used across projects.
