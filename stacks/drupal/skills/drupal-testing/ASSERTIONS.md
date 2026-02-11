# PHPUnit Assertions Reference

Complete reference for assertions in PHPUnit tests.

## Equality Assertions

```php
// Equal (type coercion)
$this->assertEquals('expected', $actual);
$this->assertEquals(100, '100');  // Passes

// Same (strict type)
$this->assertSame('expected', $actual);
$this->assertSame(100, '100');  // Fails

// Not equal
$this->assertNotEquals('unexpected', $actual);
$this->assertNotSame('unexpected', $actual);

// With delta (for floats)
$this->assertEqualsWithDelta(1.0, 0.99, 0.1);  // Passes
```

## Boolean Assertions

```php
$this->assertTrue($value);
$this->assertFalse($value);

// Alias
$this->assertThat($value, $this->isTrue());
$this->assertThat($value, $this->isFalse());
```

## Null Assertions

```php
$this->assertNull($value);
$this->assertNotNull($value);
```

## Type Assertions

```php
// Type checking
$this->assertIsArray($value);
$this->assertIsBool($value);
$this->assertIsFloat($value);
$this->assertIsInt($value);
$this->assertIsNumeric($value);
$this->assertIsObject($value);
$this->assertIsString($value);
$this->assertIsCallable($value);
$this->assertIsIterable($value);

// Not type
$this->assertIsNotArray($value);
$this->assertIsNotString($value);

// Instance of class
$this->assertInstanceOf(ClassName::class, $object);
$this->assertNotInstanceOf(OtherClass::class, $object);
```

## Array Assertions

```php
// Contains value
$this->assertContains('item', $array);
$this->assertNotContains('item', $array);

// Contains only type
$this->assertContainsOnly('string', $array);
$this->assertContainsOnlyInstancesOf(Item::class, $array);

// Has key
$this->assertArrayHasKey('key', $array);
$this->assertArrayNotHasKey('key', $array);

// Count
$this->assertCount(3, $array);
$this->assertNotCount(0, $array);

// Empty
$this->assertEmpty($array);
$this->assertNotEmpty($array);

// Same size
$this->assertSameSize($expected, $actual);
```

## String Assertions

```php
// Contains
$this->assertStringContainsString('needle', $haystack);
$this->assertStringNotContainsString('needle', $haystack);

// Case insensitive
$this->assertStringContainsStringIgnoringCase('NEEDLE', $haystack);

// Starts/Ends with
$this->assertStringStartsWith('prefix', $string);
$this->assertStringEndsWith('suffix', $string);
$this->assertStringStartsNotWith('wrong', $string);
$this->assertStringEndsNotWith('wrong', $string);

// Regex
$this->assertMatchesRegularExpression('/pattern/', $string);
$this->assertDoesNotMatchRegularExpression('/pattern/', $string);

// JSON
$this->assertJson($string);  // Valid JSON
$this->assertJsonStringEqualsJsonString($expected, $actual);
$this->assertJsonStringEqualsJsonFile('expected.json', $actual);
```

## Numeric Assertions

```php
// Greater/Less than
$this->assertGreaterThan(5, $value);
$this->assertGreaterThanOrEqual(5, $value);
$this->assertLessThan(10, $value);
$this->assertLessThanOrEqual(10, $value);

// Finite/Infinite/NaN
$this->assertFinite($value);
$this->assertInfinite($value);
$this->assertNan($value);
```

## Object Assertions

```php
// Has attribute
$this->assertObjectHasProperty('property', $object);
$this->assertObjectNotHasProperty('property', $object);

// Same object
$this->assertSame($object1, $object2);  // Same instance
$this->assertEquals($object1, $object2);  // Same values
```

## Exception Assertions

```php
// Expect exception
$this->expectException(InvalidArgumentException::class);
$this->service->methodThatThrows();

// Expect exception message
$this->expectExceptionMessage('Expected error message');
$this->expectExceptionMessageMatches('/pattern/');

// Expect exception code
$this->expectExceptionCode(404);

// Combined
public function testThrowsException(): void {
  $this->expectException(\RuntimeException::class);
  $this->expectExceptionMessage('Something went wrong');
  $this->expectExceptionCode(500);

  $this->service->riskyOperation();
}

// Using closure (PHPUnit 10+)
$this->expectException(InvalidArgumentException::class);
$this->service->validate(null);
```

## File Assertions

```php
// File exists
$this->assertFileExists('/path/to/file');
$this->assertFileDoesNotExist('/path/to/file');

// Directory exists
$this->assertDirectoryExists('/path/to/dir');
$this->assertDirectoryDoesNotExist('/path/to/dir');

// Readable/Writable
$this->assertFileIsReadable('/path/to/file');
$this->assertFileIsWritable('/path/to/file');

// File equals
$this->assertFileEquals('expected.txt', 'actual.txt');
$this->assertStringEqualsFile('expected.txt', $string);
```

## Custom Assertions

```php
// Using callback
$this->assertThat(
  $value,
  $this->callback(function ($v) {
    return $v > 0 && $v < 100;
  })
);

// Logical combinations
$this->assertThat(
  $value,
  $this->logicalAnd(
    $this->greaterThan(0),
    $this->lessThan(100)
  )
);

$this->assertThat(
  $value,
  $this->logicalOr(
    $this->isNull(),
    $this->isInstanceOf(SomeClass::class)
  )
);
```

## Soft Assertions (Multiple)

```php
public function testMultipleConditions(): void {
  $result = $this->service->process();

  // All assertions run, failure shows all
  $this->assertIsArray($result);
  $this->assertArrayHasKey('status', $result);
  $this->assertArrayHasKey('data', $result);
  $this->assertEquals('success', $result['status']);
  $this->assertNotEmpty($result['data']);
}
```

## Assertion Messages

```php
// Add custom failure message
$this->assertEquals(
  'expected',
  $actual,
  'Custom message shown on failure'
);

$this->assertTrue(
  $condition,
  sprintf('Expected %s to be valid', $input)
);
```
