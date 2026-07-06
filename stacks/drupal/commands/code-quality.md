---
description: Run comprehensive PHP/Drupal code quality checks (PHPStan, PHPCS, deprecations, dependencies)
argument-hint: [module-name | all]
allowed-tools: Bash, Read
---

Scan custom Drupal code for quality issues, coding-standard violations, deprecated API
usage, and dependency vulnerabilities.

Scope: $ARGUMENTS (a custom module machine name, "all", or empty for all custom modules)

## Checks Performed

1. **PHP Environment**
   - Compare the running `php` version against the project target (`config.platform.php`)
   - Informational only - a mismatch (e.g. dev 8.4 vs target 8.3) is a notice, not a failure

2. **Static Analysis (PHPStan)** - the primary, aggregate analyzer
   - Uses the repo `phpstan.neon` (level 1, `mglaman/phpstan-drupal`, bleedingEdge)
   - Catches: undefined methods/properties, wrong argument types, dead code, missing
     return types, and deprecated API usage (`phpstan-deprecation-rules`)
   - Baseline-aware: `phpstan-baseline.neon` suppresses known debt; focus on NEW errors

3. **Coding Standards (PHP_CodeSniffer)**
   - `Drupal` + `DrupalPractice` standards (via `drupal/coder`)
   - Catches: formatting, docblocks, naming, array syntax, and Drupal best-practice
     smells (e.g. static `\Drupal::` calls that should use dependency injection)

4. **Dependency Vulnerabilities**
   - `composer audit` against installed packages

5. **Drupal Anti-Pattern Semantic Checks** (greps for things PHPStan/PHPCS may not flag)
   - Leftover debug calls (`var_dump`, `kint`, `dpm`, `dd`, ...)
   - Unescaped Twig output (`|raw`)
   - Deprecated procedural API (`db_query`, `drupal_set_message`, ...)
   - Static `\Drupal::` service access inside `src/` classes (DI smell - note: the repo
     `phpstan.neon` intentionally ignores this, so the grep is the way to surface it)

6. **Heavy Security SAST** (referenced, not run inline)
   - For deep security scanning use `/security-scan` or `./bin/security/full-security-scan.sh`

## Steps

1. **Validate and resolve scope:**
   ```bash
   if [ -n "${ARGUMENTS:-}" ] && [ "$ARGUMENTS" != "all" ]; then
     if [ ${#ARGUMENTS} -gt 128 ]; then
       echo "ERROR: Input too long (max 128 characters)"; exit 1
     fi
     if ! printf '%s' "$ARGUMENTS" | grep -qE '^[a-zA-Z0-9_]+$'; then
       echo "ERROR: Invalid module name. Only alphanumeric and underscores allowed."; exit 1
     fi
     TARGET="modules/custom/$ARGUMENTS"
   else
     TARGET="modules/custom"
   fi
   echo "Scope: $TARGET"
   [ -e "$TARGET" ] || { echo "ERROR: $TARGET not found"; exit 1; }
   ```
   (To include themes, run the same checks against `themes/custom` separately.)

2. **PHP environment (informational):**
   ```bash
   php -v | head -1
   php -r '$j=json_decode(file_get_contents("composer.json"),true); echo "target: ",($j["config"]["platform"]["php"] ?? "unset"),"\n";'
   ```
   Note any mismatch; do not fail on it.

3. **PHPStan (primary):**
   ```bash
   ./vendor/bin/phpstan analyse "$TARGET" --no-progress
   ```
   If the binary is missing, run `composer install`.
   - Reads `phpstan.neon` automatically. The baseline still applies, so report only the
     NEW errors a change introduces.
   - Single-module caveat: when `$TARGET` is one module, PHPStan may print
     `Ignored error pattern ... was not matched in reported errors`. These are the
     repo-wide ignore rules that simply do not apply to this subset - they are **benign**.
     Count only errors that cite a file inside `$TARGET`. For an accurate baseline-aware
     count, run against all of `modules/custom`.

4. **Coding standards (PHPCS):**
   ```bash
   ./vendor/bin/phpcs --standard=Drupal,DrupalPractice \
     --extensions=php,module,inc,install,theme,profile,engine \
     --report=summary "$TARGET"
   ```
   - For full per-line detail, drop `--report=summary`.
   - Most violations are auto-fixable - preview/apply with `phpcbf`:
     ```bash
     ./vendor/bin/phpcbf --standard=Drupal,DrupalPractice \
       --extensions=php,module,inc,install,theme,profile,engine "$TARGET"
     ```
   - If the standards are not found, confirm `drupal/coder` is installed: `./vendor/bin/phpcs -i`.

5. **Dependency audit:**
   ```bash
   composer audit
   ```
   (Project-wide, not scoped to the module.)

6. **Drupal anti-pattern greps** (scoped to `$TARGET`):
   ```bash
   echo "Debug leftovers:"
   grep -rnE '\b(var_dump|print_r|var_export|dpm|dvm|dsm|kint|ksm|dpq|dd|dump)\s*\(' "$TARGET" \
     --include='*.php' --include='*.module' --include='*.inc' --include='*.install' --include='*.theme' \
     | grep -v '/tests/' || echo "  none"

   echo "Raw Twig output (|raw):"
   grep -rnE '\|\s*raw\b' "$TARGET" --include='*.twig' || echo "  none"

   echo "Deprecated procedural API:"
   grep -rnE '\b(db_query|db_select|db_insert|db_update|db_delete|drupal_set_message|format_string|drupal_render|entity_load)\s*\(' "$TARGET" \
     --include='*.php' --include='*.module' --include='*.inc' --include='*.install' || echo "  none"

   echo "Static \\Drupal:: calls in src/ (prefer dependency injection):"
   grep -rn '\\Drupal::' "$TARGET"/src 2>/dev/null | grep -v '/tests/' || echo "  none"
   ```
   Review each hit: `print_r`/`var_export` with a `true` second argument may be legitimate;
   `\Drupal::` in a `*.module` hook or a static `create()` factory is acceptable, but inside
   service/controller logic it should be constructor-injected.

7. **Report results** using the format below.

## Expected Output

```
Drupal Code Quality Report
==========================
Scope: modules/custom/<module>
PHP:   8.4.x (target 8.3) - notice

PHPStan (level 1):         X new errors   (baseline: tracked separately)
Coding standards (PHPCS):  X errors / Y warnings   (Z auto-fixable via phpcbf)
Deprecated API usage:      X   (PHPStan deprecation rules + greps)
Dependency audit:          X advisories
Anti-pattern checks:
  Debug leftovers:         X
  Raw Twig (|raw):         X
  Deprecated procedural:   X
  \Drupal:: in classes:    X

Total: X issues
```

## If Issues Found

For each issue, provide:
1. File path and line number
2. Description of the issue
3. How to fix it
4. Code example (before/after)

## Common Fixes

### Static service access -> dependency injection (PHPCS DrupalPractice / grep)
```php
// BAD: service located statically inside a class
class TrackerService {
  public function build() {
    $config = \Drupal::config('iru_tracker.settings');
  }
}

// GOOD: inject the dependency via the constructor
class TrackerService {

  public function __construct(
    protected ConfigFactoryInterface $configFactory,
  ) {}

  public function build() {
    $config = $this->configFactory->get('iru_tracker.settings');
  }

}
// Register the service args in *.services.yml (or rely on autowiring).
```

### Deprecated message API (grep / deprecation rules)
```php
// BAD
drupal_set_message($this->t('Saved.'));

// GOOD (injected MessengerInterface)
$this->messenger()->addStatus($this->t('Saved.'));
// \Drupal::messenger()->addStatus(...) is acceptable only outside DI-capable classes.
```

### Deprecated database API (grep / deprecation rules)
```php
// BAD
$result = db_query('SELECT name FROM {users} WHERE uid = ' . $uid);

// GOOD: injected Connection + placeholders
$result = $this->database->query(
  'SELECT [name] FROM {users_field_data} WHERE [uid] = :uid',
  [':uid' => $uid],
);
```

### Unescaped Twig output (grep)
```twig
{# BAD - bypasses auto-escaping, XSS risk #}
{{ user_input|raw }}

{# GOOD - let Twig auto-escape, or pass a render array #}
{{ user_input }}
```

### Missing type declarations (PHPStan)
```php
// BAD - PHPStan cannot verify the return type
public function getCount() {
  return $this->storage->count();
}

// GOOD
public function getCount(): int {
  return $this->storage->count();
}
```

## Notes

1. **PHPStan is the primary analyzer** - it also enforces deprecation rules, so it covers
   much of the "deprecated API" surface; the greps catch the rest plus the DI smell the
   repo config deliberately ignores.
2. **Baseline = tracked debt** - `phpstan-baseline.neon` holds known issues. Do not try to
   clear the whole baseline; focus on the new errors your change introduces.
3. **Auto-fix style first** - run `./vendor/bin/phpcbf ...` before hand-fixing PHPCS issues.
4. **Verify after fixes** - run the module's tests:
   `./vendor/bin/phpunit -c core/phpunit.xml.dist "modules/custom/<module>/tests/"` (or `/test-run`).
5. **Never edit `vendor/` or `core/`** - scope all fixes to `modules/custom` / `themes/custom`.
6. **Security** - this command does not run the heavy SAST suite; use `/security-scan` for that.
