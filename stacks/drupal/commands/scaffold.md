---
description: "Generate Drupal boilerplate code"
argument-hint: "<type> <name> [module]"
allowed-tools: Bash, Read, Write, Edit, Glob
---

# Scaffold Drupal Code

Generate boilerplate code for common Drupal components.

## Arguments

`$ARGUMENTS` contains space-separated values:
- First word: Type (controller, service, form, block, plugin, entity, event, subscriber)
- Second word: Name for the component (e.g., ExampleController, example_service)
- Third word: Module name (optional, will prompt if not provided)

## Instructions

### 0. Parse and Validate Input
```bash
if [ ${#ARGUMENTS} -gt 256 ]; then
  echo "ERROR: Input too long (max 256 characters)"
  exit 1
fi

SCAFFOLD_TYPE=$(echo "$ARGUMENTS" | awk '{print $1}')
COMPONENT_NAME=$(echo "$ARGUMENTS" | awk '{print $2}')
MODULE_NAME=$(echo "$ARGUMENTS" | awk '{print $3}')

# Validate type
if ! echo "$SCAFFOLD_TYPE" | grep -qE '^(controller|service|form|block|plugin|entity|event|subscriber)$'; then
  echo "ERROR: Invalid type '$SCAFFOLD_TYPE'. Use: controller, service, form, block, plugin, entity, event, subscriber"
  exit 1
fi

# Validate component name
if [ -z "$COMPONENT_NAME" ]; then
  echo "ERROR: Component name is required"
  exit 1
fi
if ! echo "$COMPONENT_NAME" | grep -qE '^[a-zA-Z][a-zA-Z0-9_]*$'; then
  echo "ERROR: Invalid component name. Must start with a letter, only alphanumeric and underscores."
  exit 1
fi

# Validate module name if provided
if [ -n "$MODULE_NAME" ]; then
  if ! echo "$MODULE_NAME" | grep -qE '^[a-zA-Z][a-zA-Z0-9_]*$'; then
    echo "ERROR: Invalid module name. Must start with a letter, only alphanumeric and underscores."
    exit 1
  fi
fi
```

Based on the type, generate the appropriate Drupal code following standard conventions.

### Supported Types

1. **controller** - Generate a Controller class with route
2. **service** - Generate a Service class with services.yml entry
3. **form** - Generate a Form class (config or standard)
4. **block** - Generate a Block plugin
5. **plugin** - Generate a generic plugin (specify plugin type)
6. **entity** - Generate a content entity
7. **event** - Generate an Event class
8. **subscriber** - Generate an EventSubscriber

### For each type, generate:

1. The main PHP class file in the correct PSR-4 location
2. Any required YAML configuration (routing, services, schema)
3. Instructions for completing the setup

### Conventions

- Follow PSR-4 namespace structure: `Drupal\<module>\...`
- Use dependency injection via constructor
- Use PHP 8.x features (constructor promotion, typed properties, union types)
- Add appropriate type hints and return types
- Include PHPDoc comments
- Place files in `modules/custom/<module>/src/...`

### Example Outputs

**Controller:**
- `src/Controller/<Name>Controller.php`
- Entry in `<module>.routing.yml`

**Service:**
- `src/Service/<Name>.php`
- Entry in `<module>.services.yml`

**Form:**
- `src/Form/<Name>Form.php`
- Entry in `<module>.routing.yml`

**Block:**
- `src/Plugin/Block/<Name>Block.php`

**Event:**
- `src/Event/<Name>Event.php`

**Subscriber:**
- `src/EventSubscriber/<Name>Subscriber.php`
- Entry in `<module>.services.yml`

## Output

Generate the code and provide:
1. File paths where code was placed
2. The generated code
3. Any additional configuration needed (YAML entries, schema, etc.)
4. Next steps for the developer (enable module, clear cache, etc.)
