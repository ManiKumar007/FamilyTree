# Authentication Setup Guide

This guide covers the setup of Google Sign-In and Email Magic Link authentication.

## Prerequisites

- Supabase project created
- Google Cloud Console project created
- Flutter environment set up

## Step 1: Supabase Configuration

### 1.1 Enable Authentication Providers

1. Go to your Supabase project dashboard
2. Navigate to **Authentication** → **Providers**
3. Enable **Email** provider
   - Enable "Confirm email" if you want email verification
   - Set "Secure email change" to enabled
4. Enable **Google** provider
   - You'll need to add Google OAuth credentials (see Step 2)

### 1.2 Configure Redirect URLs

**IMPORTANT**: To enable password reset and OAuth, you must configure redirect URLs:

1. Go to **Authentication** → **URL Configuration**
2. Set **Site URL**:
   - For development: `http://localhost:5500`
   - For production: `https://your-domain.com`
3. Add **Redirect URLs** (one per line):
   ```
   http://localhost:5500/**
   http://localhost:5500/#/reset-password
   https://your-domain.com/**
   ```

### 1.3 Configure Email Templates

1. Go to **Authentication** → **Email Templates**
2. Customize the "Magic Link" template if desired
3. For **Password Recovery** template:
   - The redirect URL is set programmatically in the app
   - Development: redirects to `http://localhost:5500/#/reset-password`
   - Production: update in `auth_service.dart` to use your production URL

### 1.4 Get Supabase Credentials

1. Go to **Settings** → **API**
2. Copy the following:
   - Project URL
   - `anon` public key
   - `service_role` secret key (for backend only)

## Step 2: Google Cloud Console Setup

### 2.1 Create OAuth 2.0 Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project or create a new one
3. Navigate to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth 2.0 Client ID**

### 2.2 Configure OAuth Consent Screen

1. Click **Configure Consent Screen**
2. Select **External** user type
3. Fill in:
   - App name: "MyFamilyTree"
   - User support email
   - Developer contact email
4. Add scopes: `email`, `profile`
5. Save and continue

### 2.3 Create OAuth Client IDs

You'll need three OAuth Client IDs:

#### Web Client ID (for Supabase)

1. Application type: **Web application**
2. Name: "MyFamilyTree Web"
3. Authorized redirect URIs: Add your Supabase callback URL
   - Format: `https://[YOUR-PROJECT-REF].supabase.co/auth/v1/callback`
4. Copy the **Client ID** and **Client Secret**

#### Android Client ID

1. Application type: **Android**
2. Name: "MyFamilyTree Android"
3. Package name: `com.myfamilytree`
4. SHA-1 certificate fingerprint:

   ```bash
   # Debug keystore
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

   # For Windows
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```

5. Copy the SHA-1 and add it to the credential
6. Copy the **Client ID**

#### iOS Client ID

1. Application type: **iOS**
2. Name: "MyFamilyTree iOS"
3. Bundle ID: `com.myfamilytree`
4. Copy the **Client ID**

### 2.4 Add Credentials to Supabase

1. Go back to Supabase **Authentication** → **Providers** → **Google**
2. Enable Google provider
3. Enter the **Web Client ID** and **Client Secret** from Step 2.3
4. Save

## Step 3: Backend Configuration

### 3.1 Create Backend .env File

1. Navigate to `backend/` directory
2. Copy `.env.example` to `.env`
   ```bash
   cp .env.example .env
   ```
3. Fill in the values:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
   SUPABASE_ANON_KEY=your-anon-key
   PORT=3000
   NODE_ENV=development
   APP_URL=http://localhost:8080
   INVITE_BASE_URL=http://localhost:8080/invite
   ```

### 3.2 Install Dependencies

```bash
cd backend
npm install
```

### 3.3 Start Backend Server

```bash
npm run dev
```

The backend should now be running on `http://localhost:3000`

## Step 4: Flutter App Configuration

### 4.1 Create App .env File

1. Navigate to `app/` directory
2. Copy `.env.example` to `.env`
   ```bash
   cp .env.example .env
   ```
3. Fill in the values:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   API_BASE_URL=http://localhost:3000/api
   GOOGLE_WEB_CLIENT_ID=your-google-web-client-id.apps.googleusercontent.com
   ```

Note: `GOOGLE_WEB_CLIENT_ID` should be the **Web Client ID** from Step 2.3, not the Android or iOS one.

### 4.2 Android Configuration

1. Open `android/app/build.gradle`
2. Ensure `applicationId` matches your package name:

   ```gradle
   android {
       defaultConfig {
           applicationId "com.myfamilytree"
           // ...
       }
   }
   ```

3. Google Sign-In is configured via `google_sign_in` package, no additional setup needed for basic functionality

### 4.3 iOS Configuration

1. Open `ios/Runner/Info.plist`
2. Add URL scheme for Google Sign-In:

   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <!-- Replace with your iOS Client ID -->
               <string>com.googleusercontent.apps.YOUR-IOS-CLIENT-ID</string>
           </array>
       </dict>
       <!-- Deep link for magic link callback -->
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>com.myfamilytree</string>
           </array>
       </dict>
   </array>
   ```

3. Update Bundle Identifier in Xcode to `com.myfamilytree`

### 4.4 Install Dependencies

```bash
cd app
flutter pub get
```

### 4.5 Run the App

```bash
flutter run
```

## Step 5: Testing Authentication

### 5.1 Test Google Sign-In

1. Launch the app
2. Click "Continue with Google"
3. Select a Google account
4. Should redirect back to the app signed in

### 5.2 Test Email Magic Link

1. Launch the app
2. Enter your email address
3. Click "Send Magic Link"
4. Check your email
5. Click the magic link
6. Should open the app signed in

**Note for Development**: Email magic links may not work perfectly in development due to deep linking. For production, configure proper deep links in Supabase and your app.

## Step 6: Troubleshooting

### Google Sign-In Issues

**"Sign in cancelled" error:**

- Check OAuth consent screen is configured
- Verify OAuth Client IDs are created correctly
- For Android: Ensure SHA-1 fingerprint is correct

**"Invalid Client ID" error:**

- Verify Web Client ID in `.env` matches Google Cloud Console
- Ensure Supabase Google provider has correct credentials

### Email Magic Link Issues

**Email not received:**

- Check spam folder
- Verify email provider is enabled in Supabase
- Check Supabase email logs in Dashboard → Authentication → Logs

**Magic link doesn't open app:**

- Configure deep linking properly
- In development, you may need to manually copy the token from the email

### Backend Connection Issues

**"Network error" or "Connection refused":**

- Ensure backend is running on correct port
- Check `API_BASE_URL` in app's `.env`
- For physical devices, use your computer's IP instead of localhost

## Security Notes

1. **Never commit `.env` files** to version control
2. **Service role key** should only be used on the backend, never in the Flutter app
3. For production:
   - Use environment variables or secure secret management
   - Enable RLS policies in Supabase
   - Configure proper CORS settings on backend
   - Use HTTPS for all communications

## Next Steps

After authentication is working:

1. Test the entire flow end-to-end
2. Set up RLS policies in Supabase (already in migrations)
3. Implement profile setup screen
4. Connect to family tree features
