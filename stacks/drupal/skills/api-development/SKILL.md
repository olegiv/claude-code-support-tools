---
name: api-development
description: Guide for building REST APIs, JSON:API endpoints, and external integrations in Drupal.
---

# API Development Skill

Comprehensive guide for building and consuming APIs in Drupal.

## API Options in Drupal

| Approach | Best For | Authentication |
|----------|----------|----------------|
| **JSON:API** | Standard CRUD on entities | Cookie, Basic, OAuth |
| **REST Resources** | Custom endpoints, complex logic | Cookie, Basic, OAuth |
| **Controllers** | Full control, non-standard responses | Custom |
| **GraphQL** | Complex queries, mobile apps | Token-based |

---

## 1. JSON:API (Built-in)

### Enable and Configure

```bash
# Enable modules
./vendor/bin/drush en jsonapi jsonapi_extras -y
```

### Default Endpoints

```
GET    /jsonapi/node/article          # List articles
GET    /jsonapi/node/article/{uuid}   # Single article
POST   /jsonapi/node/article          # Create article
PATCH  /jsonapi/node/article/{uuid}   # Update article
DELETE /jsonapi/node/article/{uuid}   # Delete article
```

### Filtering

```bash
# Filter by field
GET /jsonapi/node/article?filter[status]=1

# Filter by relationship
GET /jsonapi/node/article?filter[uid.id]={user-uuid}

# Multiple conditions
GET /jsonapi/node/article?filter[and-group][group][conjunction]=AND&filter[status][condition][path]=status&filter[status][condition][value]=1&filter[status][condition][memberOf]=and-group

# Include relationships
GET /jsonapi/node/article?include=uid,field_category

# Sparse fieldsets
GET /jsonapi/node/article?fields[node--article]=title,body,created
```

### Permission Configuration

```yaml
# user.role.anonymous.yml
permissions:
  - 'access jsonapi resource list'
```

---

## 2. Custom REST Resources

### Basic REST Resource

```php
<?php

namespace Drupal\mymodule\Plugin\rest\resource;

use Drupal\rest\Plugin\ResourceBase;
use Drupal\rest\ResourceResponse;
use Symfony\Component\DependencyInjection\ContainerInterface;
use Psr\Log\LoggerInterface;

/**
 * Provides a custom data resource.
 *
 * @RestResource(
 *   id = "mymodule_data_resource",
 *   label = @Translation("Custom Data"),
 *   uri_paths = {
 *     "canonical" = "/api/v1/data/{id}",
 *     "create" = "/api/v1/data"
 *   }
 * )
 */
class DataResource extends ResourceBase {

  /**
   * Responds to GET requests.
   */
  public function get(string $id): ResourceResponse {
    $data = $this->loadData($id);

    if (!$data) {
      return new ResourceResponse(['error' => 'Not found'], 404);
    }

    $response = new ResourceResponse($data, 200);

    // Add cache metadata
    $response->addCacheableDependency($data);
    $response->getCacheableMetadata()
      ->addCacheTags(['mymodule_data:' . $id])
      ->addCacheContexts(['user.permissions']);

    return $response;
  }

  /**
   * Responds to POST requests.
   */
  public function post(array $data): ResourceResponse {
    // Validate input
    if (empty($data['title'])) {
      return new ResourceResponse([
        'error' => 'Validation failed',
        'details' => ['title' => 'Title is required'],
      ], 400);
    }

    // Create entity
    $result = $this->createData($data);

    return new ResourceResponse($result, 201);
  }

  /**
   * Responds to PATCH requests.
   */
  public function patch(string $id, array $data): ResourceResponse {
    $existing = $this->loadData($id);

    if (!$existing) {
      return new ResourceResponse(['error' => 'Not found'], 404);
    }

    $result = $this->updateData($id, $data);

    return new ResourceResponse($result, 200);
  }

  /**
   * Responds to DELETE requests.
   */
  public function delete(string $id): ResourceResponse {
    $existing = $this->loadData($id);

    if (!$existing) {
      return new ResourceResponse(['error' => 'Not found'], 404);
    }

    $this->deleteData($id);

    return new ResourceResponse(NULL, 204);
  }

}
```

### REST Resource Configuration

```yaml
# rest.resource.mymodule_data_resource.yml
id: mymodule_data_resource
plugin_id: mymodule_data_resource
granularity: resource
configuration:
  methods:
    - GET
    - POST
    - PATCH
    - DELETE
  formats:
    - json
  authentication:
    - cookie
    - basic_auth
```

---

## 3. Controller-Based API

### API Controller

```php
<?php

namespace Drupal\mymodule\Controller;

use Drupal\Core\Controller\ControllerBase;
use Drupal\Core\Cache\CacheableJsonResponse;
use Drupal\Core\Cache\CacheableMetadata;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\DependencyInjection\ContainerInterface;

/**
 * API controller for custom data.
 */
class ApiController extends ControllerBase {

  /**
   * The data service.
   */
  protected $dataService;

  /**
   * {@inheritdoc}
   */
  public static function create(ContainerInterface $container): static {
    $instance = parent::create($container);
    $instance->dataService = $container->get('mymodule.data_service');
    return $instance;
  }

  /**
   * List endpoint with caching.
   */
  public function list(Request $request): CacheableJsonResponse {
    // Parse query parameters
    $page = (int) $request->query->get('page', 0);
    $limit = min((int) $request->query->get('limit', 20), 100);
    $filter = $request->query->get('filter', '');

    // Get data
    $items = $this->dataService->getList($page, $limit, $filter);
    $total = $this->dataService->getCount($filter);

    // Build response
    $data = [
      'data' => $items,
      'meta' => [
        'page' => $page,
        'limit' => $limit,
        'total' => $total,
        'pages' => ceil($total / $limit),
      ],
      'links' => $this->buildPaginationLinks($request, $page, $limit, $total),
    ];

    $response = new CacheableJsonResponse($data);

    // Add cache metadata
    $cacheMetadata = new CacheableMetadata();
    $cacheMetadata->addCacheTags(['mymodule_data_list']);
    $cacheMetadata->addCacheContexts(['url.query_args']);
    $cacheMetadata->setCacheMaxAge(300); // 5 minutes
    $response->addCacheableDependency($cacheMetadata);

    return $response;
  }

  /**
   * Single item endpoint.
   */
  public function get(string $id): JsonResponse {
    $item = $this->dataService->get($id);

    if (!$item) {
      return new JsonResponse([
        'error' => [
          'code' => 'NOT_FOUND',
          'message' => 'Resource not found',
        ],
      ], 404);
    }

    return new JsonResponse(['data' => $item]);
  }

  /**
   * Create endpoint.
   */
  public function create(Request $request): JsonResponse {
    $data = json_decode($request->getContent(), TRUE);

    // Validate
    $errors = $this->validate($data);
    if ($errors) {
      return new JsonResponse([
        'error' => [
          'code' => 'VALIDATION_ERROR',
          'message' => 'Validation failed',
          'details' => $errors,
        ],
      ], 400);
    }

    // Create
    $item = $this->dataService->create($data);

    return new JsonResponse(['data' => $item], 201);
  }

  /**
   * Build pagination links.
   */
  protected function buildPaginationLinks(
    Request $request,
    int $page,
    int $limit,
    int $total
  ): array {
    $baseUrl = $request->getSchemeAndHttpHost() . $request->getPathInfo();
    $pages = ceil($total / $limit);

    $links = [
      'self' => $baseUrl . '?page=' . $page . '&limit=' . $limit,
      'first' => $baseUrl . '?page=0&limit=' . $limit,
      'last' => $baseUrl . '?page=' . max(0, $pages - 1) . '&limit=' . $limit,
    ];

    if ($page > 0) {
      $links['prev'] = $baseUrl . '?page=' . ($page - 1) . '&limit=' . $limit;
    }

    if ($page < $pages - 1) {
      $links['next'] = $baseUrl . '?page=' . ($page + 1) . '&limit=' . $limit;
    }

    return $links;
  }

}
```

### Routing

```yaml
# mymodule.routing.yml
mymodule.api.list:
  path: '/api/v1/items'
  defaults:
    _controller: '\Drupal\mymodule\Controller\ApiController::list'
  methods: [GET]
  requirements:
    _permission: 'access content'
  options:
    no_cache: FALSE

mymodule.api.get:
  path: '/api/v1/items/{id}'
  defaults:
    _controller: '\Drupal\mymodule\Controller\ApiController::get'
  methods: [GET]
  requirements:
    _permission: 'access content'
    id: '[a-zA-Z0-9_-]+'

mymodule.api.create:
  path: '/api/v1/items'
  defaults:
    _controller: '\Drupal\mymodule\Controller\ApiController::create'
  methods: [POST]
  requirements:
    _permission: 'create mymodule_data'
```

---

## 4. HTTP Client for External APIs

### Service Definition

```yaml
# mymodule.services.yml
services:
  mymodule.external_client:
    class: Drupal\mymodule\Client\ExternalApiClient
    arguments:
      - '@http_client'
      - '@logger.factory'
      - '@config.factory'
      - '@cache.default'
```

### HTTP Client Implementation

```php
<?php

namespace Drupal\mymodule\Client;

use Drupal\Core\Cache\CacheBackendInterface;
use Drupal\Core\Config\ConfigFactoryInterface;
use Drupal\Core\Logger\LoggerChannelFactoryInterface;
use GuzzleHttp\ClientInterface;
use GuzzleHttp\Exception\GuzzleException;
use Psr\Log\LoggerInterface;

/**
 * Client for external API integration.
 */
class ExternalApiClient {

  protected ClientInterface $httpClient;
  protected LoggerInterface $logger;
  protected string $baseUrl;
  protected string $apiKey;
  protected CacheBackendInterface $cache;

  public function __construct(
    ClientInterface $http_client,
    LoggerChannelFactoryInterface $logger_factory,
    ConfigFactoryInterface $config_factory,
    CacheBackendInterface $cache,
  ) {
    $this->httpClient = $http_client;
    $this->logger = $logger_factory->get('mymodule');
    $this->cache = $cache;

    $config = $config_factory->get('mymodule.settings');
    $this->baseUrl = $config->get('external_api_url');
    $this->apiKey = $config->get('external_api_key');
  }

  /**
   * GET request with caching.
   */
  public function get(string $endpoint, array $query = []): ?array {
    $cacheKey = 'mymodule_api:' . md5($endpoint . serialize($query));

    // Check cache
    if ($cached = $this->cache->get($cacheKey)) {
      return $cached->data;
    }

    try {
      $response = $this->httpClient->request('GET', $this->baseUrl . $endpoint, [
        'query' => $query,
        'headers' => $this->getHeaders(),
        'timeout' => 30,
      ]);

      $data = json_decode($response->getBody()->getContents(), TRUE);

      // Cache for 5 minutes
      $this->cache->set($cacheKey, $data, time() + 300);

      return $data;
    }
    catch (GuzzleException $e) {
      $this->logger->error('API request failed: @message', [
        '@message' => $e->getMessage(),
      ]);
      return NULL;
    }
  }

  /**
   * POST request.
   */
  public function post(string $endpoint, array $data): ?array {
    try {
      $response = $this->httpClient->request('POST', $this->baseUrl . $endpoint, [
        'json' => $data,
        'headers' => $this->getHeaders(),
        'timeout' => 30,
      ]);

      return json_decode($response->getBody()->getContents(), TRUE);
    }
    catch (GuzzleException $e) {
      $this->logger->error('API POST failed: @message', [
        '@message' => $e->getMessage(),
      ]);
      return NULL;
    }
  }

  /**
   * Get request headers.
   */
  protected function getHeaders(): array {
    return [
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
      'Authorization' => 'Bearer ' . $this->apiKey,
    ];
  }

}
```

---

## 5. Authentication

### Cookie Authentication (default)

```bash
# Login
curl -c cookies.txt -X POST "https://example.com/user/login" \
  -H "Content-Type: application/json" \
  -d '{"name":"user","pass":"password"}'

# Use authenticated endpoint
curl -b cookies.txt "https://example.com/api/v1/data"
```

### Basic Auth

```bash
# Enable module
./vendor/bin/drush en basic_auth -y

# Request with basic auth
curl -u username:password "https://example.com/api/v1/data"
```

### Simple OAuth (OAuth 2.0)

```bash
# Install
composer require drupal/simple_oauth
./vendor/bin/drush en simple_oauth -y

# Generate keys
./vendor/bin/drush simple-oauth:generate-keys ../keys
```

---

## 6. API Response Standards

### Success Response

```json
{
  "data": {
    "id": "123",
    "type": "article",
    "attributes": {
      "title": "Example",
      "body": "Content..."
    }
  },
  "meta": {
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

### List Response

```json
{
  "data": [],
  "meta": {
    "page": 0,
    "limit": 20,
    "total": 100,
    "pages": 5
  },
  "links": {
    "self": "/api/v1/items?page=0",
    "first": "/api/v1/items?page=0",
    "last": "/api/v1/items?page=4",
    "next": "/api/v1/items?page=1"
  }
}
```

### Error Response

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": [
      {"field": "email", "message": "Invalid email format"},
      {"field": "title", "message": "Title is required"}
    ]
  }
}
```

### HTTP Status Codes

| Code | Use For |
|------|---------|
| 200 | Success (GET, PATCH) |
| 201 | Created (POST) |
| 204 | No Content (DELETE) |
| 400 | Bad Request (validation) |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 422 | Unprocessable Entity |
| 500 | Server Error |

---

## 7. Testing APIs

```bash
# GET request
curl -X GET "https://example.com/api/v1/items" \
  -H "Accept: application/json"

# POST with JSON
curl -X POST "https://example.com/api/v1/items" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"title": "Test", "body": "Content"}'

# With authentication
curl -u user:pass -X GET "https://example.com/api/v1/items"

# JSON:API
curl -X GET "https://example.com/jsonapi/node/article" \
  -H "Accept: application/vnd.api+json"
```
