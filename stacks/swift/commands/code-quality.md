---
description: "Scan the iOS project for code quality issues and warnings"
---

Scan the project for code quality issues and warnings.

Use the **@ios-quality-auditor** agent to perform a comprehensive code quality audit of the iOS project.

## CRITICAL: Latest Versions Required

The auditor **enforces** that ALL tools and dependencies use the **latest stable, non-vulnerable versions**:
- Xcode, Swift, iOS SDK - MUST be latest stable
- All SPM/CocoaPods/Carthage dependencies - MUST be latest stable, non-vulnerable
- Any outdated or vulnerable version is flagged as a **Critical Issue**

## What This Command Does

The ios-quality-auditor agent will:

1. **SDK Version Check** - Verify iOS SDK, Xcode, and Swift are latest stable versions
2. **Dependency Audit** - Ensure ALL dependencies are latest stable, non-vulnerable versions
3. **Build Warnings** - Run xcodebuild and capture all warnings
4. **Static Analysis** - Identify code issues:
   - Memory leak detection (retain cycles, missing [weak self], strong delegates)
   - Force unwraps (!) and force try (try!) usage
   - Unused code (unused variables, imports, functions, properties)
   - Dead code (assignments never read, redundant code)
   - Thread safety issues (UI updates not on main thread)
   - Resource issues (hardcoded strings, missing localizations)
5. **Swift Best Practices** - Check for proper Swift idioms and patterns
6. **SwiftUI Quality** - Verify state management, view composition, and performance
7. **Architecture Review** - Validate MVVM pattern adherence
8. **Info.plist Audit** - Verify permissions and configurations
9. **Test Coverage Audit** - Verify all tests exist and identify redundant tests
10. **Test Quality Audit** - Identify problematic test patterns

## Workflow

The agent follows a strict read-only audit workflow:

1. **Phase 1 - Audit** - Analyze code without making changes
2. **Phase 2 - Report** - Present findings with severity levels
3. **Phase 3 - Fix Plan** - Propose specific fixes for approval
4. **Phase 4 - Apply** - Only apply fixes after explicit user approval

## Output

The agent provides a structured report with:
- Audit Summary (SDK, dependencies, warnings count)
- Critical Issues (outdated tools/SDKs, vulnerable dependencies, security vulnerabilities, crash risks, memory leaks)
- Warnings (deprecated APIs, force unwraps, potential bugs)
- Improvements (code quality suggestions)
- Recommendations (optional enhancements)
- Test Coverage (missing tests, redundant tests, suggestions)
- Proposed Fix Plan (awaiting approval)

## Important Notes

- **No auto-fix:** The agent will NOT modify any code without your explicit approval.
- **No auto-commit:** The agent will NEVER commit or push changes.
- **Review first:** You will see the complete report and fix plan before any changes are made.
- **You decide:** Approve all, some, or none of the proposed fixes.
