---
description: Revert Drupal feature(s) to sync config from code
argument-hint: [module-name...]
allowed-tools: Bash
---

Revert Drupal features: $ARGUMENTS

**Check the arguments before running anything.** The command arguments are inserted into this prompt before any shell runs, so the shell checks below cannot protect a command that contains them. Check them yourself first: they must be empty (then list the features and stop), or one or more module machine names separated by spaces, each matching `^[a-zA-Z0-9_][a-zA-Z0-9_-]*$`. The whole value must match, on a single line; if you are unsure whether it matches, treat it as invalid. If it does not match, stop and report the invalid argument without running any command. Run the steps below only with arguments that passed this check; their shell blocks read the value from `ARGS`.

1. If no module is given, list the features and stop:
   ```bash
   ./vendor/bin/drush features:list 2>/dev/null || ./vendor/bin/drush pm:list --status=enabled
   ```
   Then ask the user to run `/feature-revert <module...>` with the names. Do not
   revert anything in this run: names given in the conversation have not passed
   the argument check.

2. With module names, check them and revert in one Bash call, so the names that
   are checked are the names that run:
   ```bash
   ARGS='$ARGUMENTS'  # passed the argument check above, so it contains no '
   [ -n "$ARGS" ] || { echo "ERROR: No module given; run /feature-revert <module...>"; exit 1; }
   if [ ${#ARGS} -gt 500 ]; then
     echo "ERROR: Input too long (max 500 characters)"
     exit 1
   fi
   if [ "$(printf '%s' "$ARGS" | LC_ALL=C tr -d '[:print:]' | wc -c)" -ne 0 ]; then
     echo "ERROR: Module names must be one line of printable characters"
     exit 1
   fi
   if ! printf '%s\n' "$ARGS" | grep -qxE '[a-zA-Z0-9_][a-zA-Z0-9_-]*( [a-zA-Z0-9_][a-zA-Z0-9_-]*)*'; then
     echo "ERROR: Use module machine names separated by single spaces"
     exit 1
   fi
   # Split into separate names explicitly (zsh does not split "$ARGS", but both
   # shells split an unquoted command substitution), then pass them quoted.
   # -y before -- so drush reads it as an option; names after -- are positional.
   set -- $(printf '%s\n' "$ARGS")
   ./vendor/bin/drush fr -y -- "$@" || { echo "ERROR: Feature revert failed; caches were not cleared"; exit 1; }
   ./vendor/bin/drush cr
   ```

3. Report:
   - Features reverted
   - Any errors or warnings
   - Configuration changes applied

Note: Feature revert syncs configuration from code (config/install/) to the database.
