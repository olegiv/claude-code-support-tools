---
description: Run comprehensive PHP/Drupal code quality checks (PHPStan, PHPCS, deprecations, dependencies)
argument-hint: [module-name | all]
allowed-tools: Bash, Read
---

Scan custom Drupal code for quality issues, coding-standard violations, deprecated API
usage, and dependency vulnerabilities.

**Read-only.** Report findings and offer the exact fixes and commands; do not edit files
and do not run `phpcbf` / `composer lint-fix*`. The user decides what to apply.

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
   - Uses the repo ruleset (`phpcs.xml.dist` / `phpcs.xml`) when there is one: it pins
     the standard, the scope, the extensions and the exclusions in one place, so every
     caller checks the same thing. Falls back to `Drupal` + `DrupalPractice` (via
     `drupal/coder`) only when the repo has no ruleset.
   - Catches: formatting, docblocks, naming, array syntax, and Drupal best-practice
     smells (e.g. static `\Drupal::` calls that should use dependency injection)
   - **No baseline.** PHPCS has no equivalent of `phpstan-baseline.neon`, so on a
     project with accumulated drift the tree will never read clean and cannot be made
     to. The gate is **changed files**; the tree-wide figure is debt to report, not a
     task list.

4. **Dependency Vulnerabilities**
   - `composer audit` against installed packages

5. **Drupal Anti-Pattern Semantic Checks** (greps for things PHPStan/PHPCS may not flag)
   - Leftover debug calls (`var_dump`, `kint`, `dpm`, `dd`, ...)
   - Unescaped Twig output (`|raw`)
   - Deprecated procedural API (`db_query`, `drupal_set_message`, ...)
   - Static `\Drupal::` service access inside `src/` classes (DI smell). Two partial
     detectors exist and neither is sufficient alone: the repo `phpstan.neon` usually
     ignores `#Drupal calls should be avoided#`, and PHPCS's
     `DrupalPractice.Objects.GlobalDrupal` only warns inside DI-capable classes - a
     fixed list of 12 base classes (`ControllerBase`, `FormBase`, `BlockBase`, ...),
     classes registered in a `*.services.yml`, or `ContainerInjectionInterface`
     implementors - and it skips static methods and reads only the *immediate* parent
     class. Plugins, event subscribers and indirect subclasses are missed. The grep is
     the wider net; expect it to overlap with the PHPCS warning on the classes the
     sniff does cover.

6. **Heavy Security SAST** (referenced, not run inline)
   - For deep security scanning use `/security-scan` or `./bin/security/full-security-scan.sh`

## Steps

1. **Validate and resolve scope:**
   ```bash
   TARGET=
   if [ -n "${ARGUMENTS:-}" ] && [ "$ARGUMENTS" != "all" ]; then
     if [ ${#ARGUMENTS} -gt 128 ]; then
       echo "ERROR: Input too long (max 128 characters)"; exit 1
     fi
     if ! printf '%s' "$ARGUMENTS" | grep -qE '^[a-zA-Z0-9_]+$'; then
       echo "ERROR: Invalid name. Only alphanumeric and underscores allowed."; exit 1
     fi
     for d in "modules/custom/$ARGUMENTS" "themes/custom/$ARGUMENTS"; do
       [ -d "$d" ] && TARGET="$d"
     done
     [ -n "$TARGET" ] || { echo "ERROR: no modules/custom/$ARGUMENTS or themes/custom/$ARGUMENTS"; exit 1; }
   fi
   if [ -n "$TARGET" ]; then
     GREP_PATHS="$TARGET"
   else
     GREP_PATHS=
     for d in modules/custom themes/custom; do
       [ -d "$d" ] && GREP_PATHS="${GREP_PATHS:+$GREP_PATHS }$d"
     done
   fi
   echo "Scope:      ${TARGET:-<per-tool config>}"
   echo "Grep paths: $GREP_PATHS"
   ```
   An **empty `$TARGET` means "whole project"** - and for the whole project every tool
   already owns its scope, so pass it no path at all: `phpstan.neon` has `paths:`,
   `phpcs.xml.dist` has `<file>`.

   **Do not unify those two scopes.** They are routinely different: a PHPCS ruleset
   typically covers `modules/custom` + `themes/custom`, while `phpstan.neon` often
   covers only `modules/custom` - and `phpstan-baseline.neon` was generated against
   exactly that set. Adding `themes/custom` to the PHPStan command line would report a
   wall of un-baselined errors that are not new and are not yours. `$GREP_PATHS` exists
   only for the greps in step 6, which have no config of their own.

2. **PHP environment (informational):**
   ```bash
   php -v | head -1
   php -r '$j=json_decode(file_get_contents("composer.json"),true); echo "target: ",($j["config"]["platform"]["php"] ?? "unset"),"\n";'
   ```
   Note any mismatch; do not fail on it.

3. **PHPStan (primary):**
   ```bash
   # Scoped run passes the path; whole-project run passes none and uses phpstan.neon `paths`.
   ./vendor/bin/phpstan analyse ${TARGET:+"$TARGET"} --no-progress
   ```
   If the binary is missing, run `composer install`.
   - Reads `phpstan.neon` automatically. The baseline still applies, so report only the
     NEW errors a change introduces.
   - Single-module caveat: when `$TARGET` is one module, PHPStan may print
     `Ignored error pattern ... was not matched in reported errors`. These are the
     repo-wide ignore rules that simply do not apply to this subset - they are **benign**.
     Count only errors that cite a file inside `$TARGET`. For an accurate baseline-aware
     count, run against all of `modules/custom`.
   - If the bare form errors with "no paths", this repo's `phpstan.neon` has no
     `paths:`. Pass `$GREP_PATHS`, but treat any errors outside `modules/custom` with
     suspicion - the baseline probably does not cover them.

4. **Coding standards (PHPCS):**

   **4a. Preflight - ask the project how it wants to be linted.** Run this once, then
   use the invocation it prints verbatim:
   ```bash
   RULESET=
   for f in .phpcs.xml phpcs.xml .phpcs.xml.dist phpcs.xml.dist; do
     [ -f "$f" ] && { RULESET="$f"; break; }
   done
   SCRIPTS=$(php -r '$s=json_decode(@file_get_contents("composer.json"),true)["scripts"]??[];
     echo implode(" ", array_intersect(["lint","lint-changed","lint-fix","lint-fix-changed"], array_keys($s)));' 2>/dev/null)
   if [ -n "$RULESET" ]; then
     echo "ruleset:  $RULESET  -> do NOT pass --standard or --extensions"
     echo "PHPCS:    ./vendor/bin/phpcs"
     echo "PHPCBF:   ./vendor/bin/phpcbf"
   else
     echo "ruleset:  none  -> pass the standard explicitly"
     echo "PHPCS:    ./vendor/bin/phpcs --standard=Drupal,DrupalPractice --extensions=php,module,inc,install,theme,profile,engine"
     echo "PHPCBF:   ./vendor/bin/phpcbf --standard=Drupal,DrupalPractice --extensions=php,module,inc,install,theme,profile,engine"
   fi
   echo "composer: ${SCRIPTS:-none}"
   ```
   Below, `$PHPCS` / `$PHPCBF` mean whatever the preflight printed.

   - **Never add `--standard=` when a ruleset exists.** PHPCS only auto-discovers
     `phpcs.xml*` when no standard is given - the search in `Config.php` is guarded by
     `isset($this->overriddenDefaults['standards']) === false`. Passing `--standard=`
     silently discards the ruleset's `<arg value="sp"/>` (findings then print with no
     sniff code), its `<exclude-pattern>`s and its cache file. The totals may match by
     coincidence and diverge the moment the ruleset changes.
   - **Passing a path is fine.** A CLI path overrides only the ruleset's `<file>`
     entries; standard, extensions, `-s`, cache and exclusions still apply.
   - If the preflight found `composer` scripts, prefer them for an **unscoped** run -
     they are the project's declared contract and may do more than bare `phpcs`. For a
     **scoped** run call `./vendor/bin/phpcs <path>` directly.

   **4b. The gate - changed files.**
   ```bash
   $PHPCS --filter=GitModified ${TARGET:+"$TARGET"}     # or: composer lint-changed
   ```
   These are the violations you are responsible for. Fix them.

   - `GitModified` runs `git ls-files -o -m --exclude-standard`: modified-in-working-tree
     plus untracked. It does **not** see a file you have already `git add`-ed - use
     `--filter=GitStaged` for the index - and it does not mean "changed on this branch".
   - Prefer `--filter=` over `$(git diff --name-only ...)`. The filter is fail-closed:
     an empty match scans nothing. Command substitution is fail-open - if the list comes
     out empty, phpcs receives no path, falls back to the ruleset's `<file>` scope, and
     lints the entire tree.

   **4c. The debt figure - informational.**
   ```bash
   $PHPCS --report=summary ${TARGET:+"$TARGET"}         # or: composer lint
   ```
   Report this number as pre-existing drift. Do not put it in the actionable total and
   do not open it as work. PHPCS has no baseline file, so this is the only way to
   express "known debt" - by labelling it.
   - For per-line detail, drop `--report=summary`. With a ruleset in play that detail
     now arrives **with sniff codes** (`-s` from `<arg value="sp"/>`), so each finding
     can be looked up or excluded by name.

   **4d. Offer the mechanical fixes - this command does not apply them.** Most
   violations are mechanical. Show the patch with `--report=diff`, which writes nothing:
   ```bash
   $PHPCS --report=diff ${TARGET:+"$TARGET"}            # read-only preview
   ```
   Then hand the user the command and let them decide:
   ```bash
   # Offer this - do not execute it.
   composer lint-fix-changed                            # or: $PHPCBF --filter=GitModified <paths>
   ```
   State how many files it would rewrite. A **directory argument is not a scope**:
   `phpcbf modules/custom/<module>` rewrites every file in that module, including ones
   the current change never touched; with no argument it rewrites all of
   `modules/custom` and `themes/custom`. And reformatting a legacy file belongs in its
   **own** commit, separate from the behavioural change, so the real diff stays readable
   and `git blame` stays useful.

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
Scope: modules/custom/<module>          (or: each tool's own config)
PHP:   8.4.x (target 8.3) - notice

PHPStan (level 1):         X new errors            (baseline: tracked separately)
Coding standards (PHPCS):  X errors / Y warnings   (Z auto-fixable) - changed files
  pre-existing drift:      N errors / M warnings   (in-scope tree; debt, NOT actionable)
Deprecated API usage:      X   (PHPStan deprecation rules + greps)
Dependency audit:          X advisories
Anti-pattern checks:
  Debug leftovers:         X
  Raw Twig (|raw):         X
  Deprecated procedural:   X
  \Drupal:: in classes:    X

Total actionable: X issues
  (excludes the PHPStan baseline and the pre-existing PHPCS drift - both are tracked
   debt, not findings from this change)
```

## If Issues Found

For each issue, provide:
1. File path and line number
2. Description of the issue
3. How to fix it
4. Code example (before/after)

## Common Fixes

### Static service access -> dependency injection (DrupalPractice.Objects.GlobalDrupal / grep)
```php
// BAD: service located statically inside a class
class TrackerService {
  public function build() {
    $config = \Drupal::config('example_tracker.settings');
  }
}

// GOOD: inject the dependency via the constructor
class TrackerService {

  public function __construct(
    protected ConfigFactoryInterface $configFactory,
  ) {}

  public function build() {
    $config = $this->configFactory->get('example_tracker.settings');
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
2. **PHPStan baseline = tracked debt** - `phpstan-baseline.neon` holds known issues. Do
   not try to clear the whole baseline; focus on the new errors your change introduces.
3. **PHPCS has no baseline** - PHP_CodeSniffer offers no baseline mechanism at all, so a
   project with accumulated drift can never show a clean tree. The gate is therefore
   **changed files** (`--filter=GitModified`), the same discipline the baseline gives
   PHPStan. Report the tree-wide figure as debt; never as a to-do list.
4. **This command is read-only** - it reports and offers fixes; it does not run
   `phpcbf` or `composer lint-fix*`. Use `--report=diff` to show what a fix would do.
   Applying it is the user's call, scoped to the files their change touches, and
   committed on its own - never a side effect of an audit.
5. **Verify after fixes** - run the module's tests:
   `./vendor/bin/phpunit -c core/phpunit.xml.dist "modules/custom/<module>/tests/"` (or `/test-run`).
6. **Never edit `vendor/` or `core/`** - scope all fixes to `modules/custom` / `themes/custom`.
7. **Security** - this command does not run the heavy SAST suite; use `/security-scan` for that.
