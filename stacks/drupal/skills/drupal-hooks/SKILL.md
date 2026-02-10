---
name: drupal-hooks
description: Use this skill when implementing Drupal hooks, altering forms, modifying entities, or extending Drupal behavior. Trigger phrases include "hook", "alter", "form alter", "entity presave", "preprocess", "event subscriber".
allowed-tools: Read, Write, Edit, Glob, Grep
---

# Drupal Hooks Skill

Comprehensive knowledge of Drupal 10/11 hooks and event subscribers.

## Hook Implementation

Hooks are implemented in `<module>.module` files:

```php
<?php

/**
 * @file
 * Hook implementations for the module.
 */

use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Entity\EntityInterface;
use Drupal\node\NodeInterface;
```

## Common Hooks

### Form Hooks

```php
/**
 * Implements hook_form_alter().
 */
function mymodule_form_alter(&$form, FormStateInterface $form_state, $form_id) {
  // Alter any form
}

/**
 * Implements hook_form_FORM_ID_alter().
 */
function mymodule_form_user_login_form_alter(&$form, FormStateInterface $form_state, $form_id) {
  // Alter specific form
  $form['name']['#description'] = t('Enter your email address.');
}
```

### Entity Hooks

```php
/**
 * Implements hook_entity_presave().
 */
function mymodule_entity_presave(EntityInterface $entity) {
  // Before any entity is saved
}

/**
 * Implements hook_ENTITY_TYPE_presave().
 */
function mymodule_node_presave(NodeInterface $node) {
  // Before node is saved
  if ($node->bundle() === 'article') {
    // Set default values, validate, etc.
  }
}

/**
 * Implements hook_entity_insert().
 */
function mymodule_entity_insert(EntityInterface $entity) {
  // After entity is created
}

/**
 * Implements hook_entity_update().
 */
function mymodule_entity_update(EntityInterface $entity) {
  // After entity is updated
}

/**
 * Implements hook_entity_delete().
 */
function mymodule_entity_delete(EntityInterface $entity) {
  // After entity is deleted
}

/**
 * Implements hook_entity_view().
 */
function mymodule_entity_view(array &$build, EntityInterface $entity, EntityViewDisplayInterface $display, $view_mode) {
  // Modify entity render array
}

/**
 * Implements hook_entity_view_alter().
 */
function mymodule_entity_view_alter(array &$build, EntityInterface $entity, EntityViewDisplayInterface $display) {
  // Alter entity render array after all modules have built it
}
```

### Access Hooks

```php
/**
 * Implements hook_node_access().
 */
function mymodule_node_access(NodeInterface $node, $op, AccountInterface $account) {
  if ($node->bundle() === 'private' && $op === 'view') {
    return AccessResult::forbidden()->cachePerUser();
  }
  return AccessResult::neutral();
}

/**
 * Implements hook_entity_access().
 */
function mymodule_entity_access(EntityInterface $entity, $operation, AccountInterface $account) {
  // Generic entity access
  return AccessResult::neutral();
}
```

### View Hooks

```php
/**
 * Implements hook_views_pre_render().
 */
function mymodule_views_pre_render(ViewExecutable $view) {
  if ($view->id() === 'my_view') {
    // Modify view before rendering
  }
}

/**
 * Implements hook_views_query_alter().
 */
function mymodule_views_query_alter(ViewExecutable $view, QueryPluginBase $query) {
  // Modify view query
}

/**
 * Implements hook_views_data().
 */
function mymodule_views_data() {
  // Expose custom tables/fields to Views
  $data = [];
  $data['mymodule_table']['table']['group'] = t('My Module');
  $data['mymodule_table']['table']['base'] = [
    'field' => 'id',
    'title' => t('My Module Data'),
  ];
  return $data;
}

/**
 * Implements hook_views_data_alter().
 */
function mymodule_views_data_alter(array &$data) {
  // Alter existing Views data
}
```

### Theme Hooks

```php
/**
 * Implements hook_theme().
 */
function mymodule_theme($existing, $type, $theme, $path) {
  return [
    'mymodule_item' => [
      'variables' => [
        'title' => NULL,
        'content' => NULL,
        'attributes' => [],
      ],
    ],
  ];
}

/**
 * Implements hook_preprocess_HOOK().
 */
function mymodule_preprocess_node(&$variables) {
  $node = $variables['node'];
  $variables['custom_class'] = 'node-' . $node->bundle();
}

/**
 * Implements hook_theme_suggestions_HOOK_alter().
 */
function mymodule_theme_suggestions_node_alter(array &$suggestions, array $variables) {
  $node = $variables['elements']['#node'];
  $suggestions[] = 'node__' . $node->bundle() . '__custom';
}
```

### Mail Hooks

```php
/**
 * Implements hook_mail().
 */
function mymodule_mail($key, &$message, $params) {
  switch ($key) {
    case 'notification':
      $message['subject'] = t('Notification');
      $message['body'][] = $params['message'];
      break;
  }
}

/**
 * Implements hook_mail_alter().
 */
function mymodule_mail_alter(&$message) {
  // Modify outgoing mail
}
```

### Cron Hooks

```php
/**
 * Implements hook_cron().
 */
function mymodule_cron() {
  // Run periodic tasks
  // Keep it fast - long tasks should use Queue API
}
```

### Install/Update Hooks

```php
/**
 * Implements hook_install().
 */
function mymodule_install() {
  // Run when module is installed
}

/**
 * Implements hook_uninstall().
 */
function mymodule_uninstall() {
  // Cleanup when module is uninstalled
}

/**
 * Implements hook_update_N().
 */
function mymodule_update_10001(&$sandbox) {
  // Database update - runs via drush updb
  // Number format: <core_version><sequence>
}

/**
 * Implements hook_requirements().
 */
function mymodule_requirements($phase) {
  $requirements = [];
  if ($phase === 'runtime') {
    $requirements['mymodule'] = [
      'title' => t('My Module'),
      'value' => t('Configured'),
      'severity' => REQUIREMENT_OK,
    ];
  }
  return $requirements;
}
```

### Menu/Routing Hooks

```php
/**
 * Implements hook_menu_links_discovered_alter().
 */
function mymodule_menu_links_discovered_alter(&$links) {
  // Alter menu links
}

/**
 * Implements hook_local_tasks_alter().
 */
function mymodule_local_tasks_alter(&$local_tasks) {
  // Alter local task tabs
}
```

### Page Hooks

```php
/**
 * Implements hook_page_attachments().
 */
function mymodule_page_attachments(array &$attachments) {
  // Add CSS/JS libraries to pages
  $attachments['#attached']['library'][] = 'mymodule/global';
}

/**
 * Implements hook_page_attachments_alter().
 */
function mymodule_page_attachments_alter(array &$attachments) {
  // Alter page attachments added by other modules
}
```

## Event Subscribers (Preferred in Drupal 10/11)

Modern Drupal prefers event subscribers over hooks for many use cases.

### Service Definition

In `mymodule.services.yml`:
```yaml
services:
  mymodule.event_subscriber:
    class: Drupal\mymodule\EventSubscriber\MyEventSubscriber
    tags:
      - { name: event_subscriber }
```

### Event Subscriber Class

```php
<?php

namespace Drupal\mymodule\EventSubscriber;

use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\Event\ResponseEvent;
use Symfony\Component\HttpKernel\KernelEvents;

class MyEventSubscriber implements EventSubscriberInterface {

  public static function getSubscribedEvents() {
    return [
      KernelEvents::REQUEST => ['onRequest', 100],
      KernelEvents::RESPONSE => ['onResponse', 0],
    ];
  }

  public function onRequest(RequestEvent $event) {
    // Handle request event
  }

  public function onResponse(ResponseEvent $event) {
    // Handle response event
  }

}
```

### Common Events

| Event | Class | Use Case |
|-------|-------|----------|
| `KernelEvents::REQUEST` | `RequestEvent` | HTTP request handling |
| `KernelEvents::RESPONSE` | `ResponseEvent` | Before response sent |
| `KernelEvents::EXCEPTION` | `ExceptionEvent` | Exception handling |
| `KernelEvents::TERMINATE` | `TerminateEvent` | After response sent |
| `ConfigEvents::SAVE` | `ConfigCrudEvent` | Config saved |
| `ConfigEvents::DELETE` | `ConfigCrudEvent` | Config deleted |
| `EntityHookEvents::ENTITY_PRESAVE` | `EntityEvent` | Entity presave (D11) |

### Config Event Subscriber

```php
<?php

namespace Drupal\mymodule\EventSubscriber;

use Drupal\Core\Config\ConfigCrudEvent;
use Drupal\Core\Config\ConfigEvents;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;

class ConfigSubscriber implements EventSubscriberInterface {

  public static function getSubscribedEvents() {
    return [
      ConfigEvents::SAVE => ['onConfigSave'],
    ];
  }

  public function onConfigSave(ConfigCrudEvent $event) {
    $config = $event->getConfig();
    if ($config->getName() === 'mymodule.settings') {
      // React to config changes
    }
  }

}
```

## Hook Attributes (Drupal 11+)

Drupal 11 introduces hook attributes as an alternative to procedural hooks:

```php
<?php

namespace Drupal\mymodule\Hook;

use Drupal\Core\Hook\Attribute\Hook;

class MyModuleHooks {

  #[Hook('form_alter')]
  public function formAlter(&$form, $form_state, $form_id): void {
    // Alter forms using OOP approach
  }

  #[Hook('cron')]
  public function cron(): void {
    // Run periodic tasks
  }

}
```

## Finding Existing Hooks

```bash
# Search for hook implementations in custom modules
grep -r "function mymodule_.*_form_alter" modules/custom/

# Find all hooks in a module
grep -E "^function <module>_" modules/custom/<module>/<module>.module

# Find all event subscribers
grep -r "EventSubscriberInterface" modules/custom/
```

## Hook Weight

Control execution order via module weight in the system.module table or by implementing `hook_module_implements_alter()`:

```php
/**
 * Implements hook_module_implements_alter().
 */
function mymodule_module_implements_alter(&$implementations, $hook) {
  if ($hook === 'form_alter') {
    // Move mymodule to the end so it runs last
    $group = $implementations['mymodule'];
    unset($implementations['mymodule']);
    $implementations['mymodule'] = $group;
  }
}
```
