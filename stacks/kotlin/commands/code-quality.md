Scan the project for code quality issues and warnings.

Use the **@android-quality-auditor** agent to perform a comprehensive code quality audit of the Android project.

## What This Command Does

The android-quality-auditor agent will:

1. **SDK Version Check** - Verify compileSdk, targetSdk, and minSdk are current
2. **Gradle Configuration** - Verify Gradle wrapper version and plugin compatibility
3. **Dependency Audit** - Check for outdated or vulnerable dependencies
4. **Static Analysis** - Run lint and identify code issues:
   - Memory leak detection (static field leaks, context leaks)
   - Unused code (unused symbols, variables, imports, parameters, theme colors/properties, unused functions)
   - Dead code (assignments never read, redundant overrides, empty methods, methods only calling super)
   - Constant parameters (parameters always passed the same value at all call sites)
   - Constant conditions (always-true/false expressions)
   - Property access syntax (use `obj.property = value` instead of `obj.setProperty(value)`)
   - Resource issues (hardcoded strings, missing resources)
5. **Kotlin Best Practices** - Check for proper Kotlin idioms and patterns
6. **Compose Quality** - Verify Jetpack Compose patterns and prevent recomposition issues
7. **Architecture Review** - Validate MVVM pattern adherence
8. **ProGuard/R8 Audit** - Verify ProGuard rules match actual dependencies and aren't overly broad
9. **Test Coverage Audit** - Verify all tests exist and identify redundant tests
10. **Test Quality Audit** - Identify problematic test patterns:
    - Redundant assertions comparing incompatible types (sealed class subtypes)
    - Tests that verify language guarantees rather than application logic
    - Always-true singleton identity checks (`assertTrue(x === y)` on `data object` singletons)
    - Always-passing tests (tautologies)
    - Duplicate test coverage
    - **Backtick-quoted function names** - Test functions using backticks (e.g., `` fun `test name`() ``) are not allowed in Android projects and cause build errors

## Workflow

The agent follows a strict read-only audit workflow:

1. **Phase 1 - Audit** - Analyze code without making changes
2. **Phase 2 - Report** - Present findings with severity levels
3. **Phase 3 - Fix Plan** - Propose specific fixes for approval
4. **Phase 4 - Apply** - Only apply fixes after explicit user approval

## Output

The agent provides a structured report with:
- 📊 Audit Summary
- 🔴 Critical Issues (security vulnerabilities, crash risks)
- 🟠 Warnings (deprecated APIs, potential bugs)
- 🟡 Improvements (code quality suggestions)
- 🟢 Recommendations (optional enhancements)
- 🧪 Test Coverage (missing tests, redundant tests, suggestions)
- 🔧 Proposed Fix Plan (awaiting approval)

## Important Notes

- **No auto-fix:** The agent will NOT modify any code without your explicit approval.
- **No auto-commit:** The agent will NEVER commit or push changes.
- **Review first:** You will see the complete report and fix plan before any changes are made.
- **You decide:** Approve all, some, or none of the proposed fixes.
