---
description: Run PHPUnit tests (optional: module name or 'all')
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
     if ! echo "$ARGUMENTS" | grep -qE '^[a-zA-Z0-9_]+$'; then
       echo "ERROR: Invalid module name. Only alphanumeric and underscores allowed."
       exit 1
     fi
   fi
   ```

2. Determine what to test:
   - If "all" is specified: run all unit tests
   - If a module name is specified: run tests for that module
   - If no argument: ask the user which module to test

3. Execute tests:

   For all tests:
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
