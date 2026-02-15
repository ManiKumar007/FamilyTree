# GitHub Copilot Instructions - MyFamilyTree

## Project Overview

MyFamilyTree is a family tree management application with Google authentication, profile management, tree visualization, and merge capabilities for connecting separate family trees.

## Tech Stack

- **Frontend**: Flutter 3.27.3 (web/mobile/desktop)
- **Backend**: Node.js + Express + TypeScript
- **Database**: Supabase (PostgreSQL)
- **Auth**: Supabase Auth (Google OAuth + Email Magic Links)
- **State Management**: Riverpod
- **Routing**: GoRouter

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

### Git Configuration
- Personal GitHub account configured: ManiKumar007 <manich623@gmail.com>
- SSH key authentication: id_ed25519_personal
- Repository: https://github.com/ManiKumar007/FamilyTree
- GPG signing disabled locally to avoid work/personal key conflicts

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
