Run instrumented tests (Espresso + Compose UI tests) on connected device.

## Steps

1. Check if device/emulator is connected: `adb devices`
2. If no device, inform user and stop
3. Run instrumented tests with Gradle
4. Parse test output for results
5. Report test results summary with link to HTML report

## Commands

**Check Connected Devices:**
```bash
adb devices
```

**Run Instrumented Tests:**
```bash
./gradlew connectedAndroidTest
```

## Output

- Test report: `app/build/reports/androidTests/connected/index.html`
- Tests run on physical device or emulator

## Notes

- Requires connected Android device or running emulator
- Tests are in `app/src/androidTest/`
- Uses AndroidX Test + Espresso + Compose UI Test
- Takes longer than unit tests (runs on device)
- Report device name and Android version used for testing
