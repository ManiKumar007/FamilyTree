# Testing & Maintenance Best Practices

## 🎯 Overview

This document outlines best practices for maintaining and testing the MyFamilyTree application, covering both backend (Node.js/Express) and frontend (Flutter) development.

---

## 📋 Table of Contents

1. [Backend Testing Strategy](#backend-testing-strategy)
2. [Frontend Testing Strategy](#frontend-testing-strategy)
3. [Code Quality & Maintenance](#code-quality--maintenance)
4. [CI/CD Best Practices](#cicd-best-practices)
5. [Database Management](#database-management)
6. [Security Best Practices](#security-best-practices)
7. [Performance Optimization](#performance-optimization)
8. [Debugging Common Issues](#debugging-common-issues)

---

## 🧪 Backend Testing Strategy

### Unit Tests

**Location:** `backend/src/__tests__/`

**Run Tests:**

```bash
cd backend
npm test                    # Run all tests
npm test -- --coverage      # Run with coverage report
npm test -- --watch         # Watch mode for development
```

**Test Structure:**

- **API Tests:** `__tests__/api/*.test.ts` - Test all endpoints
- **Utility Tests:** `__tests__/utils/*.test.ts` - Test helper functions
- **Service Tests:** Test business logic in isolation

**Example Test Pattern:**

```typescript
describe("API Endpoint", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("should handle success case", async () => {
    // Arrange: Setup mocks and data
    const mockData = { id: "123", name: "Test" };

    // Act: Make API call
    const response = await request(app).get("/api/endpoint").expect(200);

    // Assert: Verify results
    expect(response.body).toMatchObject(mockData);
  });

  it("should handle error case", async () => {
    // Test error scenarios
  });
});
```

### Integration Tests

**Purpose:** Test full workflows including database operations

**Best Practices:**

- Use a separate test database or Supabase project
- Clean up test data after each test
- Test authentication flows end-to-end
- Mock external services (email, SMS, etc.)

### API Testing Checklist

For each API endpoint, test:

- ✅ Success cases with valid data
- ✅ Validation errors (400)
- ✅ Authentication failures (401)
- ✅ Authorization failures (403)
- ✅ Not found errors (404)
- ✅ Conflict errors (409)
- ✅ Server errors (500)
- ✅ Edge cases (empty data, special characters, etc.)
- ✅ Rate limiting
- ✅ CORS headers

---

## 📱 Frontend Testing Strategy

### Widget Tests

**Location:** `app/test/widget_test.dart`

**Run Tests:**

```bash
cd app
flutter test                # Run all tests
flutter test --coverage     # Generate coverage
flutter test --watch        # Watch mode
```

**Test Pattern:**

```dart
testWidgets('Widget description', (WidgetTester tester) async {
  // Build widget
  await tester.pumpWidget(
    MaterialApp(home: YourWidget()),
  );

  // Find elements
  expect(find.text('Expected Text'), findsOneWidget);

  // Interact
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();

  // Assert
  expect(find.text('Result'), findsOneWidget);
});
```

### Unit Tests for Providers

```dart
test('Provider state management', () {
  final container = ProviderContainer();
  final provider = container.read(yourProvider);

  // Test provider logic
  expect(provider.state, expectedState);
});
```

### Golden Tests (Visual Regression)

```dart
testWidgets('Golden test', (tester) async {
  await tester.pumpWidget(YourWidget());
  await expectLater(
    find.byType(YourWidget),
    matchesGoldenFile('golden/your_widget.png'),
  );
});
```

---

## 🔧 Code Quality & Maintenance

### Backend Standards

**Linting:**

```bash
cd backend
npm run lint              # Check for issues
npm run lint -- --fix     # Auto-fix issues
```

**Code Organization:**

```
backend/src/
├── routes/          # API endpoints (thin layer)
├── services/        # Business logic
├── models/          # Data models & types
├── middleware/      # Auth, error handling
├── utils/           # Helper functions
└── config/          # Configuration
```

**Best Practices:**

- Keep routes thin - delegate to services
- Use TypeScript strict mode
- Validate all inputs with Zod
- Use meaningful variable names
- Add JSDoc comments for public APIs
- Handle errors gracefully
- Log important events

### Frontend Standards

**Analysis:**

```bash
cd app
flutter analyze       # Static analysis
```

**Code Organization:**

```
app/lib/
├── features/        # Feature-based modules
│   ├── auth/
│   ├── tree/
│   └── profile/
├── models/          # Data models
├── providers/       # Riverpod providers
├── services/        # API & business logic
├── router/          # Navigation
└── config/          # Configuration
```

**Best Practices:**

- Follow feature-first architecture
- Use Riverpod for state management
- Implement proper error handling
- Use const constructors where possible
- Follow Flutter style guide
- Add documentation comments
- Handle loading states properly

---

## 🔄 CI/CD Best Practices

### Automated Testing Pipeline

**GitHub Actions Example:**

```yaml
name: Test & Deploy

on: [push, pull_request]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: "18"
      - run: cd backend && npm install
      - run: cd backend && npm test
      - run: cd backend && npm run lint

  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: cd app && flutter pub get
      - run: cd app && flutter analyze
      - run: cd app && flutter test
```

### Pre-commit Hooks

Install Husky for Git hooks:

```bash
npm install --save-dev husky
npx husky install
npx husky add .husky/pre-commit "cd backend && npm test"
```

---

## 🗄️ Database Management

### Migration Best Practices

**Location:** `supabase/migrations/`

**Creating Migrations:**

```bash
# Use sequential numbering
# Format: XXX_description.sql
supabase/migrations/
├── 001_create_persons.sql
├── 002_create_relationships.sql
└── 003_add_column.sql
```

**Migration Template:**

```sql
-- Migration: Add new column
-- Created: 2026-02-15

-- Add column
ALTER TABLE persons ADD COLUMN IF NOT EXISTS
  nickname VARCHAR(100);

-- Create index if needed
CREATE INDEX IF NOT EXISTS idx_persons_nickname
  ON persons(nickname);

-- Update RLS policies if needed
```

**Best Practices:**

- Never modify existing migrations
- Always create new migrations for changes
- Test migrations on dev environment first
- Include rollback instructions in comments
- Use transactions where appropriate
- Document breaking changes

### Seed Data

**Location:** `supabase/seed.sql`

Use for:

- Development and testing data
- Reference data (countries, etc.)
- Demo accounts

---

## 🔒 Security Best Practices

### Backend Security

1. **Environment Variables:**
   - Never commit `.env` files
   - Use strong secrets in production
   - Rotate keys regularly

2. **Authentication:**
   - Always verify JWT tokens
   - Check user permissions
   - Implement rate limiting
   - Use HTTPS in production

3. **Input Validation:**

   ```typescript
   // Always validate inputs
   const schema = z.object({
     name: z.string().min(1).max(200),
     email: z.string().email(),
   });
   const validated = schema.parse(req.body);
   ```

4. **SQL Injection Prevention:**
   - Use Supabase client (parameterized queries)
   - Never concatenate user input in queries

5. **CORS Configuration:**
   ```typescript
   app.use(
     cors({
       origin: process.env.APP_URL, // Specific origin
       credentials: true,
     }),
   );
   ```

### Frontend Security

1. **API Keys:**
   - Use anon key only (not service role key)
   - Store in `.env` files
   - Don't log sensitive data

2. **Data Validation:**
   - Validate user input
   - Sanitize display data
   - Use proper encoding

---

## ⚡ Performance Optimization

### Backend Optimization

1. **Database Queries:**
   - Use indexes on frequently queried columns
   - Limit result sets
   - Use proper joins
   - Cache expensive queries

2. **API Responses:**
   - Implement pagination
   - Use compression
   - Return only needed fields

3. **Monitoring:**
   ```typescript
   // Log slow queries
   const start = Date.now();
   const result = await query();
   const duration = Date.now() - start;
   if (duration > 1000) {
     console.warn(`Slow query: ${duration}ms`);
   }
   ```

### Frontend Optimization

1. **Widget Performance:**
   - Use const constructors
   - Implement proper keys
   - Avoid rebuilding unnecessarily
   - Use ListView.builder for long lists

2. **State Management:**
   - Keep provider scope minimal
   - Use select for specific data
   - Implement proper caching

3. **API Calls:**
   - Cache responses where appropriate
   - Implement optimistic updates
   - Use debouncing for search

---

## 🐛 Debugging Common Issues

### Issue 1: API Endpoint Not Found (404)

**Symptoms:** Frontend gets 404 when calling API

**Solutions:**

1. Verify backend is running on correct port:

   ```bash
   curl http://localhost:3000/api/health
   ```

2. Check `APP_URL` in backend `.env`:

   ```env
   APP_URL=http://localhost:8080
   ```

3. Check `API_BASE_URL` in frontend `.env`:

   ```env
   API_BASE_URL=http://localhost:3000/api
   ```

4. Verify CORS configuration in `backend/src/index.ts`

5. Check authentication middleware isn't blocking requests

### Issue 2: CORS Errors

**Symptoms:** Browser console shows CORS errors

**Solutions:**

1. Ensure backend CORS is configured:

   ```typescript
   app.use(
     cors({
       origin: "http://localhost:8080",
       credentials: true,
     }),
   );
   ```

2. Check preflight requests are handled

3. Verify origin matches exactly (including protocol and port)

### Issue 3: Authentication Failures

**Symptoms:** 401 Unauthorized errors

**Solutions:**

1. Check auth token is being sent:

   ```dart
   'Authorization': 'Bearer ${token}'
   ```

2. Verify token hasn't expired

3. Check auth middleware is properly configured

4. Ensure Supabase keys are correct

### Issue 4: Database Connection Issues

**Solutions:**

1. Verify `.env` has correct Supabase credentials
2. Check Supabase project is active
3. Test connection:
   ```typescript
   const { data, error } = await supabaseAdmin.from("persons").select("count");
   ```

### Issue 5: Build Failures

**Backend:**

```bash
# Clear and reinstall
rm -rf node_modules package-lock.json
npm install
npm run build
```

**Frontend:**

```bash
# Clear Flutter cache
flutter clean
flutter pub get
flutter run
```

---

## 🛠️ Useful Commands

### Backend

```bash
# Development
npm run dev                 # Start dev server with hot reload
npm test                    # Run tests
npm test -- --watch         # Watch mode
npm run lint                # Lint code
npm run build               # Build for production
npm start                   # Run production build

# Database
# Run migrations (via Supabase CLI)
```

### Frontend

```bash
# Development
flutter run                 # Run app
flutter run -d chrome       # Run on Chrome
flutter run -d windows      # Run on Windows
flutter test                # Run tests
flutter analyze             # Static analysis
flutter clean               # Clean build files
flutter pub get             # Install dependencies
flutter build apk           # Build Android APK
flutter build web           # Build web version
```

---

## 📊 Test Coverage Goals

### Backend

- **Overall Coverage:** 80%+ recommended
- **Critical Business Logic:** 90%+
- **API Endpoints:** 100% of routes tested
- **Utilities:** 100% coverage

### Frontend

- **Widget Tests:** Cover critical UI paths
- **State Management:** Test all providers
- **Business Logic:** Test services and utilities

---

## 📚 Additional Resources

- [Express.js Best Practices](https://expressjs.com/en/advanced/best-practice-performance.html)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [TypeScript Best Practices](https://www.typescriptlang.org/docs/)
- [Supabase Documentation](https://supabase.com/docs)
- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [Riverpod Best Practices](https://riverpod.dev/docs/concepts/reading)

---

## ✅ Testing Checklist

Before deploying to production:

- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Code reviewed
- [ ] No console errors or warnings
- [ ] Performance tested with realistic data
- [ ] Security review completed
- [ ] Environment variables configured
- [ ] Database migrations tested
- [ ] Backup strategy in place
- [ ] Monitoring configured
- [ ] Documentation updated

---

**Last Updated:** February 15, 2026
**Maintainer:** MyFamilyTree Development Team
