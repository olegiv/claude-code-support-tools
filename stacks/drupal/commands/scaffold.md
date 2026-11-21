---
description: "Generate Drupal boilerplate code"
argument-hint: "<type> <name> [module]"
allowed-tools: Bash, Read, Write, Edit, Glob
---

# Scaffold Drupal Code

**Check the arguments before running anything.** The command arguments are inserted into this prompt before any shell runs, so the shell checks below cannot protect a command that contains them. Check them yourself first: they must be two or three words: a type (`controller`, `service`, `form`, `block`, `plugin`, `entity`, `event` or `subscriber`), a component name matching `^[a-zA-Z][a-zA-Z0-9_]*$`, and optionally a module name matching `^[a-zA-Z][a-zA-Z0-9_]*$`. The whole value must match, on a single line; if you are unsure whether it matches, treat it as invalid. If it does not match, stop and report the invalid argument without running any command. Run the steps below only with arguments that passed this check; their shell blocks read the value from `ARGS`.

Generate boilerplate code for common Drupal components.

## Arguments

`$ARGUMENTS` contains space-separated values:
- First word: Type (controller, service, form, block, plugin, entity, event, subscriber)
- Second word: Name for the component (e.g., ExampleController, example_service)
- Third word: Module name (optional, will prompt if not provided)

## Instructions

### 0. Parse and Validate Input
```bash
ARGS='$ARGUMENTS'  # passed the argument check above, so it contains no '
if [ ${#ARGS} -gt 256 ]; then
  echo "ERROR: Input too long (max 256 characters)"
  exit 1
fi

SCAFFOLD_TYPE=$(printf '%s' "$ARGS" | awk -v i=1 '{print $i}')
COMPONENT_NAME=$(printf '%s' "$ARGS" | awk -v i=2 '{print $i}')
MODULE_NAME=$(printf '%s' "$ARGS" | awk -v i=3 '{print $i}')

# Explicit path traversal check (defense-in-depth)
for VAR_CHECK in "$SCAFFOLD_TYPE" "$COMPONENT_NAME" "$MODULE_NAME"; do
  if [ -n "$VAR_CHECK" ] && printf '%s' "$VAR_CHECK" | grep -qE '(\.\.|/)'; then
    echo "ERROR: Path traversal characters not allowed"
    exit 1
  fi
done

# Validate type
if ! printf '%s' "$SCAFFOLD_TYPE" | grep -qE '^(controller|service|form|block|plugin|entity|event|subscriber)$'; then
  echo "ERROR: Invalid type '$SCAFFOLD_TYPE'. Use: controller, service, form, block, plugin, entity, event, subscriber"
  exit 1
fi

# Validate component name
if [ -z "$COMPONENT_NAME" ]; then
  echo "ERROR: Component name is required"
  exit 1
fi
if ! printf '%s' "$COMPONENT_NAME" | grep -qE '^[a-zA-Z][a-zA-Z0-9_]*$'; then
  echo "ERROR: Invalid component name. Must start with a letter, only alphanumeric and underscores."
  exit 1
fi

# Validate module name if provided
if [ -n "$MODULE_NAME" ]; then
  if ! printf '%s' "$MODULE_NAME" | grep -qE '^[a-zA-Z][a-zA-Z0-9_]*$'; then
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
