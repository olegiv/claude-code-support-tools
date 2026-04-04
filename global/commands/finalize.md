Review all changes in this session and perform the requested actions.

Parameter: $ARGUMENTS
Accepted values (comma-separated, or single): all, tests, translations, docs
Default (if empty or not provided): all

## Actions

### tests
Check test coverage for all modified files. Add or update unit/integration tests to cover new or changed functionality. Ensure edge cases are handled.

### translations
Scan all new or changed user-facing strings. Add missing translation keys to translation files. Verify existing translations are still valid after changes.

### docs
Update README, API docs, inline documentation, and config references if behavior, interfaces, or configuration changed.

## Execution
- Parse $ARGUMENTS: split by comma, trim whitespace, lowercase each value
- If "all" is present or $ARGUMENTS is empty — run all three actions
- Otherwise run only the specified actions in order: tests → translations → docs
- After completion, report a summary of what was added or updated per category