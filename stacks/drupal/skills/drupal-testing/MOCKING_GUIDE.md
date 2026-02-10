# Mocking Guide

Comprehensive guide to mocking in PHPUnit tests for Drupal projects.

## Two Mocking Approaches

Drupal projects commonly use both PHPUnit's `createMock()` and Prophecy's `prophesize()`.

### PHPUnit createMock()

**Best for:** Simple mocks, return values, basic expectations.

```php
$mock = $this->createMock(SomeClass::class);
$mock->method('getName')->willReturn('test');
$mock->expects($this->once())->method('save');
```

### Prophecy prophesize()

**Best for:** Complex entity mocking, chained calls, Drupal entities.

```php
$prophecy = $this->prophesize(SomeClass::class);
$prophecy->getName()->willReturn('test');
$prophecy->save()->shouldBeCalledOnce();
$mock = $prophecy->reveal();
```

## Common Drupal Mocks

### Database Connection

```php
use Drupal\Core\Database\Connection;
use Drupal\Core\Database\Query\SelectInterface;
use Drupal\Core\Database\StatementInterface;

$statement = $this->createMock(StatementInterface::class);
$statement->method('fetchAll')->willReturn([
  (object) ['id' => 1, 'name' => 'Item 1'],
  (object) ['id' => 2, 'name' => 'Item 2'],
]);

$query = $this->createMock(SelectInterface::class);
$query->method('fields')->willReturnSelf();
$query->method('condition')->willReturnSelf();
$query->method('execute')->willReturn($statement);

$database = $this->createMock(Connection::class);
$database->method('select')->willReturn($query);
```

### Logger

```php
use Drupal\Core\Logger\LoggerChannelInterface;

$logger = $this->createMock(LoggerChannelInterface::class);

// Expect specific log call
$logger->expects($this->once())
  ->method('error')
  ->with($this->stringContains('Error message'));

// Expect any log level
$logger->expects($this->once())
  ->method('log')
  ->with(
    $this->anything(),  // level
    $this->stringContains('message')
  );
```

### Entity Type Manager

```php
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Core\Entity\EntityStorageInterface;
use Drupal\node\NodeInterface;

$node = $this->createMock(NodeInterface::class);
$node->method('id')->willReturn(123);
$node->method('label')->willReturn('Test Node');

$storage = $this->createMock(EntityStorageInterface::class);
$storage->method('load')->with(123)->willReturn($node);
$storage->method('loadMultiple')->willReturn([$node]);

$entityTypeManager = $this->createMock(EntityTypeManagerInterface::class);
$entityTypeManager->method('getStorage')
  ->with('node')
  ->willReturn($storage);
```

### Config Factory

```php
use Drupal\Core\Config\ConfigFactoryInterface;
use Drupal\Core\Config\ImmutableConfig;

$config = $this->createMock(ImmutableConfig::class);
$config->method('get')
  ->willReturnMap([
    ['api_key', 'test-api-key'],
    ['api_url', 'https://api.example.com'],
    ['enabled', TRUE],
  ]);

$configFactory = $this->createMock(ConfigFactoryInterface::class);
$configFactory->method('get')
  ->with('mymodule.settings')
  ->willReturn($config);
```

### Content Entity (Prophecy)

```php
use Drupal\Core\Entity\ContentEntityInterface;
use Drupal\Core\Field\FieldItemListInterface;
use Drupal\Core\TypedData\TypedDataInterface;

// Field value
$fieldItem = $this->prophesize(TypedDataInterface::class);
$fieldItem->getValue()->willReturn([
  'value' => 'Field content',
  'format' => 'full_html',
]);

// Field list
$fieldList = $this->prophesize(FieldItemListInterface::class);
$fieldList->isEmpty()->willReturn(FALSE);
$fieldList->first()->willReturn($fieldItem->reveal());

// Entity
$entity = $this->prophesize(ContentEntityInterface::class);
$entity->hasField('body')->willReturn(TRUE);
$entity->get('body')->willReturn($fieldList->reveal());
$entity->id()->willReturn(123);
$entity->bundle()->willReturn('article');
$entity->getEntityTypeId()->willReturn('node');

// Use in test
$result = $this->service->process($entity->reveal());
```

### Node Entity

```php
use Drupal\node\NodeInterface;

$node = $this->prophesize(NodeInterface::class);
$node->id()->willReturn(123);
$node->bundle()->willReturn('article');
$node->getTitle()->willReturn('Test Title');
$node->isPublished()->willReturn(TRUE);
$node->getOwner()->willReturn($userMock);

$nodeEntity = $node->reveal();
```

### User Entity

```php
use Drupal\user\UserInterface;

$user = $this->prophesize(UserInterface::class);
$user->id()->willReturn(1);
$user->getAccountName()->willReturn('admin');
$user->getEmail()->willReturn('admin@example.com');
$user->hasRole('administrator')->willReturn(TRUE);
$user->isAuthenticated()->willReturn(TRUE);

$userEntity = $user->reveal();
```

### HTTP Client (Guzzle)

```php
use GuzzleHttp\ClientInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\StreamInterface;

$stream = $this->createMock(StreamInterface::class);
$stream->method('getContents')
  ->willReturn('{"status": "success", "data": []}');

$response = $this->createMock(ResponseInterface::class);
$response->method('getStatusCode')->willReturn(200);
$response->method('getBody')->willReturn($stream);

$httpClient = $this->createMock(ClientInterface::class);
$httpClient->method('request')
  ->with('GET', 'https://api.example.com/endpoint')
  ->willReturn($response);
```

### Cache Backend

```php
use Drupal\Core\Cache\CacheBackendInterface;

$cacheItem = (object) [
  'data' => ['cached' => 'data'],
  'expire' => time() + 3600,
];

$cache = $this->createMock(CacheBackendInterface::class);
$cache->method('get')
  ->willReturnMap([
    ['existing_key', $cacheItem],
    ['missing_key', FALSE],
  ]);
$cache->expects($this->once())
  ->method('set')
  ->with('new_key', $this->anything(), $this->anything());
```

## Expectation Methods

### Call Count

```php
$mock->expects($this->never())->method('methodName');
$mock->expects($this->once())->method('methodName');
$mock->expects($this->exactly(3))->method('methodName');
$mock->expects($this->atLeastOnce())->method('methodName');
$mock->expects($this->any())->method('methodName');
```

### Argument Matching

```php
// Exact value
$mock->expects($this->once())
  ->method('process')
  ->with('exact value');

// Any argument
$mock->expects($this->once())
  ->method('process')
  ->with($this->anything());

// String contains
$mock->expects($this->once())
  ->method('log')
  ->with($this->stringContains('error'));

// Callback validation
$mock->expects($this->once())
  ->method('process')
  ->with($this->callback(function ($arg) {
    return is_array($arg) && count($arg) > 0;
  }));

// Multiple arguments
$mock->expects($this->once())
  ->method('save')
  ->with(
    $this->equalTo('key'),
    $this->isType('array'),
    $this->greaterThan(0)
  );
```

### Return Values

```php
// Simple return
$mock->method('getValue')->willReturn('value');

// Return self (fluent interface)
$mock->method('setOption')->willReturnSelf();

// Return based on arguments
$mock->method('get')->willReturnMap([
  ['key1', 'value1'],
  ['key2', 'value2'],
]);

// Return callback
$mock->method('transform')
  ->willReturnCallback(function ($input) {
    return strtoupper($input);
  });

// Throw exception
$mock->method('validate')
  ->willThrowException(new \InvalidArgumentException('Invalid'));

// Return different values on consecutive calls
$mock->method('getNext')
  ->willReturnOnConsecutiveCalls('first', 'second', 'third');
```

## Prophecy Expectations

```php
// Will be called
$prophecy->method()->shouldBeCalled();

// Called specific times
$prophecy->method()->shouldBeCalledOnce();
$prophecy->method()->shouldBeCalledTimes(3);

// Never called
$prophecy->method()->shouldNotBeCalled();

// With arguments
$prophecy->method('arg1', 'arg2')->shouldBeCalled();

// Any argument
use Prophecy\Argument;
$prophecy->method(Argument::any())->willReturn('value');
$prophecy->method(Argument::type('string'))->willReturn('value');
$prophecy->method(Argument::containingString('test'))->willReturn('value');
```
