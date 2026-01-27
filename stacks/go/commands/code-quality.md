Scan the project for code quality issues and warnings.

## Checks Performed

1. **Go Toolchain Version Mismatch**
   - Check if `go version` matches the compiler version
   - If mismatch found, STOP and report the issue

2. **Comprehensive Static Analysis (golangci-lint)**
   - Runs multiple linters in a single pass
   - Catches: unhandled errors, unused parameters, redundant type conversions,
     constant comparisons, duplicate code, and more
   - Configuration in `.golangci.yml`

3. **Nil Safety Analysis**
   - Run `nilaway ./...` for potential nil pointer dereferences

4. **Semantic Analysis** (manual checks if golangci-lint misses them)
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
   - `govet` - suspicious constructs
   - `staticcheck` - comprehensive static analysis
   - `unconvert` - unnecessary type conversions
   - `unparam` - unused function parameters
   - `gocritic` - bugs, performance, style (including constant comparisons)
   - `dupl` - code clone detection
   - `gocyclo` - cyclomatic complexity
   - `misspell` - spelling mistakes

3. **Run nil safety analysis:**
   ```bash
   nilaway ./...
   ```
   If nilaway is not installed:
   ```bash
   go install go.uber.org/nilaway/cmd/nilaway@latest
   ```

4. **Check for redundant COALESCE in SQL:**
   ```bash
   grep -rn "COALESCE(" --include="*.go" . | grep -v "_test.go"
   ```
   Review each COALESCE usage:
   - If the column is `NOT NULL` with a default value, COALESCE is redundant
   - Cross-reference with migration files in `internal/store/migrations/`

5. **Check for potential resource leaks (sql.Rows):**
   ```bash
   grep -rn "QueryContext\|Query(" --include="*.go" . | grep -v "_test.go"
   ```
   Check if `rows` is passed to helper functions without `defer rows.Close()` in the caller.

6. **Report results:**
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
  - staticcheck: X issues
  - unconvert:   X issues
  - unparam:     X issues
  - gocritic:    X issues
  - dupl:        X clone groups

Nil Safety:
  nilaway:       X issues

Semantic Analysis:
  Redundant COALESCE:  X issues
  Resource leaks:      X issues

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

### gocritic/weakCond (Condition Always True/False)
```go
// BAD: RoleAdmin is const "admin", so this is always false
const RoleAdmin = "admin"
if RoleAdmin != "admin" {
    t.Error("...")
}

// GOOD: Remove useless test or test actual behavior
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
