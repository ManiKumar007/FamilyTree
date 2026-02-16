# Deployment & Testing Guide

This guide covers deploying MyFamilyTree to production and testing the complete application.

## Table of Contents

0. [Local Development & Performance](#0-local-development--performance)
1. [Supabase Setup](#1-supabase-setup)
2. [Backend Deployment](#2-backend-deployment)
3. [Flutter App Deployment](#3-flutter-app-deployment)
4. [Testing Strategy](#4-testing-strategy)
5. [Post-Deployment Checklist](#5-post-deployment-checklist)

---

## 0. Local Development & Performance

### 0.1 Quick Start Scripts

The project includes automated PowerShell scripts for easy local development:

| Script                          | Purpose                                              | Load Time         |
| ------------------------------- | ---------------------------------------------------- | ----------------- |
| `start-all.ps1`                 | Starts both backend and frontend in separate windows | 3+ min (debug)    |
| `start-backend.ps1`             | Starts only the backend server                       | ~5 sec            |
| `start-frontend.ps1`            | Starts Flutter app in DEBUG mode (slow, hot reload)  | 3-4 min           |
| `start-frontend-fast.ps1` ⚡    | Starts Flutter app in PROFILE mode                   | **30-60 sec**     |
| `start-frontend-release.ps1` 🚀 | Starts Flutter app in RELEASE mode                   | **20-40 sec**     |
| `build-and-serve.ps1` 💎        | Builds & serves production app                       | **2-5 sec** loads |
| `stop-all.ps1`                  | Stops all running instances                          | instant           |

**Usage:** Right-click any script and select **Run with PowerShell**

All scripts automatically:

- ✅ Detect and kill existing instances before starting
- ✅ Prevent port conflicts
- ✅ Show colored status messages

### 0.2 Performance Optimization

#### Flutter Web Load Times

Flutter web has different build modes with varying performance:

| Mode              | Initial Load | Hot Reload | Debugging  | Best For                            |
| ----------------- | ------------ | ---------- | ---------- | ----------------------------------- |
| **Debug**         | 3-4 min      | ✅ Yes     | ✅ Full    | Finding bugs                        |
| **Profile**       | 30-60 sec    | ✅ Yes     | ⚠️ Limited | **Daily development (recommended)** |
| **Release**       | 20-40 sec    | ❌ No      | ❌ No      | Testing performance                 |
| **Build & Serve** | 2-5 sec      | ❌ No      | ❌ No      | Final testing                       |

**Key Points:**

- The 3-4 minute load time in debug mode is **expected behavior**
- Debug mode includes full DevTools, source maps, and hot reload infrastructure
- For daily development, use **`start-frontend-fast.ps1`** (10x faster)
- Once loaded, use **hot reload** (press 'r' in terminal) for 2-5 second updates

#### Recommended Workflow

```powershell
# 1. Start backend (one-time, ~5 seconds)
.\start-backend.ps1

# 2. Start frontend in profile mode (30-60 seconds first load)
.\start-frontend-fast.ps1

# 3. Make code changes, then press 'r' in Flutter terminal (2-5 seconds)
# No need to restart!

# 4. When done, stop everything
.\stop-all.ps1
```

#### Production Build

For testing the final optimized version:

```powershell
# Build once (~1-2 minutes)
.\build-and-serve.ps1

# Then access at http://localhost:8080
# Page loads in 2-5 seconds (like production!)
```

### 0.3 Environment Setup

Before running locally, ensure you have:

1. **Backend** (`backend/.env`):

   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
   SUPABASE_ANON_KEY=your-anon-key
   PORT=3000
   ```

2. **Frontend** (`app/.env`):

   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   API_BASE_URL=http://localhost:3000/api
   ```

3. **First Time Setup**:

   ```powershell
   # Enable PowerShell scripts
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

   # Install backend dependencies
   cd backend
   npm install

   # Install Flutter dependencies
   cd ../app
   flutter pub get
   ```

### 0.4 Troubleshooting

**Problem**: Scripts won't run

```powershell
# Solution: Enable script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Problem**: Port already in use

```powershell
# Solution: Kill all instances
.\stop-all.ps1
# Then restart
.\start-all.ps1
```

**Problem**: App takes 3+ minutes to load
**Solution**: This is normal for debug mode. Use `start-frontend-fast.ps1` for 30-60 second loads.

**Problem**: Changes not appearing
**Solution**: Press 'r' in the Flutter terminal for hot reload (2-5 seconds)

For more details, see [QUICK-START.md](QUICK-START.md)

---

## 1. Supabase Setup

### 1.1 Create Production Project

1. Go to [Supabase Dashboard](https://app.supabase.com/)
2. Click **New Project**
3. Fill in details:
   - **Name**: MyFamilyTree (or your preferred name)
   - **Database Password**: Generate a strong password and save it securely
   - **Region**: Choose closest to your target users
   - **Pricing Plan**: Free tier is fine for development, scale as needed

4. Wait for project initialization (~2 minutes)

### 1.2 Run Database Migrations

1. Install Supabase CLI:

   ```bash
   npm install -g supabase
   ```

2. Login and link your project:

   ```bash
   supabase login
   supabase link --project-ref YOUR_PROJECT_REF
   ```

3. Push migrations:
   ```bash
   cd supabase
   supabase db push
   ```

Alternatively, manually execute SQL files:

1. Go to **SQL Editor** in Supabase dashboard
2. Run each migration file in order:
   - `001_create_persons.sql`
   - `002_create_relationships.sql`
   - `003_create_merge_requests.sql`
   - `004_rls_policies.sql`
   - `005_create_invite_tokens.sql`

### 1.3 Configure Authentication

Follow [AUTH_SETUP.md](AUTH_SETUP.md) to:

- Enable Google OAuth provider
- Enable Email provider
- Configure OAuth redirect URLs
- Set up email templates

### 1.4 Get Production Credentials

1. Go to **Settings** → **API**
2. Copy:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**
   - **service_role secret key** (keep this secure!)

### 1.5 Configure Storage (Optional)

If using profile photos:

1. Go to **Storage**
2. Create a new bucket: `avatars`
3. Set bucket as **Public**
4. Add RLS policies for uploads:

   ```sql
   -- Allow authenticated users to upload
   CREATE POLICY "Users can upload own avatar"
   ON storage.objects FOR INSERT
   TO authenticated
   WITH CHECK (bucket_id = 'avatars');

   -- Allow public read
   CREATE POLICY "Public avatar read"
   ON storage.objects FOR SELECT
   TO public
   USING (bucket_id = 'avatars');
   ```

---

## 2. Backend Deployment

### Option A: Railway (Recommended)

Railway provides easy deployment with zero configuration.

#### 2.1 Prepare Repository

1. Ensure `.gitignore` excludes:

   ```
   .env
   node_modules/
   dist/
   ```

2. Add start script to `backend/package.json`:

   ```json
   {
     "scripts": {
       "start": "node dist/index.js",
       "build": "tsc",
       "dev": "tsx watch src/index.ts"
     }
   }
   ```

3. Commit and push to GitHub

#### 2.2 Deploy to Railway

1. Go to [Railway.app](https://railway.app/)
2. Click **New Project** → **Deploy from GitHub repo**
3. Select your repository
4. Railway will auto-detect Node.js
5. Configure build settings:
   - **Root Directory**: `backend`
   - **Build Command**: `npm install && npm run build`
   - **Start Command**: `npm start`

#### 2.3 Add Environment Variables

In Railway project settings, add variables:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_ANON_KEY=your-anon-key
PORT=3000
NODE_ENV=production
APP_URL=https://your-app.com
INVITE_BASE_URL=https://your-app.com/invite
```

#### 2.4 Get Deployment URL

Railway will provide a URL like: `https://your-backend.up.railway.app`

Save this URL for the Flutter app configuration.

### Option B: Render

Similar to Railway, but with some manual steps:

1. Go to [Render.com](https://render.com/)
2. **New** → **Web Service**
3. Connect GitHub repository
4. Configure:
   - **Name**: myfamilytree-backend
   - **Root Directory**: `backend`
   - **Build Command**: `npm install && npm run build`
   - **Start Command**: `npm start`
5. Add environment variables (same as above)
6. Deploy

### Option C: Heroku

1. Install Heroku CLI
2. Login: `heroku login`
3. Create app:
   ```bash
   heroku create myfamilytree-backend
   ```
4. Add buildpack:
   ```bash
   heroku buildpacks:set heroku/nodejs
   ```
5. Set environment variables:
   ```bash
   heroku config:set SUPABASE_URL=xxx
   heroku config:set SUPABASE_SERVICE_ROLE_KEY=xxx
   # ... etc
   ```
6. Deploy:
   ```bash
   git subtree push --prefix backend heroku main
   ```

### Option D: Google Cloud Run

1. Install Google Cloud SDK
2. Build container:
   ```bash
   cd backend
   gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/myfamilytree-backend
   ```
3. Deploy:
   ```bash
   gcloud run deploy myfamilytree-backend \
     --image gcr.io/YOUR_PROJECT_ID/myfamilytree-backend \
     --platform managed \
     --region us-central1 \
     --allow-unauthenticated
   ```
4. Set environment variables via Cloud Console

---

## 3. Flutter App Deployment

### 3.1 Update Production Configuration

1. Create production `.env` file:

   ```bash
   cd app
   cp .env.example .env.prod
   ```

2. Fill in production values:

   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-production-anon-key
   API_BASE_URL=https://your-backend.up.railway.app/api
   GOOGLE_WEB_CLIENT_ID=your-production-client-id.apps.googleusercontent.com
   ```

3. Update app to use production env:
   ```dart
   // In main.dart, conditionally load env
   await dotenv.load(
     fileName: kReleaseMode ? '.env.prod' : '.env',
   );
   ```

### 3.2 Android Deployment

#### Prepare for Release

1. **Create keystore**:

   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Configure signing** in `android/app/build.gradle`:

   ```gradle
   android {
       ...
       signingConfigs {
           release {
               keyAlias 'upload'
               keyPassword 'YOUR_KEY_PASSWORD'
               storeFile file('C:/path/to/upload-keystore.jks')
               storePassword 'YOUR_STORE_PASSWORD'
           }
       }
       buildTypes {
           release {
               signingConfig signingConfigs.release
               minifyEnabled true
               shrinkResources true
           }
       }
   }
   ```

3. **Better approach**: Use `key.properties`:

   Create `android/key.properties`:

   ```properties
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=C:/path/to/upload-keystore.jks
   ```

   Update `android/app/build.gradle`:

   ```gradle
   def keystoreProperties = new Properties()
   def keystorePropertiesFile = rootProject.file('key.properties')
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
   }

   android {
       ...
       signingConfigs {
           release {
               keyAlias keystoreProperties['keyAlias']
               keyPassword keystoreProperties['keyPassword']
               storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
               storePassword keystoreProperties['storePassword']
           }
       }
   }
   ```

4. **Build release APK**:

   ```bash
   flutter build apk --release
   ```

5. **Build Android App Bundle** (for Play Store):
   ```bash
   flutter build appbundle --release
   ```

#### Deploy to Google Play Store

1. Go to [Google Play Console](https://play.google.com/console/)
2. **Create app**:
   - App name: MyFamilyTree
   - Default language: English
   - App or game: App
   - Free or paid: Free
3. Complete **Store listing**:
   - Short description, full description
   - App icon (512x512 PNG)
   - Feature graphic (1024x500)
   - Screenshots (minimum 2)
4. Complete **Content rating** questionnaire
5. Select **Target audience**
6. Complete **Privacy policy** (required for apps handling user data)
7. Go to **Release** → **Production**
8. Upload your `.aab` file
9. Submit for review

**Note**: First review can take 1-7 days.

### 3.3 iOS Deployment

#### Prerequisites

- Mac with Xcode installed
- Apple Developer Program membership ($99/year)

#### Prepare for Release

1. **Open in Xcode**:

   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. **Configure in Xcode**:
   - Select **Runner** project
   - **General** tab:
     - Display Name: MyFamilyTree
     - Bundle Identifier: com.myfamilytree
     - Version: 1.0.0
     - Build: 1
   - **Signing & Capabilities**:
     - Team: Select your team
     - Automatically manage signing: ✓

3. **Update `Info.plist`** (ensure production URLs)

4. **Build archive**:

   ```bash
   flutter build ios --release
   ```

5. In Xcode:
   - **Product** → **Archive**
   - Wait for build to complete
   - **Window** → **Organizer** → **Distribute App**
   - Choose **App Store Connect**
   - Upload

#### Deploy to App Store

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. **My Apps** → **+** → **New App**
3. Fill in app information:
   - Platform: iOS
   - Name: MyFamilyTree
   - Primary Language: English
   - Bundle ID: com.myfamilytree
   - SKU: myfamilytree
4. Complete app metadata:
   - Privacy policy URL
   - Category: Social Networking
   - Screenshots (required sizes)
   - Description, keywords
   - Support URL
5. Select your uploaded build
6. Submit for review

**Note**: First review can take 1-3 days.

### 3.4 Web Deployment (Optional)

1. **Build for web**:

   ```bash
   flutter build web --release
   ```

2. **Deploy to Firebase Hosting**:

   ```bash
   npm install -g firebase-tools
   firebase login
   firebase init hosting
   # Select build/web as public directory
   firebase deploy
   ```

3. **Or deploy to Vercel**:

   ```bash
   npm install -g vercel
   cd build/web
   vercel
   ```

4. **Or deploy to Netlify**: Drag `build/web` folder to Netlify

---

## 4. Testing Strategy

### 4.1 Unit Tests (Backend)

```bash
cd backend
npm install --save-dev jest @types/jest ts-jest supertest @types/supertest
```

Create `backend/tests/routes.test.ts`:

```typescript
import request from "supertest";
import app from "../src/index";

describe("API Routes", () => {
  it("GET /api/health should return 200", async () => {
    const res = await request(app).get("/api/health");
    expect(res.status).toBe(200);
  });

  it("GET /api/persons/:id requires auth", async () => {
    const res = await request(app).get("/api/persons/123");
    expect(res.status).toBe(401);
  });
});
```

Run tests:

```bash
npm test
```

### 4.2 Widget Tests (Flutter)

Create `app/test/widget_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:myfamilytree/features/tree/widgets/person_card.dart';
import 'package:myfamilytree/models/models.dart';

void main() {
  testWidgets('PersonCard displays person name', (tester) async {
    final person = Person(
      id: '1',
      name: 'John Doe',
      phone: '+911234567890',
      gender: 'male',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PersonCard(person: person),
        ),
      ),
    );

    expect(find.text('John Doe'), findsOneWidget);
  });
}
```

Run tests:

```bash
cd app
flutter test
```

### 4.3 Integration Tests

Create `app/integration_test/app_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myfamilytree/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full app flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Should show login screen
    expect(find.text('MyFamilyTree'), findsOneWidget);

    // Test navigation, forms, etc.
  });
}
```

Run integration tests:

```bash
flutter test integration_test
```

### 4.4 Manual Testing Checklist

#### Authentication

- [ ] Sign up with Google works
- [ ] Sign up with email magic link works
- [ ] Email is received and link opens app
- [ ] User can sign out
- [ ] Sign in persists across app restarts

#### Profile Setup

- [ ] First-time user is prompted to complete profile
- [ ] Profile form validates required fields
- [ ] Profile is saved correctly

#### Family Tree

- [ ] Empty tree shows appropriate message
- [ ] Can add family members (father, mother, spouse, child, sibling)
- [ ] Person cards display correctly
- [ ] Tree layout is readable
- [ ] Pan and zoom work smoothly
- [ ] Connection lines render properly

#### Add Family Member

- [ ] Form validates phone number
- [ ] Can select relationship type
- [ ] Optional fields work correctly
- [ ] Person is added to tree
- [ ] Merge detection triggers when appropriate

#### Person Details

- [ ] Tapping person card opens detail screen
- [ ] All person info displays
- [ ] Can edit own profile
- [ ] Can send invites to unverified persons

#### Search & Network

- [ ] Can search by name
- [ ] Can search by phone
- [ ] Search results are accurate
- [ ] Can view other family trees (with permission)

#### Merge Requests

- [ ] Merge notification appears when applicable
- [ ] Can review merge details
- [ ] Can accept/reject merge
- [ ] Trees merge correctly on accept

#### Invitations

- [ ] Can generate invite link
- [ ] Invite link opens app
- [ ] Recipient can claim profile
- [ ] Claimed profile verifies correctly

### 4.5 Performance Testing

- **Load time**: App should start within 3 seconds
- **Tree rendering**: Should handle 100+ nodes smoothly
- **API response time**: < 500ms for most operations
- **Memory usage**: Stay under 250MB on mobile

Tools:

```bash
# Flutter DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Analyze build size
flutter build apk --analyze-size
```

### 4.6 Security Testing

- [ ] Auth tokens expire correctly
- [ ] RLS policies prevent unauthorized access
- [ ] API endpoints require authentication
- [ ] Sensitive data is not logged
- [ ] HTTPS is enforced in production
- [ ] Service role key is never exposed to client

---

## 5. Post-Deployment Checklist

### Before Going Live

- [ ] All database migrations applied
- [ ] RLS policies enabled and tested
- [ ] Production environment variables set
- [ ] OAuth credentials configured (Google)
- [ ] Email templates customized
- [ ] Backend deployed and accessible
- [ ] App built with production config
- [ ] Privacy policy published
- [ ] Terms of service published

### After Deployment

- [ ] Test complete user flow end-to-end
- [ ] Monitor error logs (Sentry, LogRocket, etc.)
- [ ] Set up analytics (Firebase Analytics, Mixpanel)
- [ ] Monitor backend performance (New Relic, Datadog)
- [ ] Set up alerts for downtime
- [ ] Create backup strategy for database
- [ ] Document API endpoints
- [ ] Create user guide/FAQ
- [ ] Set up customer support channel

### Monitoring & Maintenance

#### Backend Monitoring

Use Railway/Render/Heroku dashboards or:

```bash
# Add logging
import winston from 'winston';

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
  ],
});
```

#### App Monitoring

Add Firebase Crashlytics:

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_crashlytics: ^3.4.0
```

```dart
// main.dart
await Firebase.initializeApp();
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
```

#### Database Monitoring

Check Supabase dashboard:

- API usage
- Database size
- Active connections
- Query performance

### Scaling Considerations

- **Database**: Monitor table sizes, add indexes as needed
- **Backend**: Scale horizontally (add more instances)
- **Storage**: Monitor storage usage for photos
- **CDN**: Consider Cloudflare for static assets

---

## Troubleshooting

### Common Issues

**Issue: "Network error" in app**

- Verify backend URL is correct
- Check backend is running
- Verify CORS settings
- Check auth token is being sent

**Issue: "Database connection failed"**

- Verify Supabase credentials
- Check RLS policies
- Ensure service role key is used only on backend

**Issue: Google Sign-In fails**

- Verify OAuth Client IDs
- Check SHA-1 fingerprints (Android)
- Ensure redirect URIs match

**Issue: App crashes on startup**

- Check environment variables are loaded
- Verify Supabase initialization
- Check for missing dependencies

---

## Next Steps

1. Set up CI/CD pipeline (GitHub Actions, Bitrise)
2. Implement analytics and user tracking
3. A/B test features
4. Gather user feedback
5. Iterate and improve

## Resources

- [Supabase Docs](https://supabase.com/docs)
- [Flutter Deployment Guide](https://docs.flutter.dev/deployment)
- [Railway Docs](https://docs.railway.app/)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer/)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
