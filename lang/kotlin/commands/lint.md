Run Android Lint to check for code quality issues.

## Steps

1. Run Lint analysis with Gradle
2. Wait for completion
3. Parse lint output for issues
4. Report issue counts by severity (errors, warnings, info)
5. Provide link to HTML report
6. Highlight critical issues that need fixing

## Commands

**Run Lint:**
```bash
./gradlew lint
```

## Output

- HTML report: `app/build/reports/lint-results-debug.html`
- XML report: `app/build/reports/lint-results-debug.xml`
- Text report: `app/build/reports/lint-results-debug.txt`

## What Lint Checks

- Unused resources
- Missing translations
- Accessibility issues
- Performance problems
- Security vulnerabilities
- API usage issues
- Layout optimization
- Memory leaks (static Context references)

## Notes

- Lint is built into Android Gradle Plugin
- Reports are generated in `app/build/reports/`
- Focus on fixing errors first, then warnings
- Some warnings can be suppressed if intentional
- Lint runs faster than full build
