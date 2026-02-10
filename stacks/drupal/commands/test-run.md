---
description: Run PHPUnit tests (optional: module name or 'all')
argument-hint: [module-name | all]
allowed-tools: Bash, Read
---

Run tests for: $ARGUMENTS

1. Determine what to test:
   - If "all" is specified: run all unit tests
   - If a module name is specified: run tests for that module
   - If no argument: ask the user which module to test

2. Execute tests:

   For all tests:
   ```bash
   ./vendor/bin/phpunit -c core/phpunit.xml.dist --group php_unit
   ```

   For specific module:
   ```bash
   ./vendor/bin/phpunit -c core/phpunit.xml.dist modules/custom/$1/tests/
   ```

3. Report results:
   - Total tests run
   - Passed/Failed count
   - Details of any failures
   - Recommendations for fixing failures
