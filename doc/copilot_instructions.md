# GitHub Copilot Instructions - MyFamilyTree

## Project Overview

MyFamilyTree is a family tree management application with Google authentication, profile management, tree visualization, and merge capabilities for connecting separate family trees.

## Tech Stack

- **Frontend**: Flutter 3.27.3 (web/mobile/desktop)
- **Backend**: Node.js + Express + TypeScript
- **Database**: Supabase (PostgreSQL)
- **Auth**: Supabase Auth (Email/Password)
- **State Management**: Riverpod
- **Routing**: GoRouter
- **E2E Testing**: Playwright

## Project Structure

```
FamilyTree/
├── app/                    # Flutter application
│   ├── lib/
│   │   ├── features/      # Feature modules (auth, tree, profile, etc.)
│   │   ├── router/        # GoRouter navigation
│   │   ├── services/      # API and auth services
│   │   └── providers/     # Riverpod state providers
│   └── .env              # Frontend env (SUPABASE_URL, API_BASE_URL)
├── backend/               # Node.js API server
│   ├── src/
│   │   ├── routes/       # API endpoints
│   │   ├── middleware/   # Auth middleware
│   │   ├── services/     # Business logic
│   │   └── config/       # Supabase config
│   └── .env              # Backend env (SUPABASE credentials, PORT)
├── e2e-tests/             # Playwright end-to-end tests
│   ├── tests/            # Test specifications
│   └── playwright.config.ts
└── supabase/
    └── migrations/        # Database schema
```

## Key Database Tables

- `persons` - Person records with phone, DOB, gender, etc.
- `relationships` - Connections between persons (bidirectional)
- `merge_requests` - Requests to merge separate family trees
- `invite_tokens` - Invitation tokens for adding family members
- `user_metadata` - User roles (user/admin/super_admin) and preferences
- `error_logs` - Application error tracking with severity levels
- `audit_logs` - Administrative action history for accountability
- `analytics` views - User growth, tree distribution, and activity metrics

## Important Context

### 🚧 TEMPORARY AUTH BYPASS (FOR TESTING)

Authentication is currently bypassed to enable testing without login:

**Frontend** (`app/lib/router/app_router.dart`):

- Line 18-38: Redirect logic commented out, returns `null`
- Profile setup redirect disabled (`/profile-setup` → `/`)

**Frontend** (`app/lib/features/tree/screens/tree_view_screen.dart`):

- Line 25: `_checkProfileSetup()` call commented out

**Backend** (`backend/src/middleware/auth.ts`):

- Auth check bypassed with mock user: `req.userId = 'mock-user-123'`

**Backend** (`backend/src/routes/tree.ts`):

- Returns empty tree instead of 404 when no profile found

⚠️ **TODO**: Re-enable authentication by uncommenting marked sections before production

### Development Scripts

- `start-backend.ps1` - Start Node.js API (auto-kills existing instances)
- `start-frontend-fast.ps1` - Start Flutter in profile mode (30-60s load, recommended)
- `start-frontend.ps1` - Start Flutter in debug mode on Chrome port 5500
- `stop-all.ps1` - Kill all Node/Flutter processes
- `run-tests.ps1` - Run Playwright E2E tests (checks backend/frontend status first)

**Instance Management:**

- Both `start-backend.ps1` and `start-frontend.ps1` automatically kill old processes before starting
- Backend script kills all Node.js processes
- Frontend script kills all Flutter/Dart processes
- Ensures no port conflicts or multiple instances running

### Admin Panel Features (Feb 2026)

A comprehensive admin panel with analytics, error tracking, and user management:

**Backend Components**:

- `backend/src/middleware/adminAuth.ts` - Admin role verification (adminMiddleware, superAdminMiddleware)
- `backend/src/services/errorLogger.ts` - Centralized error logging with sanitization
- `backend/src/services/adminService.ts` - Business logic for analytics and user management
- `backend/src/routes/admin.ts` - 11 protected admin endpoints

**Frontend Components**:

- `app/lib/services/admin_service.dart` - HTTP client with 10 model classes
- `app/lib/providers/admin_providers.dart` - 8 Riverpod providers for state management
- `app/lib/features/admin/screens/admin_dashboard_screen.dart` - Overview dashboard
- `app/lib/features/admin/screens/user_management_screen.dart` - Role & status management
- `app/lib/features/admin/screens/error_logs_screen.dart` - Error viewing & resolution
- `app/lib/features/admin/screens/admin_analytics_screen.dart` - Charts with fl_chart

**Admin User UUID**: `00000000-0000-0000-0000-000000000001` (seeded as super_admin)

**Access**: Navigate to tree view → Click admin panel icon in AppBar → Routes to `/admin`

### Environment Variables

**Required in `backend/.env`**:

- SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY, PORT=3000

**Required in `app/.env`**:

- SUPABASE_URL, SUPABASE_ANON_KEY, API_BASE_URL=http://localhost:3000/api

### Code Style Guidelines

- **TypeScript**: Strict mode, explicit types, async/await preferred
- **Flutter**: Material Design 3, feature-based folder structure
- **Naming**: camelCase (TS), snake_case (DB), PascalCase (Flutter classes)
- **Comments**: Mark temporary code with 🚧 TEMPORARY and explain restoration steps

### Common Patterns

- All backend routes use `authMiddleware` (currently bypassed)
- Phone numbers normalized before storage (`normalizePhone` utility)
- Riverpod providers for state management (familyTreeProvider, authServiceProvider)
- GoRouter for navigation with deep linking support

### Known Issues

- Google OAuth not configured (deferred per user request)
- Flutter debug mode takes 3-4 min to load (use profile mode instead)
- SharePlus API uses `Share.share()` not `SharePlus.instance.share()`
- Admin panel requires `fl_chart: ^0.69.0` dependency for analytics charts
- Theme constants must be imported from `config/theme.dart` (use `AppSpacing`, `AppSizing`, not `AppBorderRadius`)

### Development Notes

- User is beginner to Flutter/web/mobile development - provide explanatory comments
- Corporate network requires `npm config set strict-ssl false`
- Flutter not in PATH - use full path: `C:\src\flutter\bin\flutter.bat`
- Hot reload: Press 'r' in Flutter terminal (2-5 sec updates)

## Recent Work Completed (Feb 15, 2026)

### Admin Panel Implementation

**Database Migrations (Supabase):**

1. **006_create_user_metadata.sql** - User roles table with RLS policies
   - Schema: user_id, role (user/admin/super_admin), is_active, last_login_at, preferences
   - Seeded admin user: `00000000-0000-0000-0000-000000000001` with super_admin role

2. **007_create_error_logs.sql** - Centralized error tracking
   - Schema: error_type, severity, status_code, message, stack_trace, request details, user_id
   - Functions: cleanup_old_error_logs(), get_error_statistics(), get_error_rate_by_hour()
   - 90-day retention policy with automatic cleanup

3. **008_create_audit_logs.sql** - Admin action history
   - Schema: admin_user_id, action_type, resource_type, resource_id, old_value, new_value
   - Automatic change tracking with JSON diff calculation
   - Immutable logs (no updates/deletes allowed)

4. **009_create_analytics_functions.sql** - Analytics helper functions
   - get_user_growth_by_day(days_back) - Daily new user counts
   - get_tree_size_distribution() - Tree size histogram (1, 2-5, 6-10, 11-20, 21-50, 51-100, 100+)
   - get_admin_activity_summary(days_back) - Admin action counts by type
   - get_recent_errors(page_size, page_number, filter_type, filter_severity) - Paginated errors

**Backend Services:**

- **adminAuth.ts** - Role-based middleware (adminMiddleware, superAdminMiddleware)
- **errorLogger.ts** - Error logging service with auto-detection, sanitization, severity classification
- **adminService.ts** - Business logic: getDashboardStats(), getUserGrowthData(), getErrorStats(), updateUserRole(), etc.
- **admin.ts routes** - 11 protected endpoints for dashboard, analytics, error logs, user management, audit logs

**Frontend UI:**

- **admin_service.dart** - HTTP client with 10 model classes (DashboardStats, ErrorLog, UserMetadata, etc.)
- **admin_providers.dart** - 8 Riverpod providers (dashboardStatsProvider, errorLogsProvider, usersProvider, etc.)
- **admin_dashboard_screen.dart** - 7 stat cards, quick action buttons for navigation
- **user_management_screen.dart** - Role changes, enable/disable accounts, filtering by role
- **error_logs_screen.dart** - Filter by type/severity, mark errors resolved, expandable cards
- **admin_analytics_screen.dart** - User growth line chart, tree distribution bar chart (fl_chart)
- **Router updates** - 4 admin routes (/admin, /admin/users, /admin/errors, /admin/analytics)
- **TreeViewScreen** - Added admin panel icon in AppBar for navigation

**Bug Fixes:**

- **person_detail_screen.dart** - Removed orphaned widget code causing duplicate class declarations
- **landing_screen.dart** - Fixed import paths (../config/ → ../../../config/), replaced invalid AppSpacing.xxxl with AppSpacing.xxl
- **common_widgets.dart** - Fixed nullable String parameter (action → action!)
- **app_layout.dart** - Fixed undefined AppSpacing.xxs → AppSpacing.xs

**Dependencies Added:**

- `fl_chart: ^0.69.0` - Charts for analytics visualization

### Authentication System Update (Feb 16, 2026)

**Removed Google OAuth and Email Magic Links:**

- Simplified authentication to email/password only
- Removed Google Sign-In dependency usage
- Removed magic link email OTP flow

**New Authentication Flow:**

- **Signup**: Email + Password + Name (username/password based)
  - New screen: `signup_screen.dart` with form validation
  - Password confirmation field
  - Minimum 6 character password requirement
  - Auto-redirect to login after successful signup

- **Login**: Email + Password
  - Updated `login_screen.dart` with simple email/password form
  - Password visibility toggle
  - Form validation with error messages
  - "Sign Up" link for new users

**Updated Files:**

- `auth_service.dart` - Added `signUpWithPassword()` and `signInWithPassword()` methods
- `login_screen.dart` - Replaced OAuth/magic link UI with email/password form
- `signup_screen.dart` - New registration screen with validation
- `app_router.dart` - Added `/signup` route

**Routes:**

- `/login` - Email/password sign in
- `/signup` - New user registration
- Navigation between login and signup screens

### End-to-End Testing with Playwright (Feb 16, 2026)

**Setup:**

- Created `e2e-tests/` directory with Playwright framework
- Installed Playwright with Chromium, Firefox, and WebKit browsers
- TypeScript configuration for test files

**Test Suites:**

1. **Authentication Tests** (`tests/auth.spec.ts`):
   - Sign up with valid email/password
   - Sign up validation errors (missing fields, password mismatch)
   - Duplicate email error handling
   - Login with valid credentials
   - Login with invalid credentials
   - Login validation errors
   - Password visibility toggle
   - Navigation between login/signup screens

2. **Tree View Tests** (`tests/tree.spec.ts`):
   - Display family tree
   - Add child to tree
   - Add parent relationship
   - Add sibling relationship
   - View person details
   - Edit family member
   - Delete family member
   - Search for members
   - Validation for required fields
   - Empty tree state handling
   - Zoom controls
   - View switching

**Test Infrastructure:**

- `playwright.config.ts` - Configuration for test execution
- `package.json` - Test scripts (test, test:headed, test:ui, test:debug)
- `run-tests.ps1` - PowerShell script to run tests with service checks
- `README.md` - Complete testing documentation

**Running Tests:**

```powershell
# From root directory
.\run-tests.ps1              # Automated test runner with service checks

# From e2e-tests directory
npm test                     # Run all tests headless
npm run test:headed          # Run with visible browser
npm run test:ui              # Interactive UI mode
npm run test:auth            # Run only auth tests
npm run test:tree            # Run only tree tests
npm run test:debug           # Debug mode
npm run report               # View HTML report
```

**Dependencies Added:**

- `fl_chart: ^0.69.0` - Charts for analytics visualization

### Git Configuration

- Personal GitHub account configured: ManiKumar007 <manich623@gmail.com>
- SSH key authentication: id_ed25519_personal
- Repository: https://github.com/ManiKumar007/FamilyTree
- GPG signing disabled locally to avoid work/personal key conflicts

### Application Launch & Authentication Fix (Feb 16, 2026 - Session 2)

**Issues Discovered:**

1. **Frontend Compilation Failure**
   - `auth_service.dart` had malformed code from previous cleanup session
   - Missing `signOut()` method causing compilation error
   - Missing `accessToken` getter causing compilation error
   - Broken code fragments from incomplete OTP/magic link removal

2. **Invalid Supabase Authentication Key**
   - `.env` files were using placeholder publishable key format: `sb_publishable_7gumsvulTmP1yCPumQLUYQ_PVVGyHqZ`
   - Supabase Flutter SDK requires legacy JWT format anon key
   - Root cause of all authentication failures

**Fixes Applied:**

1. **Auth Service Code Repair** (`app/lib/services/auth_service.dart`)
   - Removed malformed code fragments (broken `signInWithEmail`, `verifyOtp` methods)
   - Restored clean `signOut()` method with logging
   - Restored `accessToken` getter for API authentication
   - File now contains only: `signUpWithPassword()`, `signInWithPassword()`, `signOut()`, and `accessToken`

2. **Supabase Key Fix**
   - Retrieved correct legacy anon key from Supabase using MCP client
   - Updated `backend/.env` with correct JWT anon key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - Updated `app/.env` with correct JWT anon key
   - Key difference: Legacy JWT format vs new publishable key format

**Documentation Created:**

1. **AUTH_FIX_GUIDE.md** (167 lines)
   - Problem identification and explanation
   - Step-by-step fix instructions
   - How to retrieve correct anon key from Supabase Dashboard
   - Verification steps and troubleshooting guide
   - Admin account creation process reference

2. **TESTING_GUIDE.md** (430 lines)
   - Comprehensive feature testing checklist (15+ features)
   - Authentication testing (signup, login, validation)
   - Family tree testing (view, add, edit, search)
   - Admin panel testing (dashboard, users, logs, analytics)
   - **Admin Account Setup Process** (4 steps):
     1. Create user via signup UI
     2. Get user_id from browser console logs
     3. Run SQL to promote to super_admin role
     4. Log out/in and access /admin route
   - API testing examples (PowerShell and curl)
   - Troubleshooting guide

**Key Findings:**

- **NO Default Admin Credentials** by design
  - Application uses Supabase Auth (no pre-seeded users)
  - `user_metadata` table has row for `mock-user-123` with super_admin role
  - BUT `mock-user-123` is not a real Supabase Auth user (cannot login)
  - Admin users must be created manually via signup then promoted via SQL

**Services Status:**

- Backend running on port 3000 (verified with health check)
- Frontend running on port 5500 (verified with HTTP 200)
- Both services restarted with correct Supabase credentials
- Authentication now functional with proper JWT anon key

**Authentication Now Working:**

- Signup flow functional with email/password
- Login flow functional with proper session management
- Browser console shows detailed auth logs (15+ log points)
- Access tokens properly generated for API calls

## Quick Commands

```powershell
# Start development
.\start-backend.ps1           # Backend on :3000
.\start-frontend-fast.ps1     # Flutter in 30-60s (profile mode)
.\start-frontend.ps1          # Flutter on :5500 (debug mode)

# Stop all
.\stop-all.ps1

# Database migrations (via Supabase MCP)
# Applied migrations: 001-009
# Latest: 006 (user_metadata), 007 (error_logs), 008 (audit_logs), 009 (analytics_functions)
```

## API Endpoints

### Public/User Endpoints

- `GET /api/health` - Health check
- `GET /api/tree` - Get user's family tree
- `POST /api/persons` - Create person
- `POST /api/relationships` - Create relationship
- `GET /api/search/:query` - Search within network
- `GET /api/merge/pending` - Get pending merge requests

### Admin Endpoints (Protected)

All admin routes require `authMiddleware + adminMiddleware`:

- `GET /api/admin/stats` - Dashboard statistics (users, people, errors)
- `GET /api/admin/analytics/growth?days={n}` - User growth chart data
- `GET /api/admin/analytics/tree-distribution` - Tree size distribution
- `GET /api/admin/analytics/active-users?limit={n}` - Top contributors
- `GET /api/admin/errors?page&pageSize&type&severity` - Paginated error logs
- `GET /api/admin/errors/stats?days={n}` - Error summary by type
- `PUT /api/admin/errors/:id/resolve` - Mark error resolved
- `GET /api/admin/users?page&pageSize&role` - User list with filtering
- `PUT /api/admin/users/:id/role` - Change user role (super admin only)
- `PUT /api/admin/users/:id/status` - Enable/disable user account
- `GET /api/admin/audit-logs?page&pageSize` - Administrative action history
- `GET /api/admin/health` - System health check with database latency

## When Suggesting Code

1. Check if authentication bypass is still active (look for 🚧 TEMPORARY markers)
2. Use TypeScript for backend, Dart for frontend
3. Follow existing patterns in similar files
4. Add comments for complex logic
5. Consider user is learning - explain non-obvious code
