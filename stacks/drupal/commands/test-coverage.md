---
description: Check test coverage for a module
argument-hint: <module_name>
allowed-tools: Bash, Glob, Read
---

Check test coverage for module: $ARGUMENTS

## Instructions

1. **Find all PHP classes in the module**:
   ```bash
   find modules/custom/$1/src -name "*.php" -type f
   ```

2. **Find all test files**:
   ```bash
   find modules/custom/$1/tests -name "*Test.php" -type f 2>/dev/null
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
   ./vendor/bin/phpunit -c core/phpunit.xml.dist modules/custom/$1/tests/ 2>&1 | tail -20
   ```
