---
description: Generate PHPUnit test for a class or module
argument-hint: <module/path/to/Class.php> or <module_name>
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

Generate PHPUnit tests for: $ARGUMENTS

## Instructions

### 0. Validate Input
```bash
if [ ${#ARGUMENTS} -gt 256 ]; then
  echo "ERROR: Input too long (max 256 characters)"
  exit 1
fi

# Block path traversal
if echo "$ARGUMENTS" | grep -qE '\.\.'; then
  echo "ERROR: Path traversal not allowed"
  exit 1
fi

# Validate: module name (alphanumeric/underscore) or file path (safe chars)
if ! echo "$ARGUMENTS" | grep -qE '^[a-zA-Z0-9_./-]+$'; then
  echo "ERROR: Invalid input. Only alphanumeric, dots, slashes, hyphens, underscores allowed."
  exit 1
fi
```

1. **Parse the argument**:
   - If a file path is provided (contains `/` or `.php`), create tests for that specific class
   - If a module name is provided, list testable classes and ask which to test

2. **For a specific class file**:
   - Read the source file to understand:
     - Class namespace and name
     - Constructor dependencies
     - Public methods to test
     - Method signatures and return types

3. **Create the test file**:
   - Location: `modules/custom/<module>/tests/src/Unit/<ClassName>Test.php`
   - Create directory if needed: `mkdir -p modules/custom/<module>/tests/src/Unit`

4. **Follow Drupal testing conventions**:
   - Use `Drupal\Tests\UnitTestCase` as base class
   - Add `@coversDefaultClass` annotation
   - Add `@group <module_name>` annotation
   - Create mocks for all constructor dependencies
   - Add `@covers` annotation for each test method
   - Use descriptive test method names: `testMethodNameReturnsExpectedResult`

5. **Generate tests for each public method**:
   - Happy path test
   - Edge cases (null, empty, boundary values)
   - Exception cases where applicable

6. **After creating the test file**:
   - Run syntax check: `php -l <test_file>`
   - Run the test: `./vendor/bin/phpunit -c core/phpunit.xml.dist <test_file>`
   - Report results

## Example Output Structure

```php
<?php

namespace Drupal\Tests\<module>\Unit;

use Drupal\Tests\UnitTestCase;
use Drupal\<module>\<Namespace>\<ClassName>;
// ... dependency imports

/**
 * Tests for <ClassName>.
 *
 * @coversDefaultClass \Drupal\<module>\<Namespace>\<ClassName>
 * @group <module>
 */
class <ClassName>Test extends UnitTestCase {

  private <ClassName> $service;
  // ... mock properties

  protected function setUp(): void {
    parent::setUp();
    // Create mocks
    // Instantiate service
  }

  /**
   * @covers ::methodName
   */
  public function testMethodName(): void {
    // Test implementation
  }

}
```
