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
- `stop-all.ps1` - Kill all Node/Flutter processes

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

### Development Notes
- User is beginner to Flutter/web/mobile development - provide explanatory comments
- Corporate network requires `npm config set strict-ssl false`
- Flutter not in PATH - use full path: `C:\src\flutter\bin\flutter.bat`
- Hot reload: Press 'r' in Flutter terminal (2-5 sec updates)

## Quick Commands
```powershell
# Start development
.\start-backend.ps1           # Backend on :3000
.\start-frontend-fast.ps1     # Flutter in 30-60s

# Stop all
.\stop-all.ps1

# Database migrations (via Supabase MCP)
# Already applied: 001-005 migrations
```

## API Endpoints
- `GET /api/health` - Health check
- `GET /api/tree` - Get user's family tree
- `POST /api/persons` - Create person
- `POST /api/relationships` - Create relationship
- `GET /api/search/:query` - Search within network
- `GET /api/merge/pending` - Get pending merge requests

## When Suggesting Code
1. Check if authentication bypass is still active (look for 🚧 TEMPORARY markers)
2. Use TypeScript for backend, Dart for frontend
3. Follow existing patterns in similar files
4. Add comments for complex logic
5. Consider user is learning - explain non-obvious code
