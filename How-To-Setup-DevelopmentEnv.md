# MyFamilyTree — Development Environment Setup

> This guide walks you through setting up the project locally from scratch.

---

## Prerequisites

Make sure the following are installed on your machine before proceeding:

| Tool | Minimum Version | Install Link |
|------|----------------|--------------|
| **Node.js** | v18+ (LTS recommended) | https://nodejs.org/ |
| **npm** | v9+ (ships with Node.js) | — || **Flutter** | v3.24+ | https://flutter.dev/docs/get-started/install |
| **Dart** | v3.5+ (ships with Flutter) | — || **Git** | Any recent version | https://git-scm.com/ |
| **Supabase CLI** (optional) | v1.100+ | https://supabase.com/docs/guides/cli |
| **VS Code** (recommended) | Latest | https://code.visualstudio.com/ |

### Verify installations

```bash
node --version    # Should print v18.x or higher
npm --version     # Should print 9.x or higher
flutter --version # Should print Flutter 3.24.x or higher
dart --version    # Should print Dart 3.5.x or higher
git --version
```

---

## 1. Install Flutter & Dart

### Windows

1. **Download Flutter SDK:**
   - Go to https://docs.flutter.dev/get-started/install/windows
   - Download the Flutter SDK zip file
   - Extract to a permanent location (e.g., `C:\flutter`)
   - **Do NOT** extract to `Program Files` or any directory requiring elevated privileges

2. **Add Flutter to PATH:**
   ```powershell
   # Open PowerShell as Administrator
   $env:Path += ";C:\flutter\bin"
   # Make it permanent:
   [System.Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
   ```

   Or manually:
   - Search for "Environment Variables" in Windows
   - Edit System PATH variable
   - Add `C:\flutter\bin`

3. **Install Visual Studio with C++ tools:**
   - Download Visual Studio 2022 (Community Edition is free)
   - During installation, select "Desktop development with C++"
   - This is required for building Windows apps

4. **Run Flutter Doctor:**
   ```bash
   flutter doctor
   ```
   This checks for missing dependencies and shows what to fix.

5. **Accept Android Licenses (if building for Android):**
   ```bash
   flutter doctor --android-licenses
   ```

### macOS

1. **Install Flutter using Homebrew:**
   ```bash
   brew install --cask flutter
   ```

   Or manually:
   ```bash
   cd ~/development
   unzip ~/Downloads/flutter_macos_<version>.zip
   export PATH="$PATH:`pwd`/flutter/bin"
   ```

2. **Install Xcode (for iOS development):**
   - Install from Mac App Store
   - Run: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
   - Accept license: `sudo xcodebuild -license`

3. **Install CocoaPods:**
   ```bash
   sudo gem install cocoapods
   ```

4. **Run Flutter Doctor:**
   ```bash
   flutter doctor
   ```

### Linux (Ubuntu/Debian)

1. **Download and extract Flutter:**
   ```bash
   cd ~/development
   wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_<version>.tar.xz
   tar xf flutter_linux_<version>.tar.xz
   export PATH="$PATH:`pwd`/flutter/bin"
   ```

2. **Add to PATH permanently:**
   ```bash
   echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bashrc
   source ~/.bashrc
   ```

3. **Install dependencies:**
   ```bash
   sudo apt-get update
   sudo apt-get install curl git unzip xz-utils zip libglu1-mesa
   ```

4. **Run Flutter Doctor:**
   ```bash
   flutter doctor
   ```

### Verify Flutter Installation

```bash
flutter --version
flutter doctor -v
```

**Expected output:**
```
Flutter 3.24.x • channel stable • https://github.com/flutter/flutter.git
Framework • revision xxxxx
Engine • revision xxxxx
Tools • Dart 3.5.x • DevTools 2.x.x
```

---

## 2. Clone the Repository

```bash
git clone <repository-url>
cd FamilyTree
```

---

## 3. Install Backend Dependencies

```bash
cd backend
npm install
```

This installs all required packages defined in `package.json`, including:

| Package | Purpose |
|---------|---------|
| `express` | HTTP server framework |
| `@supabase/supabase-js` | Supabase client SDK (database, auth) |
| `cors` | Cross-origin resource sharing |
| `helmet` | Security headers |
| `express-rate-limit` | API rate limiting |
| `dotenv` | Environment variable loading |
| `zod` | Request validation / schema parsing |
| `typescript` | TypeScript compiler |
| `tsx` | TypeScript execution with hot-reload for dev |

---

## 4. Configure Backend Environment Variables

Create a `.env` file in the `backend/` directory:

```bash
cp .env.example .env   # If .env.example exists, otherwise create manually
```

Add the following variables to `backend/.env`:

```env
# Supabase
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_ANON_KEY=<your-supabase-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<your-supabase-service-role-key>

# Server
PORT=3000
NODE_ENV=development

# App URLs
APP_URL=http://localhost:8080
INVITE_BASE_URL=http://localhost:8080/invite
```

### Where to find Supabase keys

1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Select your project (or create a new one)
3. Navigate to **Settings → API**
4. Copy the **Project URL**, **anon public** key, and **service_role secret** key

> ⚠️ **Never commit `.env` to version control.** Make sure `.gitignore` includes `.env`.

---

## 5. Set Up Supabase Database

### Option A: Using Supabase Dashboard (Web UI)

1. Go to your Supabase project → **SQL Editor**
2. Run each migration file in order from the `supabase/migrations/` folder:
   - `001_create_persons.sql`
   - `002_create_relationships.sql`
   - `003_create_merge_requests.sql`
   - `004_rls_policies.sql`
   - `005_create_invite_tokens.sql`
3. (Optional) Run `supabase/seed.sql` to populate sample data

### Option B: Using Supabase CLI (Local Development)

```bash
# Install the Supabase CLI if you haven't already
npm install -g supabase

# From the project root
supabase init        # Only if supabase/ config doesn't exist yet
supabase start       # Starts local Supabase (Docker required)
supabase db reset    # Applies migrations + seed data
```

> **Note**: The Supabase CLI local dev requires [Docker Desktop](https://www.docker.com/products/docker-desktop/) to be installed and running.

---

## 6. Run the Backend (Development Mode)

```bash
cd backend
npm run dev
```

This starts the server using `tsx watch` with hot-reload. The API will be available at:

```
http://localhost:3000
```

### Verify the server is running

```bash
curl http://localhost:3000/api/health
# Expected: {"status":"ok","timestamp":"..."}
```

---

## 7. Install Flutter App Dependencies

```bash
cd app
flutter pub get
```

This downloads all Flutter packages specified in `pubspec.yaml`, including:

| Package | Purpose |
|---------|---------||
| `supabase_flutter` | Supabase client for Flutter |
| `google_sign_in` | Google OAuth authentication |
| `go_router` | Declarative routing |
| `flutter_riverpod` | State management |
| `http` | HTTP client for API calls |
| `flutter_dotenv` | Environment variable loading |
| `cached_network_image` | Image caching |
| `share_plus` | Native share functionality |
| `url_launcher` | Open URLs in browser |

---

## 8. Configure Flutter App Environment Variables

Create a `.env` file in the `app/` directory:

```bash
cd app
cp .env.example .env
```

Edit `app/.env`:

```env
# Supabase
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_ANON_KEY=<your-supabase-anon-key>

# Backend API
API_BASE_URL=http://localhost:3000/api
```

**Important notes:**
- Use `http://10.0.2.2:3000/api` on **Android emulator** (not `localhost`)
- Use `http://<your-local-ip>:3000/api` on **physical devices** (e.g., `http://192.168.1.100:3000/api`)
- Use `http://localhost:3000/api` on **web** and **iOS simulator**

---

## 9. Run the Flutter App

### Web (Chrome)

```bash
cd app
flutter run -d chrome
```

### Android Emulator

1. **Start an emulator:**
   ```bash
   flutter emulators --launch <emulator_id>
   ```
   Or open Android Studio → AVD Manager → Start emulator

2. **Run the app:**
   ```bash
   cd app
   flutter run
   ```

### iOS Simulator (macOS only)

1. **Start simulator:**
   ```bash
   open -a Simulator
   ```

2. **Run the app:**
   ```bash
   cd app
   flutter run -d iphone
   ```

### Physical Device

**Android:**
1. Enable Developer Options on your phone
2. Enable USB Debugging
3. Connect via USB
4. Run: `flutter run`

**iOS:**
1. Connect iPhone via USB
2. Trust the computer on your device
3. Open Xcode and configure signing
4. Run: `flutter run`

---

## 10. Build Flutter App for Production

### Web
```bash
cd app
flutter build web --release
# Output: build/web/
```

### Android APK
```bash
cd app
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Play Store)
```bash
cd app
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (macOS only)
```bash
cd app
flutter build ios --release
# Then open ios/Runner.xcworkspace in Xcode and archive
```

---

## 11. Backend Build for Production

```bash
cd backend
npm run build    # Compiles TypeScript → dist/
npm start        # Runs compiled JS from dist/
```

---

## 12. Available npm Scripts

Run these from the `backend/` directory:

| Script | Command | Description |
|--------|---------|-------------|
| `npm run dev` | `tsx watch src/index.ts` | Start dev server with hot-reload |
| `npm run build` | `tsc` | Compile TypeScript to JavaScript |
| `npm start` | `node dist/index.js` | Run the compiled production build |
| `npm run lint` | `eslint src/` | Lint the source code |
| `npm test` | `jest` | Run tests |

---

## 13. API Endpoints

Once the server is running, the following route groups are available:

| Route | Description |
|-------|-------------|
| `GET /api/health` | Health check |
| `/api/persons` | CRUD operations for family members |
| `/api/relationships` | Manage family relationships |
| `/api/tree` | Family tree traversal / graph queries |
| `/api/search` | Search within N-circle network |
| `/api/merge` | Tree merge requests |
| `/api/invite` | Invitation token management |

---

## 14. Project Structure

```
FamilyTree/
├── backend/
│   ├── package.json
│   ├── tsconfig.json
│   └── src/
│       ├── index.ts              # Express app entry point
│       ├── config/
│       │   ├── env.ts            # Environment variable definitions
│       │   └── supabase.ts       # Supabase client setup
│       ├── middleware/
│       │   ├── auth.ts           # Authentication middleware
│       │   └── errorHandler.ts   # Global error handler
│       ├── models/
│       │   └── types.ts          # TypeScript type definitions
│       ├── routes/
│       │   ├── persons.ts        # Person CRUD routes
│       │   ├── relationships.ts  # Relationship routes
│       │   ├── tree.ts           # Tree traversal routes
│       │   ├── search.ts         # Network search routes
│       │   ├── merge.ts          # Merge request routes
│       │   └── invite.ts         # Invite token routes
│       ├── services/
│       │   ├── graphService.ts   # Graph traversal logic
│       │   └── mergeService.ts   # Tree merge logic
│       └── utils/
│           └── phone.ts          # Phone number utilities
├── app/                          # Flutter mobile/web app
│   ├── pubspec.yaml
│   ├── analysis_options.yaml
│   ├── .env                      # Environment variables
│   ├── assets/                   # Images, fonts
│   └── lib/
│       ├── main.dart             # App entry point
│       ├── app.dart              # Root widget
│       ├── config/
│       │   ├── theme.dart        # Material 3 theme
│       │   └── constants.dart    # App constants
│       ├── models/
│       │   └── models.dart       # Data models (Person, Relationship, etc.)
│       ├── services/
│       │   ├── auth_service.dart # Supabase authentication
│       │   └── api_service.dart  # HTTP API client
│       ├── providers/
│       │   └── providers.dart    # Riverpod state providers
│       ├── router/
│       │   └── app_router.dart   # GoRouter navigation config
│       └── features/
│           ├── auth/
│           │   └── screens/
│           │       ├── login_screen.dart
│           │       └── profile_setup_screen.dart
│           ├── tree/
│           │   ├── screens/
│           │   │   ├── tree_view_screen.dart      # Main canvas
│           │   │   └── add_member_screen.dart
│           │   └── widgets/
│           │       ├── person_card.dart           # Geni-style card
│           │       └── tree_painter.dart          # Connection lines
│           ├── profile/
│           │   └── screens/
│           │       ├── person_detail_screen.dart
│           │       └── edit_profile_screen.dart
│           ├── search/
│           │   └── screens/
│           │       └── search_screen.dart         # N-circle search
│           ├── invite/
│           │   └── screens/
│           │       └── invite_screen.dart
│           └── merge/
│               └── screens/
│                   └── merge_review_screen.dart
├── supabase/
│   ├── seed.sql                  # Sample seed data
│   └── migrations/               # Database migration scripts
├── IDEA.md                       # Product concept & architecture
└── README.md
```

---

## 15. Recommended VS Code Extensions

| Extension | ID | Purpose |
|-----------|----|---------|
| **Flutter** | `Dart-Code.flutter` | Flutter framework support |
| **Dart** | `Dart-Code.dart-code` | Dart language support |
| ESLint | `dbaeumer.vscode-eslint` | JavaScript/TypeScript linting |
| Prettier | `esbenp.prettier-vscode` | Code formatting |
| Thunder Client | `rangav.vscode-thunder-client` | API testing (Postman alternative) |
| DotENV | `mikestead.dotenv` | `.env` file syntax highlighting |

---

## Troubleshooting

### Backend Issues

| Problem | Solution |
|---------|----------|
| `npm install` fails | Make sure you're using Node.js v18+. Run `node --version` to check. |
| Server won't start | Ensure `.env` file exists in `backend/` with all required variables. |
| Supabase connection errors | Verify `SUPABASE_URL` and keys in `.env`. Check the Supabase dashboard to confirm the project is active. |
| Port 3000 already in use | Change `PORT` in `.env` or stop the process using port 3000: `npx kill-port 3000` |
| TypeScript compilation errors | Run `npm install` again to ensure all `@types/*` packages are installed. |

### Flutter Issues

| Problem | Solution |
|---------|----------|
| `flutter pub get` fails | Run `flutter doctor` to check for issues. Try `flutter clean` then `flutter pub get` again. |
| App can't connect to API | **Android emulator:** Use `http://10.0.2.2:3000/api` instead of `localhost`<br>**Physical device:** Use your computer's local IP (e.g., `http://192.168.1.100:3000/api`) |
| Google Sign-In not working | Ensure you've configured OAuth credentials in Google Cloud Console and added them to Supabase. |
| Build errors on Android | Run `flutter clean` then `flutter build apk --release` again. Check that Android SDK is properly installed via `flutter doctor`. |
| iOS build fails | Open `ios/Runner.xcworkspace` in Xcode and fix signing issues. Make sure CocoaPods is installed: `sudo gem install cocoapods` |
| Hot reload not working | Press `r` in terminal to manually reload, or `R` for hot restart. |
| `.env` variables not loading | Make sure `.env` file is in the `app/` directory (not `app/lib/`). Restart the app completely. |

---

## Questions?

Reach out to the project maintainer or check [IDEA.md](IDEA.md) for the full product concept and technical architecture.
