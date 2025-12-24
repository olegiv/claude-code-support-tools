Scan the project for code quality issues and warnings.

## Checks Performed

1. **Go Toolchain Version Mismatch**
   - Check if `go version` matches the compiler version
   - If mismatch found, STOP and report the issue

2. **Static Analysis**
   - Run `go vet ./...` for common issues
   - Run `staticcheck ./...` for extended analysis
   - Run `errcheck ./...` for unhandled errors

3. **Nil Safety Analysis**
   - Run `nilaway ./...` for potential nil pointer dereferences
   - Detects nil flows from source to dereference points
   - Install if missing: `go install go.uber.org/nilaway/cmd/nilaway@latest`

4. **Duplicate Code Detection**
   - Run `dupl -t 50 .` to find code clones
   - Threshold of 50 tokens catches significant duplicates
   - Install if missing: `go install github.com/mibk/dupl@latest`

5. **Semantic Analysis** (manual checks)
   - Condition is always false/true (constant comparisons)
   - Empty slice declaration using literal
   - Variable collides with imported package name
   - Redundant COALESCE in SQL queries

## Steps

1. **Check Go toolchain:**
   ```bash
   go version
   $(go env GOTOOLDIR)/compile -V
   ```
   If versions don't match, report error and provide fix instructions.

2. **Run static analysis tools:**
   ```bash
   go vet ./...
   staticcheck ./...
   errcheck ./...
   ```

3. **Run nil safety analysis:**
   ```bash
   nilaway ./...
   ```
   If nilaway is not installed, install it first:
   ```bash
   go install go.uber.org/nilaway/cmd/nilaway@latest
   ```

4. **Run duplicate code detection:**
   ```bash
   dupl -t 50 .
   ```
   If dupl is not installed, install it first:
   ```bash
   go install github.com/mibk/dupl@latest
   ```
   Report clone groups found. Duplicates in test files are lower priority.

5. **Check for constant comparisons (condition always false):**
   - Find constant definitions and their values
   - Find tests comparing constants to literal values
   - Report any useless comparisons

6. **Check for duplicate string literals:**
   ```bash
   grep -oE '"/[^"]*"' --include="*.go" -r . | sort | uniq -c | sort -rn | awk '$1 >= 2'
   ```
   Report string literals (especially route patterns) appearing 2+ times that should be extracted to constants.

   **Example fix:**
   ```go
   // BAD: Duplicated route patterns
   r.Get("/users", usersHandler.List)
   r.Get("/users/{id}", usersHandler.Edit)
   r.Post("/users", usersHandler.Create)

   // GOOD: Extract to constants
   const (
       routeUsers   = "/users"
       routeUsersID = "/users/{id}"
   )
   r.Get(routeUsers, usersHandler.List)
   r.Get(routeUsersID, usersHandler.Edit)
   r.Post(routeUsers, usersHandler.Create)
   ```

7. **Check for empty slice literals:**
   ```bash
   grep -rn ":= \[\][a-zA-Z.]*{}" --include="*.go" .
   ```
   Report any `x := []Type{}` that should be `var x []Type`

8. **Check for package name collisions:**
   - Find files importing common packages (url, http, json, errors, etc.)
   - Check if those package names are used as variables
   - Report collisions

9. **Check for redundant COALESCE in SQL:**
   ```bash
   grep -rn "COALESCE(" --include="*.go" . | grep -v "_test.go"
   ```
   Review each COALESCE usage:
   - If the column is `NOT NULL` with a default value, COALESCE is redundant
   - Cross-reference with migration files in `internal/store/migrations/`
   - Check column definitions: `NOT NULL DEFAULT ''` means COALESCE is unnecessary

   **Example fix:**
   ```sql
   -- BAD: meta_title is NOT NULL DEFAULT ''
   SELECT COALESCE(meta_title, '') FROM pages

   -- GOOD: Column can never be NULL
   SELECT meta_title FROM pages
   ```

10. **Report results:**
    - List all issues found with file:line references
    - Provide fix suggestions for each issue
    - Summary of total issues by category

## Package Names to Check for Collisions

Standard library: `bytes`, `context`, `crypto`, `encoding`, `errors`, `fmt`, `hash`, `html`, `http`, `io`, `json`, `log`, `math`, `net`, `os`, `path`, `reflect`, `regexp`, `runtime`, `sort`, `sql`, `strconv`, `strings`, `sync`, `template`, `testing`, `time`, `unicode`, `url`, `xml`

## Expected Output

```
Code Quality Report
==================

Go Toolchain: OK (go1.25.5)

Static Analysis:
  go vet:      0 issues
  staticcheck: 0 issues
  errcheck:    0 issues

Nil Safety:
  nilaway:     0 issues

Duplicate Code:
  dupl:        0 clone groups (or N clone groups in test files)

Semantic Analysis:
  Constant comparisons:     0 issues
  Empty slice literals:     0 issues (excluding generated files)
  Package name collisions:  0 issues
  Redundant COALESCE:       0 issues

Total: 0 issues found
```

## If Issues Found

For each issue, provide:
1. File path and line number
2. Description of the issue
3. How to fix it
4. Code example (before/after)

### Common nilaway Fixes

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

Note: Generated files (*.sql.go, etc.) are excluded from empty slice literal checks.
