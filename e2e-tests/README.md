# End-to-End Tests for MyFamilyTree

This directory contains Playwright end-to-end tests for the MyFamilyTree application.

## Prerequisites

1. **Backend** must be running on `http://localhost:3000`
2. **Frontend** must be running on `http://localhost:5500`
3. Node.js and npm must be installed

## Installation

```powershell
cd e2e-tests
npm install
npx playwright install
```

## Running Tests

### Run all tests

```powershell
npm test
```

### Run tests with UI

```powershell
npm run test:ui
```

### Run tests in headed mode (see browser)

```powershell
npm run test:headed
```

### Run specific test suites

```powershell
# Authentication tests (login/signup)
npm run test:auth

# Tree view tests (add members, relationships)
npm run test:tree
```

### Debug mode

```powershell
npm run test:debug
```

### View test report

```powershell
npm run report
```

## Test Structure

- `tests/auth.spec.ts` - Authentication tests
  - Sign up with email/password
  - Login with credentials
  - Validation errors
  - Password visibility toggle
  - Navigation between login/signup

- `tests/tree.spec.ts` - Family tree tests
  - View family tree
  - Add child
  - Add parent
  - Add sibling
  - Edit member
  - Delete member
  - Search members
  - View person details

## Configuration

The Playwright configuration is in `playwright.config.ts`. Key settings:

- **Base URL**: http://localhost:5500
- **Browser**: Chromium (Chrome)
- **Screenshots**: Only on failure
- **Videos**: Only on failure
- **Retries**: 2 (in CI mode)

## Test Data

Tests use dynamically generated test data:

- Email: `test{timestamp}@example.com`
- Password: `TestPassword123!`
- Names: `Test User {timestamp}`

This ensures tests don't conflict with existing data.

## Troubleshooting

### Tests fail immediately

- Ensure backend is running: `http://localhost:3000/api/health`
- Ensure frontend is running: `http://localhost:5500`
- Start them with `.\start-backend.ps1` and `.\start-frontend.ps1`

### Element not found errors

- The UI might have changed. Update selectors in test files.
- Check if auth bypass is still enabled (tests expect real auth)

### Timeout errors

- Increase timeout in `playwright.config.ts`
- Check network connectivity
- Ensure Supabase is accessible

### Email verification required

- Supabase may require email verification for new signups
- You may need to disable email verification in Supabase settings
- Or manually verify test accounts in Supabase dashboard

## CI/CD Integration

To run tests in CI:

```yaml
- name: Install dependencies
  run: |
    cd e2e-tests
    npm install
    npx playwright install --with-deps

- name: Start backend
  run: |
    cd backend
    npm install
    npm run dev &

- name: Start frontend
  run: |
    cd app
    flutter run -d web-server --web-port=5500 &

- name: Run tests
  run: |
    cd e2e-tests
    npm test
```

## Writing New Tests

1. Create a new `.spec.ts` file in `tests/` directory
2. Import Playwright test utilities:
   ```typescript
   import { test, expect } from "@playwright/test";
   ```
3. Use `test.describe()` to group related tests
4. Use `test.beforeEach()` for setup
5. Write assertions with `expect()`

Example:

```typescript
test("should do something", async ({ page }) => {
  await page.goto("/some-page");
  await expect(page.locator("text=Hello")).toBeVisible();
});
```

## Best Practices

1. **Use data-testid attributes** in components for reliable selectors
2. **Generate unique test data** to avoid conflicts
3. **Clean up after tests** - delete created test data
4. **Use page object pattern** for complex flows
5. **Keep tests independent** - don't rely on test order
6. **Add explicit waits** for async operations
7. **Use meaningful test names** that describe what's being tested

## Resources

- [Playwright Documentation](https://playwright.dev/)
- [Playwright Best Practices](https://playwright.dev/docs/best-practices)
- [Playwright Selectors](https://playwright.dev/docs/selectors)
