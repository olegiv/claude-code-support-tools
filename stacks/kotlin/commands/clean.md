---
description: "Clean build artifacts and caches"
allowed-tools: Bash
---

Clean build artifacts and caches.

## Steps

1. Run Gradle clean command
2. Wait for completion
3. Report cleaned directories
4. Optionally suggest rebuilding after clean

## Commands

**Clean Build:**
```bash
./gradlew clean
```

## What Gets Cleaned

- `app/build/` directory (all build outputs)
- `.gradle/` cache files
- Compiled classes and resources
- Generated code

## Notes

- Use this when builds behave strangely
- After clean, need to rebuild: `./gradlew assembleDebug`
- Clean removes all APKs and build artifacts
- Gradle configuration cache is preserved
