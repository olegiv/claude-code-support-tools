---
description: "Run PHPUnit tests (default: the modules the change touches; or a module name, or 'all')"
argument-hint: [module-name | all]
allowed-tools: Bash, Read
---

Run tests for: $ARGUMENTS

1. Validate input:
   ```bash
   if [ -n "${ARGUMENTS:-}" ] && [ "$ARGUMENTS" != "all" ]; then
     if [ ${#ARGUMENTS} -gt 128 ]; then
       echo "ERROR: Input too long (max 128 characters)"
       exit 1
     fi
     if ! printf '%s' "$ARGUMENTS" | grep -qE '^[a-zA-Z0-9_]+$'; then
       echo "ERROR: Invalid module name. Only alphanumeric and underscores allowed."
       exit 1
     fi
   fi
   ```

2. Determine what to test. Test the updated code only, never the full suite unless the
   user asks for it:
   - If no argument: the custom modules and themes the change touches, compared with the
     remote default branch, plus uncommitted work. Keep each `modules/custom/<name>/` and
     `themes/custom/<name>/` whose `<name>` matches `^[a-z0-9_]+$` and that has a `tests/`
     directory. Ask the user only when the change touches none.
   - If a module name is specified: run tests for that module
   - If "all" is specified: run all unit tests. Only when the user asked for the full
     suite in their own message

3. Execute tests:

   For the touched modules and themes (no argument):
   ```bash
   base=$(git symbolic-ref -q --short refs/remotes/origin/HEAD || echo origin/main)
   set --
   # Machine names only ([a-z0-9_]), so no path from git output can carry shell syntax.
   for dir in $( { git diff --name-only "$base"...HEAD
                  git status --porcelain -uall \
                    | awk '{ sub(/^.. /, ""); n = split($0, p, " -> "); for (i = 1; i <= n; i++) print p[i] }'; } \
       | sed -n -E 's#^((modules|themes)/custom/[a-z0-9_]+)/.*#\1#p' | sort -u); do
     [ -d "$dir/tests" ] && set -- "$@" "$dir/tests/"
   done
   if [ $# -gt 0 ]; then
     ./vendor/bin/phpunit -c core/phpunit.xml.dist "$@"
   else
     echo "The change touches no custom module or theme with tests."
   fi
   ```

   For all tests (only on request):
   ```bash
   ./vendor/bin/phpunit -c core/phpunit.xml.dist --group php_unit
   ```

   For specific module:
   ```bash
   ./vendor/bin/phpunit -c core/phpunit.xml.dist "modules/custom/$ARGUMENTS/tests/"
   ```

4. Report results:
   - Total tests run
   - Passed/Failed count
   - Details of any failures
   - Recommendations for fixing failures
