---
description: "Check translation status and coverage"
argument-hint: "[language-code]"
allowed-tools: Bash
---

# Translation Check

Check translation status and coverage for the Drupal site.

## Arguments

- `$ARGUMENTS` - Optional language code to check (e.g., fr, de, es, ja, pt-br)

## Instructions

### 1. Enabled Languages
```bash
./vendor/bin/drush language:list 2>&1
```

### 2. Translation Status Overview
```bash
./vendor/bin/drush locale:check 2>&1
./vendor/bin/drush locale:update --dry-run 2>&1 || echo "No updates available"
```

### 3. Translation Coverage by Language
```bash
./vendor/bin/drush sql:query "
SELECT
  language,
  COUNT(*) as translated_strings
FROM locales_target
GROUP BY language
ORDER BY translated_strings DESC;
"
```

### 4. Untranslated Strings Count
```bash
LANG="${ARGUMENTS:-}"
if [ -z "$LANG" ]; then
  echo "No language specified. Showing all languages from step 3."
else
  ./vendor/bin/drush sql:query "
  SELECT COUNT(*) as untranslated
  FROM locales_source s
  LEFT JOIN locales_target t ON s.lid = t.lid AND t.language = '$LANG'
  WHERE t.lid IS NULL;
  "
fi
```

### 5. Content Translation Status
```bash
./vendor/bin/drush sql:query "
SELECT
  n.type,
  n.langcode,
  COUNT(*) as count
FROM node_field_data n
GROUP BY n.type, n.langcode
ORDER BY n.type, n.langcode;
"
```

### 6. Missing Content Translations
```bash
LANG="${ARGUMENTS:-}"
if [ -n "$LANG" ]; then
  ./vendor/bin/drush sql:query "
  SELECT DISTINCT n.type, COUNT(*) as missing
  FROM node_field_data n
  WHERE n.default_langcode = 1
    AND n.status = 1
    AND n.nid NOT IN (
      SELECT nid FROM node_field_data WHERE langcode = '$LANG'
    )
  GROUP BY n.type
  ORDER BY missing DESC;
  "
fi
```

### 7. Translation Files
```bash
find . -name "*.po" -not -path "./vendor/*" -not -path "./core/*" 2>/dev/null | head -20 || echo "No .po files found"
```

### 8. Custom Module Translations
```bash
find modules/custom -name "*.po" -o -name "translations" -type d 2>/dev/null | head -20 || echo "No custom module translations found"
```

## Output Format

### Language Overview

| Language | Code | Status | Default |
|----------|------|--------|---------|
| English | en | Enabled | Yes |

### Interface Translation Coverage

| Language | Translated Strings | Untranslated | Coverage % |
|----------|-------------------|--------------|------------|

### Content Translation Status

| Content Type | Default Lang | Other Languages |
|--------------|-------------|-----------------|

### Missing Translations

Content published in default language but missing translations.

### Recommendations

1. **Import translations**:
   ```bash
   ./vendor/bin/drush locale:import <langcode> path/to/file.po --type=customized --override=all
   ```

2. **Update from remote**:
   ```bash
   ./vendor/bin/drush locale:update
   ```

3. **Export for translation**:
   ```bash
   ./vendor/bin/drush locale:export <langcode> > export-<langcode>.po
   ```

4. **Content translation workflow**:
   - Enable content_translation module if not already enabled
   - Configure translation settings per content type
