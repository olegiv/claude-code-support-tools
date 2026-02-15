Scan the project for code quality issues and warnings.

## Checks Performed

1. **Go Toolchain Version Mismatch**
   - Check if `go version` matches the compiler version
   - If mismatch found, STOP and report the issue

2. **Comprehensive Static Analysis (golangci-lint)**
   - Runs multiple linters in a single pass
   - Catches: unhandled errors, direct error comparisons, unused parameters,
     redundant type conversions, constant comparisons, duplicate code, and more
   - Configuration in `.golangci.yml`

3. **Nil Safety Analysis**
   - Run `nilaway ./...` for potential nil pointer dereferences

4. **Import Sorting**
   - Check for unsorted imports within groups (alphabetical order)
   - Check for unnecessary import group splits (third-party separated from project imports)

5. **CSS Analysis**
   - Check for `var(--*)` usages that reference undefined custom properties in theme CSS files
   - Check for margin/padding side properties that can be collapsed into shorthand
   - Check for `font-family` declarations using `var()` without a generic font family fallback

6. **JSON Schema Compliance**
   - Check that `$schema` relative paths in `messages.json` files resolve to the actual schema file

7. **Semantic Analysis** (manual checks if golangci-lint misses them)
   - Stuttering names — exported symbols that repeat the package name (`revive/exported` detects this but is suppressed by the `comments` exclusion preset)
   - Incorrect doc comments — comment on exported symbol starts with wrong name (`revive/exported` detects this but is suppressed by the `comments` exclusion preset)
   - Struct initialization without field names (`govet/composites` only catches cross-package types, not anonymous structs or same-package types)
   - Bool conditions always true/false on certain code paths (variable initialized then used on early-return path without modification)
   - Unused exported constants/variables (golangci-lint `unused` only catches unexported symbols)
   - Redundant named-type conversion of untyped constants (`unconvert` does NOT catch `template.HTML("literal")` or `template.JS("literal")` in return contexts where the untyped constant auto-converts)
   - Redundant struct type conversion with type aliases (`unconvert` does NOT catch `NamedType(v)` when `v` is an anonymous struct via type alias `=` that is directly assignable to `NamedType`)
   - Pointer to local variable replaceable with `new(expr)` (Go 1.26+: `tmp := expr; &tmp` → `new(expr)`)
   - Cross-method/cross-file code duplication (golangci-lint `dupl` misses methods with identical bodies on different receivers, identical test helpers across packages, and small duplicated functions below the token threshold)
   - Unused type parameters in generic functions
   - Redundant COALESCE in SQL queries
   - Potential resource leaks (sql.Rows not closed in caller)

## Steps

1. **Check Go toolchain:**
   ```bash
   go version
   $(go env GOTOOLDIR)/compile -V
   ```
   If versions don't match, report error and provide fix instructions.

2. **Run golangci-lint (primary tool):**
   ```bash
   golangci-lint run ./...
   ```

   If golangci-lint is not installed:
   ```bash
   go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
   ```

   **Linters enabled:**
   - `errcheck` - unchecked errors
   - `errorlint` - direct error comparisons (`==` instead of `errors.Is()`), type assertions (`err.(*T)` instead of `errors.As()`), non-wrapping format verbs (`%s`/`%v` instead of `%w`)
   - `govet` - suspicious constructs
   - `staticcheck` - comprehensive static analysis
   - `unconvert` - unnecessary type conversions
   - `unparam` - unused function parameters
   - `gocritic` - bugs, performance, style (including constant comparisons)
   - `dupl` - code clone detection
   - `gocyclo` - cyclomatic complexity
   - `misspell` - spelling mistakes
   - `usetesting` - `os.Setenv`/`os.MkdirTemp`/`os.Chdir`/`os.CreateTemp` in tests instead of `t.Setenv`/`t.TempDir`/`t.Chdir`/`os.CreateTemp(t.TempDir(), ...)`

3. **Run nil safety analysis:**
   ```bash
   nilaway ./...
   ```
   If nilaway is not installed:
   ```bash
   go install go.uber.org/nilaway/cmd/nilaway@latest
   ```

4. **Check for unsorted imports:**

   Go imports should be alphabetically sorted within each group, and use exactly 2 groups:
   stdlib, then all external (third-party + project) together.

   Detection:
   ```bash
   goimports -l $(find . -name "*.go" -not -path "./.git/*" -not -name "*_templ.go" -not -name "*.sql.go")
   ```

   If `goimports` is not installed:
   ```bash
   go install golang.org/x/tools/cmd/goimports@latest
   ```

   Also check for unnecessary 3-group splits (third-party like chi separated from project imports):
   ```bash
   grep -rl 'go-chi/chi' --include="*.go" . | xargs grep -l 'chi/v5"' | while read f; do
     python3 -c "
   import re
   with open('$f') as fh:
       content = fh.read()
   m = re.search(r'import \((.*?)\)', content, re.DOTALL)
   if m:
       groups = [g.strip() for g in re.split(r'\n\s*\n', m.group(1)) if g.strip()]
       if len(groups) > 2:
           print(f'$f: {len(groups)} import groups (expected 2)')
   "
   done
   ```

   **Common patterns:**
   - `errors` before `encoding/json` (alphabetical sort error within stdlib group)
   - Third-party chi import in its own group separated from project imports by blank line

5. **Check for unresolved CSS custom properties in theme files:**

   Theme CSS files may reference `var(--property)` that is never defined in the same file.
   This causes the property to silently fall back to its initial value, breaking styling.

   Detection: For each theme CSS file, extract all `var(--*)` usages and verify each
   property is defined (has a `--property:` declaration) in the same file.

   ```bash
   for f in internal/themes/*/static/css/theme.css custom/themes/*/static/css/theme.css; do
     [ -f "$f" ] || continue
     grep -oE 'var\(--[a-zA-Z0-9_-]+\)' "$f" | sed 's/var(--//;s/)//' | sort -u | while read -r prop; do
       if ! grep -qE -- "--${prop}[[:space:]]*:" "$f"; then
         echo "$f: unresolved --$prop"
       fi
     done
   done
   ```

   **Common causes:**
   - Property renamed but not all usages updated (e.g., `--dev-mono` → `--dev-font-mono`)
   - Property from a design system never added to the theme (e.g., `--font-size-small`)
   - Typo in property name (e.g., `--text-primary` vs `--text-color`)

6. **Check for CSS margin/padding shorthand opportunities:**

   When a CSS rule uses multiple side-specific properties (e.g., `margin-top` + `margin-bottom`,
   or `margin-left` + `margin-right`), they can often be collapsed into a single shorthand property.

   Detection: For each theme CSS file, find rules containing 2+ margin-side or padding-side properties.

   ```bash
   for f in internal/themes/*/static/css/theme.css custom/themes/*/static/css/theme.css; do
     [ -f "$f" ] || continue
     python3 -c "
   import re, sys
   with open('$f') as fh:
       css = fh.read()
   for m in re.finditer(r'([^{}]+)\{([^{}]+)\}', css):
       sel, body = m.group(1).strip(), m.group(2)
       for prop in ['margin', 'padding']:
           sides = [s for s in ['top','right','bottom','left'] if re.search(rf'{prop}-{s}\s*:', body)]
           if len(sides) >= 2:
               print(f'$f: {sel} — {prop}-{{\", \".join(sides)}} can use shorthand')
   "
   done
   ```

   **Common patterns:**
   - `margin-top` + `margin-bottom` → `margin: <top> 0 <bottom>`
   - `margin-left` + `margin-right` → `margin: 0 <right> 0 <left>`
   - `padding-top` + `padding-bottom` → `padding: <top> 0 <bottom>`

7. **Check for missing generic font family in CSS:**

   Every `font-family` declaration should end with a generic family name (`sans-serif`, `serif`,
   `monospace`, `cursive`, `system-ui`). When `font-family` uses only a `var()` custom property,
   the browser has no fallback if the property fails to resolve.

   Detection:
   ```bash
   for f in internal/themes/*/static/css/theme.css custom/themes/*/static/css/theme.css; do
     [ -f "$f" ] || continue
     grep -nE 'font-family:\s*var\(--[^)]+\);$' "$f"
   done
   ```

   For each match, append the appropriate generic family based on the property's purpose:
   - Body/UI font → `, sans-serif`
   - Heading font (serif-based) → `, serif`
   - Monospace/code font → `, monospace`

8. **Check for broken `$schema` paths in i18n JSON files:**

   All `messages.json` files reference `.schema/i18n-schema.json` via a relative `$schema` path.
   Theme locale files are deeper in the directory tree than module locale files, so the number
   of `../` segments must match the actual depth from the file to the project root.

   Detection:
   ```bash
   python3 -c "
   import json, glob, os
   for fpath in sorted(glob.glob('**/messages.json', recursive=True)):
       with open(fpath) as f:
           data = json.load(f)
       ref = data.get('\$schema', '')
       if not ref:
           print(f'{fpath}: missing \$schema')
           continue
       resolved = os.path.normpath(os.path.join(os.path.dirname(fpath), ref))
       if not os.path.exists(resolved):
           print(f'{fpath}: broken \$schema -> {resolved}')
   "
   ```

   **Common cause:** File is at depth N from root but `$schema` has N-1 `../` segments.
   Theme locales (`internal/themes/*/locales/*/`) and custom theme locales (`custom/themes/*/locales/*/`)
   are 5 levels deep and need `../../../../../.schema/i18n-schema.json`, while module locales
   (`modules/*/locales/*/`) are 4 levels deep and need `../../../../.schema/i18n-schema.json`.

9. **Check for stuttering names (exported symbols repeating package name):**

   `revive/exported` detects this but is suppressed by the golangci-lint `comments` exclusion preset.
   Exported symbols should not repeat the package name (e.g., `theme.ThemeEngine` stutters, `theme.Engine` is correct).

   Detection:
   ```bash
   grep -rn "^func\|^type\|^const\|^var" --include="*.go" . | grep -v "_test.go" | grep -v ".sql.go"
   ```
   For each exported symbol, check if it starts with or contains the package name.
   Focus on `internal/` packages where naming is fully under project control.

   **Common patterns:**
   - `theme.ThemeEngine` → `theme.Engine`
   - `cache.CacheEntry` → `cache.Entry`
   - `config.ConfigOptions` → `config.Options`

10. **Check for incorrect doc comments on exported symbols:**

   `revive/exported` detects this but is suppressed by the golangci-lint `comments` exclusion preset.
   Go convention requires doc comments on exported symbols to start with the symbol's name.

   Detection (top-level declarations):
   ```bash
   grep -B1 "^func \|^type \|^var " --include="*.go" -rn . | grep -v "_test.go" | grep -v ".sql.go"
   ```

   Detection (grouped constants inside `const (...)` blocks):
   ```bash
   python3 -c "
   import re, os
   for root, dirs, files in os.walk('.'):
       dirs[:] = [d for d in dirs if d not in {'.git', 'vendor'}]
       for fname in files:
           if not fname.endswith('.go') or fname.endswith('_templ.go') or fname.endswith('.sql.go') or '_test.go' in fname:
               continue
           fpath = os.path.join(root, fname)
           with open(fpath) as f:
               lines = f.readlines()
           for i, line in enumerate(lines):
               # Match exported constant with a comment on the previous line
               m = re.match(r'\s+([A-Z]\w+)\s+', line)
               if not m:
                   continue
               name = m.group(1)
               if i > 0:
                   comment = lines[i-1].strip()
                   if comment.startswith('//') and not comment.startswith('// ' + name):
                       # Skip blank or section comments without leading symbol name
                       word_after = comment[3:].split()[0] if len(comment) > 3 and comment[3:].strip() else ''
                       if word_after and word_after[0].isupper() and word_after != name:
                           print(f'{fpath}:{i+1}: comment starts with \"{word_after}\" but symbol is \"{name}\"')
   "
   ```

   For each exported symbol with a doc comment, verify the comment starts with the symbol name.
   Skip auto-generated files (e.g., `icon_defs.go`, `icon_data.go` from templUI).

   **Common causes:**
   - Function/type renamed but comment kept the old name
   - Comment copied from another symbol
   - Prefixed comments that don't match (e.g., `// TwIf` for function `If`)
   - Group comment on a `const` block (e.g., `// Content restrictions`) that GoLand associates with the first exported constant in the group

11. **Check for struct initialization without field names:**

   `govet/composites` only flags unkeyed literals for types from other packages, and may miss some
   patterns (single-field structs, test files excluded from govet). Manual check catches additional cases.

   Detection (multi-field positional with string-first):
   ```bash
   grep -rn '{\s*"[^"]*"\s*,' --include="*.go" . | grep -v "_test.go" | grep -v ".sql.go"
   ```

   Detection (single-field unkeyed or variable-first — e.g., `image.Uniform{img.Color}`):
   ```bash
   grep -rnE '\b[A-Z][a-zA-Z]+\{[a-z][a-zA-Z.]+\}' --include="*.go" . | grep -v "_test.go" | grep -v ".sql.go" | grep -v ':'
   ```
   For each match, check if the struct has named fields — if so, the literal should use field names.
   Common stdlib types: `image.Uniform{C: color}`, `image.Point{X: 0, Y: 0}`.
   Skip type conversions (e.g., `DemoRestriction(value)`) which look similar but are not struct literals.

   Always use explicit field names — it prevents bugs when struct fields are reordered or new fields are added.

12. **Check for bool conditions always true/false:**

   No golangci-lint linter performs flow-sensitive analysis for variables that are always true/false on
   certain code paths. Look for these patterns:

   **a) Early-return before modification:**
   - Variable initialized with a default value (e.g., `x := true`)
   - Early-return branch that uses the variable before it could be modified
   - Fix: use the literal value directly on the early-return path, declare the variable after

   **b) Nil check inside non-nil guard (dead code):**
   - Outer `if x != nil` guard ensures `x` is non-nil
   - Inner `if x == nil` is always false — dead code
   - Fix: remove the inner nil check and its error-handling block

   **c) Closure-captured variable compared to literal (gocritic false positive):**
   - Variable declared with zero value (e.g., `var count int`)
   - Mutated inside a closure (e.g., `func() { count++ }`) passed to another function
   - Compared to a literal after the closure should have run (e.g., `if count != 1`)
   - gocritic sees the variable as always 0 (can't track closure mutations), flags `0 != 1` as always true
   - Fix: use a scoped variable for the expected value: `if want := 1; count != want`

13. **Check for unused exported constants/variables:**

   golangci-lint's `unused` only catches unexported symbols. For exported constants in `internal/` packages,
   manually check if they are referenced anywhere outside their definition file.

   Strategy:
   - Find files with exported constants: `grep -rn "^\tconst\|^const\|^\t[A-Z][a-zA-Z]*\s*=" --include="*.go" . | grep -v "_test.go" | grep -v ".sql.go"`
   - Focus on `internal/` packages (these can't be imported externally, so unused exports are dead code)
   - Skip auto-generated files (e.g., `icon_defs.go`, `icon_data.go` from templUI)
   - For each exported constant, grep for its usage: `grep -rn "ConstantName" --include="*.go" .`
   - If it only appears in its definition line (and possibly its doc comment), it's unused — remove it

   **Common patterns:**
   - Duplicate role/status constants across packages (e.g., `model.RoleEditor` vs `handler.RoleEditor`)
   - Leftover constants from removed features
   - Constants defined "for completeness" but never actually used

14. **Check for redundant named-type conversion of untyped constants:**

    `unconvert` does NOT catch conversions where an untyped constant (string literal, numeric literal)
    is explicitly converted to a named type (`template.HTML`, `template.JS`, `template.URL`, `template.CSS`)
    in a context where the untyped constant would auto-convert (return statement, assignment to typed variable).

    Detection:
    ```bash
    grep -rnE 'return template\.(HTML|JS|URL|CSS)\(["`'"'"'`]' --include="*.go" .
    ```

    For each match, check if the function return type or assignment target is already the named type.
    If so, the explicit conversion is redundant — untyped constants auto-convert to named types.

    **Common patterns:**
    - `return template.HTML("literal")` in a function returning `template.HTML`
    - `return template.JS("[]")` in a function returning `template.JS`

15. **Check for redundant struct type conversion with type aliases:**

    `unconvert` does NOT catch `NamedType(v)` where `v` is an anonymous struct (via a type alias
    defined with `=`) that is directly assignable to `NamedType` without explicit conversion.
    In Go, an anonymous struct value is assignable to a named struct type with identical fields.

    Detection:
    ```bash
    grep -rnE 'type \w+ = struct' --include="*.go" .
    ```

    For each type alias found, search for explicit conversions from the alias type to a named type:
    - Find where the alias is used in range/assignment
    - Check if the target uses `NamedType(variable)` conversion
    - If the named type has the same field structure, the conversion is redundant — direct assignment works

16. **Check for pointer to local variable (Go 1.26 `new(expr)`):**

    Go 1.26 extended `new()` to accept an expression, not just a type. The pattern `tmp := expr; &tmp`
    (creating a variable solely to take its address) can be replaced with `new(expr)`.

    Detection — find short variable declarations where the variable is only used as `&variable`:
    ```bash
    python3 -c "
    import re, os
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if d not in {'.git', 'vendor'}]
        for fname in files:
            if not fname.endswith('.go') or fname.endswith('_templ.go') or fname.endswith('.sql.go'):
                continue
            fpath = os.path.join(root, fname)
            with open(fpath) as f:
                lines = f.readlines()
            for i, line in enumerate(lines):
                m = re.match(r'\s+(\w+)\s*:=\s*(.+)', line)
                if not m:
                    continue
                var = m.group(1)
                if var in ('_', 'err', 'ok', 'ctx', 'mu', 'wg'):
                    continue
                # Search forward in function for usages
                addr_only = False
                for j in range(i+1, min(i+80, len(lines))):
                    l = lines[j]
                    if re.match(r'^func\b|^}\s*$', l.rstrip()) and not l.strip().startswith('}'):
                        break
                    has_addr = bool(re.search(r'&' + var + r'\b', l))
                    has_bare = bool(re.search(r'(?<!&)\b' + var + r'\b', l))
                    if has_bare:
                        addr_only = False
                        break
                    if has_addr:
                        addr_only = True
                if addr_only:
                    print(f'{fpath}:{i+1}: {var} := ... only used as &{var} — use new()')
    "
    ```

    For each match, verify:
    - The variable is not mutated through the pointer (e.g., `*position++` means the pointer itself is needed)
    - There are no mutex/ordering constraints requiring the copy before a later operation
    - Replace `tmp := expr; &tmp` with `new(expr)`

    **Exception:** Do NOT replace when the pointer is passed to a function that mutates through it
    and the mutation must persist (e.g., a counter incremented via `*ptr++`).

17. **Check for cross-method/cross-file code duplication:**

    golangci-lint `dupl` (threshold 200 tokens) misses these common patterns:

    **a) Identical methods on different receiver types:**
    ```bash
    # Find method names that appear on multiple types
    grep -rn "^func (.*) \w\+(" --include="*.go" . | grep -v "_test.go" | \
      sed 's/.*func ([^)]*) //' | sed 's/(.*//' | sort | uniq -d
    ```
    For each duplicate method name, compare the method bodies across receivers.
    If bodies are identical, extract to a standalone package-level function.

    **b) Identical test helper functions across packages:**
    ```bash
    # Find test helper functions duplicated across packages
    grep -rn "^func test\w\+(" --include="*_test.go" . | \
      sed 's/.*func //' | sed 's/(.*//' | sort | uniq -d
    ```
    For each match, compare function bodies. If identical, move to `internal/testutil/`.
    Already shared: `testutil.TestLogger()`, `testutil.TestLoggerSilent()`,
    `testutil.TestDB()`, `testutil.TestMemoryDB()`, `testutil.MinimalThemeFuncMap()`.

    **c) Identical code blocks within a file (below dupl threshold):**
    Look for 3+ structurally identical blocks (10-20 lines each) that vary only in:
    - Field names or table names (database reload functions)
    - Error messages or log messages (CRUD handlers)
    - Validation parameters (form parsing)
    Extract a generic helper parameterized by the varying parts.

    **Not duplicates** (skip these):
    - `testDB()` functions that create different schemas per package
    - Handler methods with similar structure but different business logic
    - CSS rules duplicated across self-contained themes

18. **Check for unused type parameters:**
    ```bash
    grep -rn "\[T any\]" --include="*.go" . | grep -v "_test.go"
    ```
    For each match, verify the type parameter `T` is actually used in:
    - Function parameters
    - Return type
    - Function body

    If `T` is never referenced, remove the type parameter.

19. **Check for redundant COALESCE in SQL:**
    ```bash
    grep -rn "COALESCE(" --include="*.go" . | grep -v "_test.go"
    ```
    Review each COALESCE usage:
    - If the column is `NOT NULL` with a default value, COALESCE is redundant
    - Cross-reference with migration files in `internal/store/migrations/`

20. **Check for potential resource leaks (sql.Rows):**
    ```bash
    grep -rn "QueryContext\|Query(" --include="*.go" . | grep -v "_test.go"
    ```
    Check if `rows` is passed to helper functions without `defer rows.Close()` in the caller.

21. **Report results:**
   - List all issues found with file:line references
   - Provide fix suggestions for each issue
   - Summary of total issues by category

## Expected Output

```
Code Quality Report
==================

Go Toolchain: OK (go1.X.X)

golangci-lint: X issues
  - errcheck:    X issues
  - errorlint:   X issues
  - staticcheck: X issues
  - unconvert:   X issues
  - unparam:     X issues
  - gocritic:    X issues
  - dupl:        X clone groups
  - usetesting:  X issues

Nil Safety:
  nilaway:       X issues

Import Sorting:
  Unsorted imports:       X issues
  Unnecessary group splits: X issues

CSS Analysis:
  Unresolved properties:      X issues
  Shorthand opportunities:    X issues
  Missing generic font family: X issues

JSON Schema:
  Broken $schema paths:       X issues

Semantic Analysis:
  Stuttering names:          X issues
  Incorrect doc comments:    X issues
  Unkeyed struct literals:   X issues
  Always true/false:         X issues
  Unused exported constants: X issues
  Unused type params:           X issues
  Redundant named-type conversion: X issues
  Redundant struct conversion (type alias): X issues
  Pointer to local variable (new(expr)):   X issues
  Cross-method/file duplication:           X issues
  Redundant COALESCE:           X issues
  Resource leaks:               X issues

Total: X issues found
```

## If Issues Found

For each issue, provide:
1. File path and line number
2. Description of the issue
3. How to fix it
4. Code example (before/after)

## Linter-Specific Issue Types

### unconvert (Redundant Type Conversion)
```go
// BAD: ConflictStrategy("skip") when ConflictSkip is already ConflictStrategy
assert.Equal(t, ConflictStrategy("skip"), ConflictSkip)

// GOOD: Compare the underlying value
assert.Equal(t, "skip", string(ConflictSkip))
```

### unparam (Unused Parameter)
```go
// BAD: opts is never used in the function body
func importMedia(ctx context.Context, opts ImportOptions, result *Result) {
    // opts is never referenced
}

// GOOD: Remove unused parameter
func importMedia(ctx context.Context, result *Result) {
    // ...
}
```

### errorlint (Direct Error Comparison / Non-Wrapping Format Verbs)
```go
// BAD: direct comparison — fails if err is wrapped
if err == sql.ErrNoRows {

// GOOD: use errors.Is for sentinel errors
if errors.Is(err, sql.ErrNoRows) {

// BAD: type assertion — fails if err is wrapped
if e, ok := err.(*MyError); ok {

// GOOD: use errors.As for type assertions
var e *MyError
if errors.As(err, &e) {

// BAD: non-wrapping format verb loses error chain
return fmt.Errorf("failed: %v", err)

// GOOD: use %w to preserve error chain
return fmt.Errorf("failed: %w", err)
```

### gocritic/weakCond (Condition Always True/False)
```go
// BAD: RoleAdmin is const "admin", so this is always false
const RoleAdmin = "admin"
if RoleAdmin != "admin" {
    t.Error("...")
}

// GOOD: Remove useless test or test actual behavior

// BAD: gocritic sees runCount as always 0 (can't track closure mutation)
var runCount int
m.Up = func(db *sql.DB) error { runCount++; return nil }
_ = r.InitAll(ctx)
if runCount != 1 {  // gocritic: condition is always true (0 != 1)
    t.Errorf("expected 1, ran %d times", runCount)
}

// GOOD: use scoped variable to avoid constant comparison
if want := 1; runCount != want {
    t.Errorf("expected %d, ran %d times", want, runCount)
}
```

### usetesting (Test Helper Replacements)
```go
// BAD: os.Setenv in test — leaked env var if test fails
os.Setenv("KEY", "value")
defer os.Unsetenv("KEY")

// GOOD: auto-restores after test
t.Setenv("KEY", "value")

// BAD: os.MkdirTemp with manual cleanup
dir, err := os.MkdirTemp("", "test-*")
if err != nil { t.Fatal(err) }
defer os.RemoveAll(dir)

// GOOD: auto-cleaned by testing framework
dir := t.TempDir()

// BAD: os.Chdir with manual restore
oldWd, _ := os.Getwd()
os.Chdir(dir)
defer os.Chdir(oldWd)

// GOOD: auto-restores working directory
t.Chdir(dir)

// BAD: os.CreateTemp in system temp dir
f, err := os.CreateTemp("", "test-*.db")

// GOOD: create in t.TempDir() for auto-cleanup
f, err := os.CreateTemp(t.TempDir(), "test-*.db")
```

### Unsorted Imports (goimports)
```go
// BAD: "errors" before "encoding/json" (alphabetical error)
// BAD: chi in separate group from project imports (3 groups)
import (
	"database/sql"
	"errors"
	"encoding/json"

	"github.com/go-chi/chi/v5"

	"github.com/olegiv/ocms-go/internal/store"
)

// GOOD: sorted alphabetically, 2 groups (stdlib + external)
import (
	"database/sql"
	"encoding/json"
	"errors"

	"github.com/go-chi/chi/v5"
	"github.com/olegiv/ocms-go/internal/store"
)
```

### Stuttering Names (manual)
```go
// BAD: exported symbol repeats the package name
package theme

const ThemeEngineTempl = "templ"
const ThemeEngineHTML  = "html"
type ThemeConfig struct { ... }

// GOOD: drop the package name prefix
package theme

const EngineTempl = "templ"
const EngineHTML  = "html"
type Config struct { ... }
```

Note: Also update all references (e.g., `theme.ThemeEngineTempl` → `theme.EngineTempl`).

### Incorrect Doc Comments (manual)
```go
// BAD: comment starts with "TwIf" but function is named "If"
// TwIf returns value if condition is true, otherwise an empty value of type T.
func If[T comparable](condition bool, value T) T {

// GOOD: comment starts with the function name
// If returns value if condition is true, otherwise an empty value of type T.
func If[T comparable](condition bool, value T) T {
```

Note: This often happens when functions are renamed but comments are not updated.

```go
// BAD: group comment on const block — GoLand associates it with first constant
const (
	// Content restrictions (block all modifications)
	RestrictionContentReadOnly DemoRestriction = "content_read_only"

// GOOD: comment starts with the constant name
const (
	// RestrictionContentReadOnly blocks all content modifications in demo mode.
	RestrictionContentReadOnly DemoRestriction = "content_read_only"
```

### Struct Initialization Without Field Names (manual)
```go
// BAD: positional — breaks if fields are reordered or added
items := []struct {
    Name string
    Slug string
}{
    {"Blog", "blog"},
    {"News", "news"},
}

// GOOD: explicit field names
items := []struct {
    Name string
    Slug string
}{
    {Name: "Blog", Slug: "blog"},
    {Name: "News", Slug: "news"},
}

// BAD: single-field struct without field name
draw.Draw(rgba, rect, &image.Uniform{img.Color}, image.Point{}, draw.Src)

// GOOD: explicit field name
draw.Draw(rgba, rect, &image.Uniform{C: img.Color}, image.Point{}, draw.Src)
```

### Bool Condition Always True/False (manual)

**Early-return before modification:**
```go
// BAD: banCheck is always true on the early-return path
banCheck := true
autoBan := true

rows, err := db.Query(query)
if err != nil {
    m.banCheckEnabled = banCheck  // always true here
    m.autoBanEnabled = autoBan    // always true here
    return nil
}
// ... loop that may modify banCheck/autoBan ...

// GOOD: use literals on early-return, declare variables after
rows, err := db.Query(query)
if err != nil {
    m.banCheckEnabled = true
    m.autoBanEnabled = true
    return nil
}

banCheck := true
autoBan := true
// ... loop that may modify banCheck/autoBan ...
```

**Nil check inside non-nil guard (dead code):**
```go
// BAD: activeTheme == nil is always false inside the non-nil branch
engine := theme.EngineTempl
if activeTheme != nil {
    engine = activeTheme.RenderEngine()
}
if engine == theme.EngineHTML {
    if activeTheme == nil {  // always false — we only get EngineHTML when activeTheme != nil
        http.Error(w, "Internal Server Error", 500)
        return
    }
    activeTheme.RenderPage(...)
}

// GOOD: remove the dead nil check
if engine == theme.EngineHTML {
    activeTheme.RenderPage(...)
}
```

**Closure-captured variable (gocritic false positive):**
```go
// BAD: gocritic can't track mutations through closures
var runCount int
migration.Up = func(db *sql.DB) error { runCount++; return nil }
_ = registry.InitAll(ctx)
if runCount != 1 {  // gocritic: 0 != 1 is always true
    t.Errorf("expected 1, ran %d", runCount)
}

// GOOD: scoped expected value avoids constant comparison
if want := 1; runCount != want {
    t.Errorf("expected %d, ran %d", want, runCount)
}
```

## Common nilaway Fixes

**Potential nil dereference after error check:**
```go
// Before (nilaway warning)
resp, err := client.Do(req)
if err != nil {
    return err
}
defer resp.Body.Close()  // nilaway: resp could be nil

// After (fixed)
resp, err := client.Do(req)
if err != nil {
    return err
}
if resp == nil {
    return fmt.Errorf("nil response")
}
defer resp.Body.Close()
```

**Slice access after length check with t.Errorf:**
```go
// Before (nilaway warning)
if len(items) != 1 {
    t.Errorf("expected 1, got %d", len(items))
}
if items[0].Name != "test" {  // nilaway: items could be nil

// After (fixed - use t.Fatalf to stop execution)
if len(items) != 1 {
    t.Fatalf("expected 1, got %d", len(items))
}
if items[0].Name != "test" {  // now safe
```

## Unused Type Parameter Fix

```go
// BAD: T is declared but never used in signature or body
func assignItems[T any](ids []int64, fn func(int64) error) []int64 {
    var result []int64
    for _, id := range ids {
        if fn(id) == nil {
            result = append(result, id)
        }
    }
    return result
}

// GOOD: Remove unused type parameter
func assignItems(ids []int64, fn func(int64) error) []int64 {
    var result []int64
    for _, id := range ids {
        if fn(id) == nil {
            result = append(result, id)
        }
    }
    return result
}
```

Note: Also update call sites to remove type arguments (e.g., `assignItems[int64](...)` → `assignItems(...)`).

## Resource Leak Fix

```go
// BAD: rows passed to helper without local defer
rows, err := db.QueryContext(ctx, query)
if err != nil {
    return nil
}
return scanRows(rows)  // if scanRows panics, leak occurs

// GOOD: always defer close in caller
rows, err := db.QueryContext(ctx, query)
if err != nil {
    return nil
}
defer func() { _ = rows.Close() }()
return scanRows(rows)
```

Note: `rows.Close()` is idempotent - calling it twice is safe.

## Unresolved CSS Custom Property Fix

```css
/* BAD: --dev-mono is not defined (actual property is --dev-font-mono) */
.form-control {
    font-family: var(--dev-mono);
}

/* GOOD: use the actual defined property name */
.form-control {
    font-family: var(--dev-font-mono);
}

/* BAD: --font-size-small is not defined anywhere */
.footer-privacy-link {
    font-size: var(--font-size-small);
}

/* GOOD: use a literal value if no custom property exists */
.footer-privacy-link {
    font-size: 0.875rem;
}
```

Common causes: property renamed but not all usages updated, typo in property
name, property from a design system never added to the theme.

### CSS Margin/Padding Shorthand (manual)
```css
/* BAD: separate side properties */
.sub-menu .sub-menu.flip-left {
    margin-left: 0;
    margin-right: 4px;
}

/* GOOD: collapsed into shorthand */
.sub-menu .sub-menu.flip-left {
    margin: 0 4px 0 0;
}

/* BAD: separate top and bottom */
.dev-prose h1, .dev-prose h2 {
    margin-top: 2em;
    margin-bottom: 0.75em;
}

/* GOOD: collapsed into shorthand */
.dev-prose h1, .dev-prose h2 {
    margin: 2em 0 0.75em;
}
```

Shorthand order: `margin: <top> <right> <bottom> <left>` (clockwise).
When left equals right: `margin: <top> <right> <bottom>`.
When top equals bottom and left equals right: `margin: <top-bottom> <left-right>`.

### Redundant Named-Type Conversion of Untyped Constants (manual)
```go
// BAD: template.HTML() wrapping a string literal is redundant
// when the function already returns template.HTML
func renderFooterLink() template.HTML {
    return template.HTML(`<a href="#">Link</a>`)
}

// GOOD: untyped string constants auto-convert to named types
func renderFooterLink() template.HTML {
    return `<a href="#">Link</a>`
}
```

Note: This only applies to **untyped constants** (string/numeric literals).
Conversions from **typed values** (e.g., `template.HTML(builder.String())` where
`.String()` returns typed `string`) are NOT redundant — Go requires explicit
conversion between named types and their underlying type.

### Redundant Struct Conversion with Type Alias (manual)
```go
// Type alias creates an anonymous struct type
type anonOpt = struct {
    Code string
    Name string
}

type LangOption struct {
    Code string
    Name string
}

// BAD: explicit conversion is redundant — anonymous structs are
// directly assignable to named types with identical fields
for i, o := range opts {
    result[i] = LangOption(o)
}

// GOOD: direct assignment works
for i, o := range opts {
    result[i] = o
}
```

Note: This applies when the source is an anonymous struct (often via type alias `=`)
and the target is a named struct with the same fields. Go allows direct assignment
because one of the types is unnamed. `unconvert` does not detect this.

### Pointer to Local Variable — Use `new(expr)` (Go 1.26+, manual)
```go
// BAD: temporary variable created solely to take its address
id := user.ID
return &id

// GOOD: Go 1.26 new(expr) creates a pointer to the value
return new(user.ID)

// BAD: multi-line temp variable for struct field
t := page.PublishedAt.Time
exportPage.PublishedAt = &t

// GOOD: inline with new()
exportPage.PublishedAt = new(page.PublishedAt.Time)

// BAD: temp for function result
opt := convertOption(*lang)
return &opt

// GOOD: inline with new()
return new(convertOption(*lang))
```

**Exception:** Do NOT use `new()` when the pointer is passed to a function that
mutates through it and the mutation must persist across iterations (e.g., a counter
`*position++`). Also skip when mutex/lock ordering requires the copy to happen
before an unlock (e.g., copy value under lock, return pointer after unlock).

### Cross-Method/Cross-File Duplication (manual)

**Identical methods on different receivers:**
```go
// BAD: loadMenu duplicated on FrontendHandler and FormsHandler
func (h *FrontendHandler) loadMenu(slug, path, lang string) []MenuItem { ... }
func (h *FormsHandler) loadMenu(slug, path, lang string) []MenuItem { ... }

// GOOD: standalone package-level function
func loadMenu(ms *service.MenuService, slug, path, lang string) []MenuItem { ... }
```

**Identical test helpers across packages:**
```go
// BAD: testLogger() duplicated in theme/manager_test.go, scheduler/registry_test.go
func testLogger() *slog.Logger {
    return slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: slog.LevelError}))
}

// GOOD: use shared testutil
import "github.com/olegiv/ocms-go/internal/testutil"
logger := testutil.TestLoggerSilent()
```

**Structurally identical blocks varying only in parameters:**
```go
// BAD: 3 identical reload functions varying only in query/mutex/field
func (m *Module) reloadBannedIPs() error { /* 22 lines */ }
func (m *Module) reloadAutoBanPaths() error { /* 22 lines */ }
func (m *Module) reloadWhitelist() error { /* 22 lines */ }

// GOOD: generic helper parameterized by varying parts
func (m *Module) reloadPatterns(query string, mu *sync.RWMutex, dest *[]string) error { ... }
func (m *Module) reloadBannedIPs() error { return m.reloadPatterns(q, &m.bannedMu, &m.bannedPatterns) }
```

### Missing Generic Font Family (manual)
```css
/* BAD: no generic fallback — if var() fails, browser has no hint */
.form-input {
    font-family: var(--font-family);
}
.code-block {
    font-family: var(--dev-font-mono);
}

/* GOOD: generic family after the custom property */
.form-input {
    font-family: var(--font-family), sans-serif;
}
.code-block {
    font-family: var(--dev-font-mono), monospace;
}
```

Choose the generic family based on the property's purpose:
- Body/UI fonts → `sans-serif`
- Serif heading fonts → `serif`
- Code/monospace fonts → `monospace`
