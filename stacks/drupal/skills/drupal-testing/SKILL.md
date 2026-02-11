---
name: drupal-testing
description: Write and run PHPUnit tests for Drupal modules. Use when creating tests, debugging test failures, or improving test coverage. Includes templates for unit tests, mocking patterns, and data providers.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Drupal Testing Skill

This skill guides writing and running PHPUnit tests for Drupal 10/11 modules.

## Quick Reference

### Running Tests

```bash
# All unit tests
./vendor/bin/phpunit -c core/phpunit.xml.dist --group php_unit

# Module tests
./vendor/bin/phpunit -c core/phpunit.xml.dist modules/custom/<module>/tests/

# Single file
./vendor/bin/phpunit -c core/phpunit.xml.dist modules/custom/<module>/tests/src/Unit/ServiceTest.php

# Single method
./vendor/bin/phpunit -c core/phpunit.xml.dist --filter testMethodName

# With coverage
./vendor/bin/phpunit -c core/phpunit.xml.dist --coverage-html coverage/ modules/custom/<module>/tests/
```

### Test Directory Structure

```
modules/custom/<module>/
├── src/
│   └── Service/
│       └── MyService.php          # Class to test
└── tests/
    └── src/
        └── Unit/
            └── MyServiceTest.php  # Test class
```

## Test Types

| Type | Location | Speed | Use Case |
|------|----------|-------|----------|
| Unit | tests/src/Unit/ | Fast | Isolated class testing |
| Kernel | tests/src/Kernel/ | Medium | Drupal API integration |
| Functional | tests/src/Functional/ | Slow | Full browser testing |

**Focus on Unit tests** for most cases - they are fast and test logic in isolation.

## Conventions

Standard Drupal testing conventions:
- `Drupal\Tests\UnitTestCase` as base class
- Both PHPUnit `createMock()` and Prophecy `prophesize()`
- Data providers with `Generator`
- Annotations: `@group`, `@covers`, `@dataProvider`

## Basic Test Template

```php
<?php

namespace Drupal\Tests\<module>\Unit;

use Drupal\Tests\UnitTestCase;
use Drupal\<module>\Service\MyService;
use Drupal\Core\Logger\LoggerChannelInterface;
use PHPUnit\Framework\MockObject\MockObject;

/**
 * Tests for MyService.
 *
 * @coversDefaultClass \Drupal\<module>\Service\MyService
 * @group <module>
 */
class MyServiceTest extends UnitTestCase {

  /**
   * The service under test.
   */
  private MyService $service;

  /**
   * @var \Drupal\Core\Logger\LoggerChannelInterface|\PHPUnit\Framework\MockObject\MockObject
   */
  private LoggerChannelInterface|MockObject $logger;

  /**
   * {@inheritdoc}
   */
  protected function setUp(): void {
    parent::setUp();
    $this->logger = $this->createMock(LoggerChannelInterface::class);
    $this->service = new MyService($this->logger);
  }

  /**
   * @covers ::process
   */
  public function testProcessReturnsExpectedResult(): void {
    $result = $this->service->process('input');
    $this->assertEquals('expected', $result);
  }

}
```

## Related Files

- `TEST_TEMPLATES.md` - Detailed templates for different scenarios
- `MOCKING_GUIDE.md` - Comprehensive mocking patterns
- `ASSERTIONS.md` - All available assertions

## Finding Existing Tests

Find all test files in your project:

```bash
find modules/custom -path "*/tests/src/Unit/*.php" -type f
```
