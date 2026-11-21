---
description: Check test coverage for a module
argument-hint: <module_name>
allowed-tools: Bash, Glob, Read
---

Check test coverage for module: $ARGUMENTS

**Check the arguments before running anything.** The command arguments are inserted into this prompt before any shell runs, so the shell checks below cannot protect a command that contains them. Check them yourself first: they must be one module machine name matching `^[a-zA-Z0-9_]+$`. The whole value must match, on a single line; if you are unsure whether it matches, treat it as invalid. If it does not match, stop and report the invalid argument without running any command. Run the steps below only with arguments that passed this check; their shell blocks read the value from `ARGS`.

## Instructions

0. **Validate input**:
   ```bash
   ARGS='$ARGUMENTS'  # passed the argument check above, so it contains no '
   if [ -z "${ARGS}" ]; then
     echo "ERROR: Module name is required"
     exit 1
   fi
   if [ ${#ARGS} -gt 128 ]; then
     echo "ERROR: Input too long (max 128 characters)"
     exit 1
   fi
   if ! printf '%s' "$ARGS" | grep -qE '^[a-zA-Z0-9_]+$'; then
     echo "ERROR: Invalid module name. Only alphanumeric and underscores allowed."
     exit 1
   fi
   MODULE_NAME="$ARGS"
   ```

1. **Find all PHP classes in the module**:
   ```bash
   MODULE_NAME='$ARGUMENTS'  # passed the argument check above; each Bash call is a new shell
   [ -d "modules/custom/$MODULE_NAME/src" ] || { echo "ERROR: modules/custom/$MODULE_NAME/src not found"; exit 1; }
   find "modules/custom/$MODULE_NAME/src" -name "*.php" -type f
   ```

2. **Find all test files**:
   ```bash
   MODULE_NAME='$ARGUMENTS'  # passed the argument check above; each Bash call is a new shell
   if [ -d "modules/custom/$MODULE_NAME/tests" ]; then
     find "modules/custom/$MODULE_NAME/tests" -name "*Test.php" -type f
   else
     echo "No tests directory: modules/custom/$MODULE_NAME/tests (0 test files)"
   fi
   ```

3. **Analyze coverage**:
   - List classes that have corresponding tests
   - List classes that are missing tests
   - Calculate coverage percentage

4. **Report format**:

   ```
   ## Test Coverage Report: <module>

   ### Classes with Tests
   - ClassName -> ClassNameTest.php

   ### Classes Missing Tests
   - OtherClass (src/Service/OtherClass.php)
   - AnotherClass (src/Controller/AnotherClass.php)

   ### Summary
   - Total classes: X
   - Classes with tests: Y
   - Coverage: Z%

   ### Recommendations
   - Priority classes to test: [list based on complexity]
   ```

5. **Optionally run existing tests**:
   ```bash
   MODULE_NAME='$ARGUMENTS'  # passed the argument check above; each Bash call is a new shell
   [ -d "modules/custom/$MODULE_NAME/tests" ] || { echo "No tests to run: modules/custom/$MODULE_NAME/tests not found"; exit 0; }
   ./vendor/bin/phpunit -c core/phpunit.xml.dist "modules/custom/$MODULE_NAME/tests/" 2>&1 | tail -20
   ```
