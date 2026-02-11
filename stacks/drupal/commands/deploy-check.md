---
description: Run pre-deployment checklist
allowed-tools: Bash, Read, Grep
---

# Pre-Deployment Checklist

Run a comprehensive pre-deployment checklist using standard Drupal tools.

## 1. Git Status
```bash
git status
```

## 2. Check for Uncommitted Changes
Verify all changes are committed or intentionally excluded.

## 3. Composer Audit
```bash
composer audit
```

## 4. Run Tests
```bash
./vendor/bin/phpunit -c core/phpunit.xml.dist --group php_unit 2>&1 | tail -20
```

If no test group is configured, try:
```bash
./vendor/bin/phpunit -c core/phpunit.xml.dist 2>&1 | tail -20
```

## 5. Check Database Updates
```bash
./vendor/bin/drush updb --no-post-updates -n 2>&1 | head -10
```

## 6. Check Configuration Status
```bash
./vendor/bin/drush config:status 2>&1 | head -20
```

## 7. Check Module Status
```bash
./vendor/bin/drush pm:security 2>&1
```

## Report Summary

Provide a summary of:
- [ ] Git status (clean/dirty)
- [ ] Composer audit results
- [ ] Test results (pass/fail)
- [ ] Pending database updates
- [ ] Configuration sync status
- [ ] Security advisories
- [ ] Overall deployment readiness

Recommend whether it is safe to deploy or what needs to be addressed first.
