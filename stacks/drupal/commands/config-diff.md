---
description: Show configuration differences between database and exported files
allowed-tools: Bash
---

# Configuration Diff

Show differences between active configuration (database) and exported configuration files.

## Instructions

### 1. Check Config Status
```bash
./vendor/bin/drush config:status --format=table 2>&1
```

### 2. Show Specific Diffs (if changes exist)

For each changed config item, show the diff:
```bash
./vendor/bin/drush config:diff <config.name> 2>&1
```

### 3. Check Feature Status
```bash
./vendor/bin/drush features:status 2>&1 || echo "Features module may not be enabled"
```

### 4. List Overridden Features
```bash
./vendor/bin/drush features:list --status=overridden 2>&1 || true
```

### 5. Check for UUID Issues in Feature Configs
```bash
grep -r "^uuid:" modules/custom/*/config/install/*.yml 2>/dev/null | head -20
```

## Output Format

Provide a summary:

### Configuration Status

| Config Name | State | Action Needed |
|-------------|-------|---------------|
| name | Only in DB / Different / Only in sync | Export/Import/Review |

### Feature Status

| Feature | State | Action |
|---------|-------|--------|
| module_name | Overridden/Default | Revert/Export |

### Issues Found

- List any UUID issues in config/install
- List any environment-specific values
- List any missing dependencies

### Recommendations

Provide specific commands to resolve each issue.
