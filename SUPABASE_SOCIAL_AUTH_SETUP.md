# Supabase Social Authentication Setup

This guide explains how to configure Google, Email, and Facebook authentication using Supabase as the single auth provider.

## Overview

The FamilyTree app uses **Supabase's built-in OAuth providers** for all authentication:
- ✅ Email/Password (native Supabase auth)
- ✅ Google OAuth (via Supabase)
- ✅ Facebook OAuth (via Supabase)

**Benefits:**
- Single authentication flow through Supabase
- No need for separate Google Sign-In SDK
- Centralized session management
- Consistent user experience across all auth methods

---

## 1. Email/Password Authentication

### Already Configured ✓

Email/password authentication is enabled by default in Supabase.

**Optional Settings:**
1. Go to **Authentication** → **Providers** → **Email**
2. Configure:
   - **Confirm email**: Enable for email verification
   - **Secure email change**: Enable for security
   - **Minimum password length**: Set to 6 characters (default)

---

## 2. Google OAuth Setup

### Step 1: Get Google OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Navigate to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth 2.0 Client ID**

### Step 2: Configure OAuth Consent Screen

1. Click **Configure Consent Screen**
2. Select **External** user type
3. Fill in application details:
   - **App name**: MyFamilyTree
   - **User support email**: your-email@example.com
   - **Developer contact email**: your-email@example.com
4. Add scopes: `email`, `profile`
5. Save and continue

### Step 3: Create Web Client ID

1. Application type: **Web application**
2. Name: "MyFamilyTree Web"
3. **Authorized JavaScript origins**:
   - `https://vojwwcolmnbzogsrmwap.supabase.co` (your Supabase URL)
   - `http://localhost:8080` (for local testing)
4. **Authorized redirect URIs**:
   - `https://vojwwcolmnbzogsrmwap.supabase.co/auth/v1/callback`
   - Format: `https://[YOUR-PROJECT-REF].supabase.co/auth/v1/callback`
5. Click **Create**
6. Copy the **Client ID** and **Client Secret**

### Step 4: Configure in Supabase

1. Go to your Supabase Dashboard
2. Navigate to **Authentication** → **Providers**
3. Find **Google** and click to expand
4. Enable the provider
5. Enter:
   - **Client ID** (from Google Cloud Console)
   - **Client Secret** (from Google Cloud Console)
6. Click **Save**

### Step 5: Add Redirect URLs in Supabase

1. Go to **Authentication** → **URL Configuration**
2. Add these **Redirect URLs**:
   ```
   http://localhost:8080/**
   https://your-production-domain.com/**
   ```
3. Set **Site URL** to your main app URL

---

## 3. Facebook OAuth Setup

### Step 1: Create Facebook App

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Click **My Apps** → **Create App**
3. Select **Consumer** as app type
4. Fill in:
   - **App Name**: MyFamilyTree
   - **App Contact Email**: your-email@example.com
5. Click **Create App**

### Step 2: Add Facebook Login Product

1. In your app dashboard, click **Add Product**
2. Find **Facebook Login** and click **Set Up**
3. Select **Web** as platform
4. Enter your **Site URL**: `https://vojwwcolmnbzogsrmwap.supabase.co`
5. Click **Save** and **Continue**

### Step 3: Configure OAuth Settings

1. Go to **Facebook Login** → **Settings**
2. Add **Valid OAuth Redirect URIs**:
   ```
   https://vojwwcolmnbzogsrmwap.supabase.co/auth/v1/callback
   ```
   (Replace with your actual Supabase project URL)
3. Enable **Client OAuth Login**: Yes
4. Enable **Web OAuth Login**: Yes
5. Click **Save Changes**

### Step 4: Get App Credentials

1. Go to **Settings** → **Basic**
2. Copy:
   - **App ID**
   - **App Secret** (click **Show** to reveal)
3. Add your app domains:
   - **App Domains**: `supabase.co`
   - **Privacy Policy URL**: Your privacy policy URL
   - **Terms of Service URL**: Your terms URL

### Step 5: Configure in Supabase

1. Go to your Supabase Dashboard
2. Navigate to **Authentication** → **Providers**
3. Find **Facebook** and click to expand
4. Enable the provider
5. Enter:
   - **Facebook Client ID** (App ID from Facebook)
   - **Facebook Secret** (App Secret from Facebook)
6. Click **Save**

### Step 6: Make App Live (for Production)

1. In Facebook Developers, go to **Settings** → **Basic**
2. Scroll down to **App Mode**
3. Switch from **Development** to **Live**
4. Complete any required verification steps

**Note:** Keep the app in Development mode for testing. You can add test users in **Roles** → **Test Users**.

---

## 4. Test the Integration

### Local Testing

1. Run your Flutter app:
   ```bash
   cd app
   flutter run -d chrome
   ```

2. Navigate to the login page
3. Test each auth method:
   - ✅ Email/Password signup and login
   - ✅ Google OAuth login
   - ✅ Facebook OAuth login

### Verify in Supabase Dashboard

1. Go to **Authentication** → **Users**
2. Verify users are created after successful login
3. Check user metadata for provider information

---

## 5. Environment Configuration

### App `.env` File

Ensure your `app/.env` file has:
```env
SUPABASE_URL=https://vojwwcolmnbzogsrmwap.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
API_BASE_URL=http://localhost:3000/api
```

### Backend `.env` File

Ensure your `backend/.env` file has:
```env
SUPABASE_URL=https://vojwwcolmnbzogsrmwap.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
SUPABASE_ANON_KEY=your-anon-key-here
```

---

## 6. Code Implementation

### AuthService (Already Implemented)

The `AuthService` in `app/lib/services/auth_service.dart` provides:

```dart
// Email/Password
await authService.signUpWithPassword(email: email, password: password);
await authService.signInWithPassword(email: email, password: password);

// Google OAuth
await authService.signInWithGoogle();

// Facebook OAuth
await authService.signInWithFacebook();

// Sign out
await authService.signOut();
```

### Login/Signup Screens (Already Implemented)

Both `login_screen.dart` and `signup_screen.dart` include:
- Email/password forms
- Google OAuth button
- Facebook OAuth button

---

## 7. Troubleshooting

### Google OAuth Issues

**Problem**: "redirect_uri_mismatch" error

**Solution**:
1. Verify redirect URI in Google Cloud Console matches exactly:
   `https://YOUR-PROJECT-REF.supabase.co/auth/v1/callback`
2. Check both JavaScript origins and redirect URIs are configured
3. Wait 5-10 minutes for Google changes to propagate

**Problem**: "Access blocked: This app's request is invalid"

**Solution**:
1. Ensure OAuth consent screen is configured
2. Add your email as a test user if app is not published
3. Verify scopes include `email` and `profile`

### Facebook OAuth Issues

**Problem**: "URL Blocked: This redirect failed"

**Solution**:
1. Check Valid OAuth Redirect URIs in Facebook Login settings
2. Ensure URI matches Supabase callback URL exactly
3. Verify app domain includes `supabase.co`

**Problem**: "App Not Setup: This app is still in development mode"

**Solution**:
1. Add test users in Facebook Developers → **Roles** → **Test Users**
2. OR switch app to Live mode (requires verification)

### General Issues

**Problem**: Users created but session not persisting

**Solution**:
1. Check Supabase URL Configuration has correct redirect URLs
2. Verify `authFlowType: AuthFlowType.pkce` in `main.dart`
3. Clear browser cache and cookies

**Problem**: "Invalid provider" error

**Solution**:
1. Ensure provider is enabled in Supabase Dashboard
2. Verify Client ID and Secret are configured correctly
3. Check for typos in provider name

---

## 8. Production Deployment

### Checklist

- [ ] Configure production redirect URLs in Google Cloud Console
- [ ] Configure production redirect URLs in Facebook Developers
- [ ] Add production domain to Supabase URL Configuration
- [ ] Switch Facebook app to Live mode
- [ ] Update `.env` files with production URLs
- [ ] Test all auth methods in production environment
- [ ] Set up proper SSL/HTTPS for production domain

### Security Best Practices

1. **Never commit credentials**: Keep `.env` files in `.gitignore`
2. **Use environment variables**: Different credentials for dev/staging/prod
3. **Rotate secrets regularly**: Update OAuth secrets periodically
4. **Monitor auth logs**: Check Supabase logs for suspicious activity
5. **Enable rate limiting**: Protect against brute force attacks
6. **Verify email addresses**: Enable email confirmation for production

---

## 9. Additional Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Facebook Login Documentation](https://developers.facebook.com/docs/facebook-login)
- [Supabase Auth UI Components](https://supabase.com/docs/guides/auth/auth-helpers/auth-ui)

---

## Summary

Your app now uses **Supabase as the single authentication provider** for:
- ✅ Native email/password authentication
- ✅ Google OAuth (no separate SDK needed)
- ✅ Facebook OAuth (no separate SDK needed)

All authentication flows are handled consistently through Supabase, providing:
- Unified session management
- Consistent user experience
- Simplified codebase
- Centralized user management
