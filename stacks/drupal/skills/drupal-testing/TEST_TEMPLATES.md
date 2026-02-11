# Test Templates

Comprehensive templates for PHPUnit tests in Drupal projects.

## Service Test Template

For testing service classes with dependency injection:

```php
<?php

namespace Drupal\Tests\<module>\Unit;

use Drupal\Tests\UnitTestCase;
use Drupal\<module>\Service\ExampleService;
use Drupal\Core\Database\Connection;
use Drupal\Core\Logger\LoggerChannelInterface;
use PHPUnit\Framework\MockObject\MockObject;

/**
 * Tests for ExampleService.
 *
 * @coversDefaultClass \Drupal\<module>\Service\ExampleService
 * @group <module>
 */
class ExampleServiceTest extends UnitTestCase {

  /**
   * The service under test.
   */
  private ExampleService $service;

  /**
   * @var \Drupal\Core\Database\Connection|\PHPUnit\Framework\MockObject\MockObject
   */
  private Connection|MockObject $database;

  /**
   * @var \Drupal\Core\Logger\LoggerChannelInterface|\PHPUnit\Framework\MockObject\MockObject
   */
  private LoggerChannelInterface|MockObject $logger;

  /**
   * {@inheritdoc}
   */
  protected function setUp(): void {
    parent::setUp();

    $this->database = $this->createMock(Connection::class);
    $this->logger = $this->createMock(LoggerChannelInterface::class);

    $this->service = new ExampleService(
      $this->database,
      $this->logger
    );
  }

  /**
   * Tests getData returns array.
   *
   * @covers ::getData
   */
  public function testGetDataReturnsArray(): void {
    $result = $this->service->getData();
    $this->assertIsArray($result);
  }

  /**
   * Tests getData with empty result.
   *
   * @covers ::getData
   */
  public function testGetDataReturnsEmptyArrayWhenNoData(): void {
    $result = $this->service->getData();
    $this->assertEmpty($result);
  }

}
```

## Data Provider Template

For testing multiple input/output combinations:

```php
<?php

namespace Drupal\Tests\<module>\Unit;

use Drupal\Tests\UnitTestCase;
use Drupal\<module>\Helper\StringHelper;
use Generator;

/**
 * Tests for StringHelper.
 *
 * @coversDefaultClass \Drupal\<module>\Helper\StringHelper
 * @group <module>
 */
class StringHelperTest extends UnitTestCase {

  /**
   * The helper under test.
   */
  private StringHelper $helper;

  /**
   * {@inheritdoc}
   */
  protected function setUp(): void {
    parent::setUp();
    $this->helper = new StringHelper();
  }

  /**
   * Tests formatString with various inputs.
   *
   * @dataProvider stringProvider
   * @covers ::formatString
   */
  public function testFormatString(string $input, string $expected): void {
    $result = $this->helper->formatString($input);
    $this->assertEquals($expected, $result);
  }

  /**
   * Data provider for testFormatString.
   *
   * @return \Generator
   */
  public function stringProvider(): Generator {
    yield 'empty string' => [
      'input' => '',
      'expected' => '',
    ];

    yield 'simple string' => [
      'input' => 'hello',
      'expected' => 'Hello',
    ];

    yield 'string with spaces' => [
      'input' => 'hello world',
      'expected' => 'Hello World',
    ];

    yield 'already capitalized' => [
      'input' => 'HELLO',
      'expected' => 'Hello',
    ];

    yield 'special characters' => [
      'input' => 'hello-world_test',
      'expected' => 'Hello-world_test',
    ];
  }

}
```

## Exception Testing Template

For testing error conditions and exceptions:

```php
<?php

namespace Drupal\Tests\<module>\Unit;

use Drupal\Tests\UnitTestCase;
use Drupal\<module>\Service\ValidationService;
use InvalidArgumentException;

/**
 * Tests for ValidationService.
 *
 * @coversDefaultClass \Drupal\<module>\Service\ValidationService
 * @group <module>
 */
class ValidationServiceTest extends UnitTestCase {

  /**
   * The service under test.
   */
  private ValidationService $service;

  /**
   * {@inheritdoc}
   */
  protected function setUp(): void {
    parent::setUp();
    $this->service = new ValidationService();
  }

  /**
   * Tests validate throws exception for null input.
   *
   * @covers ::validate
   */
  public function testValidateThrowsExceptionForNullInput(): void {
    $this->expectException(InvalidArgumentException::class);
    $this->expectExceptionMessage('Input cannot be null');

    $this->service->validate(null);
  }

  /**
   * Tests validate throws exception for empty string.
   *
   * @covers ::validate
   */
  public function testValidateThrowsExceptionForEmptyString(): void {
    $this->expectException(InvalidArgumentException::class);
    $this->expectExceptionMessage('Input cannot be empty');

    $this->service->validate('');
  }

  /**
   * Tests validate returns true for valid input.
   *
   * @covers ::validate
   */
  public function testValidateReturnsTrueForValidInput(): void {
    $result = $this->service->validate('valid input');
    $this->assertTrue($result);
  }

}
```

## Entity/Field Mocking Template (Prophecy)

For testing code that interacts with Drupal entities:

```php
<?php

namespace Drupal\Tests\<module>\Unit;

use Drupal\Tests\UnitTestCase;
use Drupal\<module>\Service\EntityProcessor;
use Drupal\Core\Entity\ContentEntityInterface;
use Drupal\Core\Field\FieldItemListInterface;
use Drupal\Core\TypedData\TypedDataInterface;
use Prophecy\Prophecy\ObjectProphecy;

/**
 * Tests for EntityProcessor.
 *
 * @coversDefaultClass \Drupal\<module>\Service\EntityProcessor
 * @group <module>
 */
class EntityProcessorTest extends UnitTestCase {

  /**
   * The service under test.
   */
  private EntityProcessor $processor;

  /**
   * {@inheritdoc}
   */
  protected function setUp(): void {
    parent::setUp();
    $this->processor = new EntityProcessor();
  }

  /**
   * Tests processEntity with valid field.
   *
   * @covers ::processEntity
   */
  public function testProcessEntityWithValidField(): void {
    // Create field value mock
    $fieldValue = [
      'value' => 'test content',
      'format' => 'full_html',
    ];

    $field = $this->prophesize(TypedDataInterface::class);
    $field->getValue()->willReturn($fieldValue);

    $fieldList = $this->prophesize(FieldItemListInterface::class);
    $fieldList->isEmpty()->willReturn(FALSE);
    $fieldList->first()->willReturn($field->reveal());

    $entity = $this->prophesize(ContentEntityInterface::class);
    $entity->hasField('body')->willReturn(TRUE);
    $entity->get('body')->willReturn($fieldList->reveal());

    $result = $this->processor->processEntity($entity->reveal(), 'body');

    $this->assertEquals('test content', $result);
  }

  /**
   * Tests processEntity with missing field.
   *
   * @covers ::processEntity
   */
  public function testProcessEntityWithMissingField(): void {
    $entity = $this->prophesize(ContentEntityInterface::class);
    $entity->hasField('nonexistent')->willReturn(FALSE);
    $entity->getEntityTypeId()->willReturn('node');
    $entity->bundle()->willReturn('article');

    $this->expectException(\Exception::class);

    $this->processor->processEntity($entity->reveal(), 'nonexistent');
  }

  /**
   * Tests processEntity with empty field.
   *
   * @covers ::processEntity
   */
  public function testProcessEntityWithEmptyField(): void {
    $fieldList = $this->prophesize(FieldItemListInterface::class);
    $fieldList->isEmpty()->willReturn(TRUE);

    $entity = $this->prophesize(ContentEntityInterface::class);
    $entity->hasField('body')->willReturn(TRUE);
    $entity->get('body')->willReturn($fieldList->reveal());

    $result = $this->processor->processEntity($entity->reveal(), 'body');

    $this->assertNull($result);
  }

}
```

## Mock Interaction Verification Template

For testing that dependencies are called correctly:

```php
<?php

namespace Drupal\Tests\<module>\Unit;

use Drupal\Tests\UnitTestCase;
use Drupal\<module>\Service\CacheService;
use Drupal\Core\Cache\CacheBackendInterface;
use Drupal\Core\Logger\LoggerChannelInterface;
use PHPUnit\Framework\MockObject\MockObject;

/**
 * Tests for CacheService.
 *
 * @coversDefaultClass \Drupal\<module>\Service\CacheService
 * @group <module>
 */
class CacheServiceTest extends UnitTestCase {

  /**
   * The service under test.
   */
  private CacheService $service;

  /**
   * @var \Drupal\Core\Cache\CacheBackendInterface|\PHPUnit\Framework\MockObject\MockObject
   */
  private CacheBackendInterface|MockObject $cache;

  /**
   * @var \Drupal\Core\Logger\LoggerChannelInterface|\PHPUnit\Framework\MockObject\MockObject
   */
  private LoggerChannelInterface|MockObject $logger;

  /**
   * {@inheritdoc}
   */
  protected function setUp(): void {
    parent::setUp();

    $this->cache = $this->createMock(CacheBackendInterface::class);
    $this->logger = $this->createMock(LoggerChannelInterface::class);

    $this->service = new CacheService($this->cache, $this->logger);
  }

  /**
   * Tests get returns cached value when exists.
   *
   * @covers ::get
   */
  public function testGetReturnsCachedValue(): void {
    $cacheItem = (object) ['data' => 'cached value'];

    $this->cache
      ->expects($this->once())
      ->method('get')
      ->with('cache_key')
      ->willReturn($cacheItem);

    $result = $this->service->get('cache_key');

    $this->assertEquals('cached value', $result);
  }

  /**
   * Tests get returns null and logs when cache miss.
   *
   * @covers ::get
   */
  public function testGetReturnsNullOnCacheMiss(): void {
    $this->cache
      ->expects($this->once())
      ->method('get')
      ->with('missing_key')
      ->willReturn(FALSE);

    $this->logger
      ->expects($this->once())
      ->method('debug')
      ->with($this->stringContains('Cache miss'));

    $result = $this->service->get('missing_key');

    $this->assertNull($result);
  }

  /**
   * Tests set stores value in cache.
   *
   * @covers ::set
   */
  public function testSetStoresValueInCache(): void {
    $this->cache
      ->expects($this->once())
      ->method('set')
      ->with(
        'cache_key',
        'value to cache',
        $this->greaterThan(time())
      );

    $this->service->set('cache_key', 'value to cache');
  }

  /**
   * Tests clear removes value from cache.
   *
   * @covers ::clear
   */
  public function testClearRemovesFromCache(): void {
    $this->cache
      ->expects($this->once())
      ->method('delete')
      ->with('cache_key');

    $this->logger
      ->expects($this->once())
      ->method('info')
      ->with($this->stringContains('Cleared cache'));

    $this->service->clear('cache_key');
  }

}
```

## HTTP Client/API Testing Template

For testing services that make HTTP requests:

```php
<?php

namespace Drupal\Tests\<module>\Unit;

use Drupal\Tests\UnitTestCase;
use Drupal\<module>\Service\ApiClient;
use Drupal\Core\Logger\LoggerChannelInterface;
use GuzzleHttp\ClientInterface;
use GuzzleHttp\Exception\ClientException;
use PHPUnit\Framework\MockObject\MockObject;
use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\StreamInterface;

/**
 * Tests for ApiClient.
 *
 * @coversDefaultClass \Drupal\<module>\Service\ApiClient
 * @group <module>
 */
class ApiClientTest extends UnitTestCase {

  /**
   * The service under test.
   */
  private ApiClient $client;

  /**
   * @var \GuzzleHttp\ClientInterface|\PHPUnit\Framework\MockObject\MockObject
   */
  private ClientInterface|MockObject $httpClient;

  /**
   * @var \Drupal\Core\Logger\LoggerChannelInterface|\PHPUnit\Framework\MockObject\MockObject
   */
  private LoggerChannelInterface|MockObject $logger;

  /**
   * {@inheritdoc}
   */
  protected function setUp(): void {
    parent::setUp();

    $this->httpClient = $this->createMock(ClientInterface::class);
    $this->logger = $this->createMock(LoggerChannelInterface::class);

    $this->client = new ApiClient($this->httpClient, $this->logger);
  }

  /**
   * Tests fetchData returns parsed response.
   *
   * @covers ::fetchData
   */
  public function testFetchDataReturnsParsedResponse(): void {
    $responseBody = '{"id": 1, "name": "Test"}';

    $stream = $this->createMock(StreamInterface::class);
    $stream->method('getContents')->willReturn($responseBody);

    $response = $this->createMock(ResponseInterface::class);
    $response->method('getBody')->willReturn($stream);
    $response->method('getStatusCode')->willReturn(200);

    $this->httpClient
      ->expects($this->once())
      ->method('request')
      ->with('GET', 'https://api.example.com/data')
      ->willReturn($response);

    $result = $this->client->fetchData('https://api.example.com/data');

    $this->assertEquals(['id' => 1, 'name' => 'Test'], $result);
  }

  /**
   * Tests fetchData handles client exception.
   *
   * @covers ::fetchData
   */
  public function testFetchDataHandlesClientException(): void {
    $request = $this->createMock(RequestInterface::class);
    $response = $this->createMock(ResponseInterface::class);
    $response->method('getStatusCode')->willReturn(400);

    $exception = new ClientException(
      'Bad Request',
      $request,
      $response
    );

    $this->httpClient
      ->method('request')
      ->willThrowException($exception);

    $this->logger
      ->expects($this->once())
      ->method('error');

    $this->expectException(ClientException::class);

    $this->client->fetchData('https://api.example.com/data');
  }

}
```
