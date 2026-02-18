# Integration Tests

This directory contains Flutter integration tests that work on **both web and mobile platforms**.

## Overview

These tests use Flutter's `integration_test` package, which provides:

- ✅ **Native widget testing** - works with Flutter's rendering engine
- ✅ **Cross-platform** - same tests run on web, iOS, and Android
- ✅ **Real app behavior** - tests the actual app, not just UI
- ✅ **Works with CanvasKit** - no DOM limitations like Playwright

## Test Structure

```
integration_test/
├── app_test.dart            # Main test suite (runs all tests)
├── auth_test.dart           # Authentication flow tests (8 tests)
├── profile_setup_test.dart  # Profile setup feature tests (3 tests)
└── tree_test.dart           # Family tree feature tests (12 tests)
```

## Running Tests

### Web (Chrome)

```bash
flutter test integration_test/app_test.dart -d chrome
```

### Android Emulator

```bash
flutter test integration_test/app_test.dart -d android
```

### iOS Simulator (macOS only)

```bash
flutter test integration_test/app_test.dart -d iphone
```

### Run Specific Test File

```bash
# Just auth tests
flutter test integration_test/auth_test.dart -d chrome

# Just profile setup tests
flutter test integration_test/profile_setup_test.dart -d chrome

# Just tree tests
flutter test integration_test/tree_test.dart -d chrome
```

### Run with verbose output

```bash
flutter test integration_test/app_test.dart -d chrome --verbose
```

## Test Coverage

### Authentication Tests (auth_test.dart)

1. ✅ App loads and shows landing/login screen
2. ✅ Sign up flow - complete registration
3. ✅ Sign in flow - login with credentials
4. ✅ Form validation - empty fields
5. ✅ Form validation - invalid email format
6. ✅ Form validation - password too short
7. ✅ Navigation - switch between login and signup
8. ✅ Password visibility toggle

### Family Tree Tests (tree_test.dart)

1. ✅ Navigation - access family tree after login
2. ✅ Tree UI - renders person cards
3. ✅ Add member - navigation to add member screen
4. ✅ Add member - form validation
5. ✅ Search - search functionality exists
6. ✅ Profile - view person details
7. ✅ Relationships - display family connections
8. ✅ Bottom navigation - switch between screens
9. ✅ Invite - share family tree link
10. ✅ Edit profile - navigate to edit screen
11. ✅ Performance - tree renders within acceptable time
12. ✅ Offline mode - handles no connection gracefully

## Best Practices

### Writing Tests

1. **Use `pumpAndSettle()`** - waits for all animations/async operations
2. **Add timeouts** - `pumpAndSettle(Duration(seconds: 3))` for API calls
3. **Check widget existence** - `if (widget.evaluate().isNotEmpty)` before tapping
4. **Use descriptive reasons** - helps debugging when tests fail
5. **Test both happy path and error cases**

### Test Data

- Tests use random email addresses to avoid conflicts
- Default test credentials: `test@example.com` / `test123`
- Create test users in Supabase manually for login tests

### Debugging Failed Tests

```bash
# Run with verbose logging
flutter test integration_test/auth_test.dart -d chrome --verbose

# Run single test
flutter test integration_test/auth_test.dart -d chrome --plain-name "Sign up flow"
```

## Comparison with Playwright Tests

| Feature           | Playwright E2E                  | Flutter Integration Tests   |
| ----------------- | ------------------------------- | --------------------------- |
| Platform Support  | Web only                        | Web + iOS + Android         |
| Flutter CanvasKit | ❌ Blocked                      | ✅ Works natively           |
| DOM Access        | Required                        | Not needed                  |
| Speed             | Slower (browser automation)     | Faster (native)             |
| Setup Complexity  | High (separate Node.js project) | Low (built-in)              |
| Debugging         | Browser DevTools                | Flutter DevTools + IDE      |
| CI/CD             | Requires headless browser       | Flutter test infrastructure |

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.24.0"
      - run: flutter pub get
      - run: flutter test integration_test -d web-server
```

### Local Test Runner Script (PowerShell)

```powershell
# Run all tests on web
flutter test integration_test/app_test.dart -d chrome

# Run and generate report
flutter test integration_test/app_test.dart -d chrome --reporter=expanded > test_results.txt
```

## Troubleshooting

### "No device found"

```bash
# List available devices
flutter devices

# Start Chrome for web testing
flutter devices
# Look for "Chrome (web)"
```

### Tests timeout

- Increase timeout in `pumpAndSettle(Duration(seconds: 10))`
- Check if backend is running (port 3000)
- Verify Supabase connection in `.env`

### Widget not found

- Add longer wait times: `await tester.pumpAndSettle(Duration(seconds: 3))`
- Use `find.textContaining()` instead of exact match
- Check if auth redirect is enabled/disabled

### Supabase connection errors

- Verify `.env` file exists in `app/` directory
- Check `SUPABASE_URL` and `SUPABASE_ANON_KEY`
- Ensure migrations are applied to database

## Next Steps

1. **Add more test coverage**
   - Relationship creation tests
   - Search functionality tests
   - Admin panel tests (if applicable)
   - Error handling scenarios

2. **Set up CI/CD**
   - Add GitHub Actions workflow
   - Run tests on every PR
   - Generate test reports

3. **Create test data fixtures**
   - Script to create test users
   - Seed test family tree data
   - Clean up test data after runs

4. **Performance testing**
   - Measure rendering time for large trees
   - Test with many family members
   - Memory leak detection

## Resources

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Integration Test Package](https://pub.dev/packages/integration_test)
- [Flutter Testing Best Practices](https://docs.flutter.dev/cookbook/testing/integration/introduction)
