Run Detekt static analysis on the Kotlin codebase.

## What This Command Does

Runs Detekt to perform static code analysis and identify:
- Unused variables and parameters
- Assigned values that are never read
- Variables that could be vals
- Unnecessary let/apply calls
- Code complexity issues
- Naming convention violations

## Usage

```bash
# Run Detekt
./gradlew detekt

# Run with HTML report
./gradlew detekt
# Report: app/build/reports/detekt/detekt.html
```

## Setup (if not configured)

If Detekt is not yet configured in the project, add it:

### 1. Add to `gradle/libs.versions.toml`:
```toml
[versions]
detekt = "1.23.8"

[plugins]
detekt = { id = "io.gitlab.arturbosch.detekt", version.ref = "detekt" }
```

### 2. Add to `app/build.gradle.kts`:
```kotlin
plugins {
    // ... existing plugins
    alias(libs.plugins.detekt)
}

detekt {
    buildUponDefaultConfig = true
    config.setFrom(files("$projectDir/detekt.yml"))
    parallel = true
}
```

### 3. Create `app/detekt.yml`:
Copy the template from `.claude/shared/stacks/kotlin/templates/detekt.yml`

## Key Rules for Android/Compose

The recommended configuration:
- **Enabled:** UnusedPrivateMember, UnusedParameter, VarCouldBeVal, IgnoredReturnValue
- **Adjusted for Compose:** LongMethod (160), LongParameterList (18 params)
- **Disabled:** MagicNumber (noisy for colors), MaxLineLength (IDE handles), TooGenericExceptionCaught (needed for Android)

## Fixing Issues

When Detekt reports issues:
1. Review the report at `app/build/reports/detekt/detekt.html`
2. Fix issues or adjust thresholds in `detekt.yml` if rules are too strict
3. Re-run `./gradlew detekt` to verify fixes
