# E2E Testing Status - MyFamilyTree

**Date**: February 16, 2026  
**Application Status**: ✅ RUNNING  
**Test Status**: ⚠️ BLOCKED BY FLUTTER WEB ARCHITECTURE

---

## 🎯 Application Status

✅ **Backend**: Running on http://localhost:3000  
✅ **Frontend**: Running on http://localhost:5500  
✅ **Authentication**: Email/password working  
✅ **Router**: Configured with hash-based routing (`/#/login`, `/#/signup`)

---

## ⚠️ E2E Testing Issue: Flutter Web CanvasKit Renderer

### The Problem

Playwright E2E tests **cannot access UI elements** in the current Flutter Web application due to architectural incompatibility:

1. **Flutter Web uses CanvasKit renderer**
   - Renders all UI to `<canvas>` elements
   - UI elements (buttons, text, inputs) are drawn as pixels, not DOM nodes

2. **Playwright requires DOM elements**
   - Queries like `page.locator('text=Create Account')` look for DOM nodes
   - `input[type="email"]` doesn't exist in the DOM
   - Everything is inside `<canvas>` and `<flt-glass-pane>` custom elements

3. **Test Results**
   ```
   Current URL: http://localhost:5500/#/signup
   Create Account count: 0
   Sign Up count: 0
   Email input count: 0
   ```

   - Playwright navigates successfully
   - Page loads correctly
   - But NO UI elements are found ❌

### Why This Happens

Flutter Web CanvasKit:

```html
<body>
  <flutter-view>
    <flt-glass-pane>
      <canvas></canvas>
      <!-- ALL UI rendered here as pixels -->
    </flt-glass-pane>
  </flutter-view>
</body>
```

What Playwright sees:

- Empty canvas
- No `<button>`, `<input>`, `<div>` with text
- No semantic HTML structure

---

## 💡 Solutions

### Option 1: Flutter Integration Tests (✅ Recommended)

**Use Flutter's built-in integration testing instead of Playwright**

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signup flow', (tester) async {
    await tester.pumpWidget(MyApp());

    // Find widgets directly - works with Canvas rendering!
    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('Account created'), findsOneWidget);
  });
}
```

**Run**:

```powershell
cd app
flutter test integration_test/app_test.dart -d chrome
```

**Advantages**:

- ✅ Native Flutter testing - full widget access
- ✅ Works with CanvasKit renderer
- ✅ Same API as widget tests
- ✅ Can run on web, mobile, desktop

---

### Option 2: Swtich to HTML Renderer (⚠️ Deprecated)

**Temporarily use HTML renderer for Playwright tests**

```powershell
cd app
flutter run -d web-server --web-port=5500 --web-renderer html
```

**Result**:

- ✅ Creates real DOM elements
- ✅ Playwright can find inputs, buttons, text
- ⚠️ HTML renderer is **officially deprecated** by Flutter
- ⚠️ Warning message on startup

**When to use**: Quick validation before migrating to integration tests

---

### Option 3: Add Semantic Labels (🔧 Complex)

**Add accessibility labels to all interactive elements**

```dart
// Before
ElevatedButton(
  onPressed: _signUp,
  child: Text('Sign Up'),
)

// After
Semantics(
  label: 'Sign Up Button',
  button: true,
  child: ElevatedButton(
    onPressed: _signUp,
    child: Text('Sign Up'),
  ),
)
```

**Update Playwright tests**:

```typescript
// Instead of:
await page.click('button:has-text("Sign Up")');

// Use:
await page.click('[aria-label="Sign Up Button"]');
```

**Advantages**:

- ✅ Works with CanvasKit
- ✅ Improves accessibility
- ❌ Requires updating every interactive widget
- ❌ Requires updating all tests

---

### Option 4: Visual Regression Testing (📸 Alternative)

**Test UI visually instead of DOM interaction**

```typescript
test("signup page looks correct", async ({ page }) => {
  await page.goto("/#/signup");
  await page.waitForTimeout(3000); // Let Flutter render

  // Compare screenshot to baseline
  expect(await page.screenshot()).toMatchSnapshot("signup-page.png");
});
```

**Advantages**:

- ✅ Works with CanvasKit
- ✅ Catches visual regressions
- ❌ Can't test interactions (form submission, etc.)
- ❌ Brittle (fonts, timing can cause failures)

---

## 📋 Current Test Files

### `/e2e-tests/tests/auth.spec.ts`

- 9 authentication tests
- **Status**: ❌ All failing (cannot find UI elements)
- Tests: signup, login, validation, navigation

### `/e2e-tests/tests/tree.spec.ts`

- 13 tree management tests
- **Status**: ❌ All failing (cannot find UI elements)
- Tests: add members, edit, delete, search

### `/e2e-tests/tests/debug.spec.ts`

- Debug helper to inspect rendered HTML
- **Status**: ✅ Working
- Shows: URLs, element counts, page content

---

## 🚀 Recommended Next Steps

1. **Immediate** (Today):
   - Keep application running (backend + frontend)
   - Application is fully functional for manual testing
   - E2E tests are paused pending architecture decision

2. **Short Term** (This Week):
   - **Decision**: Choose Flutter Integration Tests OR HTML Renderer
   - If Integration Tests: Create `integration_test/` directory in `app/`
   - If HTML Renderer: Accept deprecation warning for testing

3. **Medium Term** (This Sprint):
   - Migrate 22 Playwright tests to Flutter integration tests
   - Or keep Playwright but switch renderer + update selectors
   - Add semantic labels for accessibility (good practice regardless)

4. **Long Term**:
   - Build comprehensive integration test suite
   - Add golden screenshot tests
   - Integrate tests into CI/CD pipeline

---

## 📊 Test Coverage Needed

Authentication:

- ✅ Email/password signup
- ✅ Duplicate email validation
- ✅ Form validation
- ✅ Login/logout
- ✅ Password visibility toggle

Tree Management:

- ✅ View tree
- ✅ Add child/parent/sibling
- ✅ Edit member
- ✅ Delete member
- ✅ Search members

---

## 🐛 Known Issues

1. **Flutter CanvasKit Rendering**
   - Root cause of test failures
   - Not a bug - architectural choice
   - Requires different testing approach

2. **Hash-Based Routing**
   - URLs use `#/login` not `/login`
   - Tests updated to use hash routing
   - Working correctly ✅

3. **Auth Redirect Logic**
   - Temporarily disabled for testing
   - Needs re-enabling after test solution chosen

---

## 📚 Resources

- **Playwright**: https://playwright.dev
- **Flutter Integration Testing**: https://docs.flutter.dev/testing/integration-tests
- **Flutter Web Rendering**: https://docs.flutter.dev/platform-integration/web/renderers
- **Widget Testing**: https://docs.flutter.dev/testing/overview#widget-tests

---

## ✅ Summary

| Component           | Status     | Notes                                     |
| ------------------- | ---------- | ----------------------------------------- |
| Backend             | ✅ Running | Port 3000                                 |
| Frontend            | ✅ Running | Port 5500                                 |
| Auth System         | ✅ Working | Email/password                            |
| Router              | ✅ Updated | Hash routing                              |
| Playwright Tests    | ❌ Blocked | CanvasKit issue                           |
| **Recommended Fix** | 📝 Pending | Choose integration tests or HTML renderer |

---

**Application is fully functional and ready for manual testing.**  
**Automated E2E testing requires architecture decision.**
