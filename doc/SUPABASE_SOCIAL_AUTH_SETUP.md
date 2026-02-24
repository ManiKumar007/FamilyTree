# Supabase Social Authentication Setup

This guide explains how to configure Google, Email, and Facebook authentication using Supabase as the single auth provider.

## ⚡ Current Configuration

**Phone authentication is DISABLED** to keep costs at $0 and simplify setup.

**Active authentication methods:**
- ✅ Email/Password - FREE
- ✅ Google OAuth - FREE
- ✅ Facebook OAuth - FREE

This covers 95%+ of users! Phone auth code is included but commented out - you can enable it later if needed.

---

## 🤔 Do You Need Phone Auth?

**You might NOT need phone auth if:**
- ✅ Your users have email addresses
- ✅ Your users have Google/Facebook accounts
- ✅ You want to keep costs at $0 (email/social are free!)
- ✅ You're targeting tech-savvy users

**You SHOULD add phone auth if:**
- 📱 Targeting users in rural areas (limited email/internet access)
- 👴 Targeting older demographics (familiar with phone/SMS)
- 🇮🇳 Targeting Indian market (WhatsApp/phone-first culture)
- 🔒 Need extra verification layer
- 💼 B2B app requiring phone verification

**Our recommendation:** Start with Email + Google + Facebook (all FREE!). Add phone auth later if you see users struggling with email/social login.

---

## Overview

The FamilyTree app currently uses **3 FREE authentication methods**:
- ✅ Email/Password (native Supabase auth) - **FREE**
- ✅ Google OAuth (via Supabase) - **FREE**
- ✅ Facebook OAuth (via Supabase) - **FREE**
- ⏸️ Phone/SMS OTP - **DISABLED** (requires paid SMS provider)

**Benefits:**
- Single authentication flow through Supabase
- No need for separate Google Sign-In SDK
- Centralized session management
- Consistent user experience across all auth methods
- **Zero ongoing costs** for authentication
- Multiple options for different user preferences

**To enable Phone Auth later:** See section 2 below for setup instructions.

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

## 2. Phone/SMS Authentication ⏸️ (CURRENTLY DISABLED)

> **✅ Status:** Phone auth code is included but **UI is disabled** to keep costs at $0.  
> **💰 Cost:** Requires paid SMS provider (~₹0.60-0.80 per login)  
> **🔓 How to enable:** Follow steps below, then uncomment phone buttons in login/signup screens  

### � SMS Provider Required

**Note:** Supabase requires a third-party SMS provider for phone authentication. There's no free/default option anymore.

**Best Options for Getting Started:**

1. **Twilio** (Most Popular - Easiest Setup)
   - 💰 **Free trial credits**: $15-20 to start
   - 📊 Cost: ~$0.0075 per SMS in India, ~$0.01 in US
   - ⏱️ Setup time: 10 minutes
   - ✅ Works globally
   - 👍 **Recommended for beginners**

2. **Textlocal** (Good for India)
   - 💰 Pay-per-use, no monthly fee
   - 📊 Cost: ~₹0.10-0.25 per SMS in India
   - 🇮🇳 Best for Indian users
   - ⏱️ Setup time: 15 minutes

3. **MessageBird** (Europe)
   - 💰 Free trial credits available
   - 📊 Competitive pricing
   - 🇪🇺 Strong in Europe

**Cost Reality Check:**
- 100 test messages = ~$1 (₹80)
- 1000 auth messages = ~$10 (₹800)
- Very affordable for testing and small-scale production!

---

### Step 1: Set Up Twilio (Recommended)

**Why Twilio:** Free trial credits, globally reliable, easiest to set up.

1. **Create Twilio Account**:
   - Go to [Twilio Console](https://www.twilio.com/try-twilio)
   - Sign up (no credit card needed for trial)
   - Verify your email and phone
   - Get **$15-20 in free trial credits** 🎉

2. **Get a Phone Number**:
   - In Twilio Console → **Phone Numbers** → **Buy a number**
   - Select a country (US is cheapest, ~$1/month)
   - Choose a number with **SMS capability**
   - Purchase it (uses your free credits)

3. **Get Your Credentials**:
   - Go to Twilio Console **Dashboard**
   - Copy these values:
     - **Account SID** (starts with AC...)
     - **Auth Token** (click to reveal)
     - **Phone Number** (the one you just bought, e.g., +1234567890)

---

### Step 2: Configure in Supabase

1. Go to your Supabase Dashboard
2. Navigate to **Authentication** → **Providers** → **Phone**
3. Toggle **"Enable Phone Sign-ups"** ON
4. Select **Twilio** as SMS provider
5. Enter your credentials:
   - **Twilio Account SID**
   - **Twilio Auth Token**
   - **Twilio Phone Number** (with country code, e.g., +12345678901)
6. Click **Save**

---

### Step 3: Configure Phone Settings

1. In **Authentication** → **Providers** → **Phone**:
   - **Enable Phone Sign-ups**: Toggle ON
   - **Enable Phone OTP**: Toggle ON
   - **OTP Expiry**: Set to 60 seconds (default)
   - **OTP Length**: 6 digits (recommended)

---

### Step 4: Test Phone Authentication

1. Run your Flutter app
2. Click "Continue with Phone" on login/signup screen
3. Enter phone number with country code (e.g., +919876543210)
4. Receive OTP via SMS (usually arrives within 5-10 seconds)
5. Enter OTP to verify and sign in

**Twilio Trial Limitations:**
- Can only send SMS to **verified phone numbers** during trial
- To verify your phone: Twilio Console → **Phone Numbers** → **Verified Caller IDs**
- Enter your phone number and verify with code
- Once verified, you can test phone auth with that number
- After adding payment method, you can send to any number

### Phone Number Format

- Must include country code: `+[country code][number]`
- Examples:
  - India: `+919876543210`
  - USA: `+11234567890`
  - UK: `+447911123456`

### Supported Countries

The app includes pre-configured country codes for:
- 🇮🇳 India (+91)
- 🇺🇸 USA/Canada (+1)
- 🇬🇧 UK (+44)
- 🇦🇪 UAE (+971)
- 🇦🇺 Australia (+61)
- 🇸🇬 Singapore (+65)
- 🇨🇳 China (+86)
- 🇯🇵 Japan (+81)
- 🇰🇷 South Korea (+82)
- 🇩🇪 Germany (+49)
- 🇫🇷 France (+33)

---

### 🔓 How to Re-Enable Phone Auth

When you're ready to add phone authentication (requires SMS provider setup above):

**Step 1:** Uncomment in [login_screen.dart](../app/lib/features/auth/screens/login_screen.dart):
```dart
// Remove the /* and */ around the phone button:
const SizedBox(height: 12),
ElevatedButton.icon(
  onPressed: () => _showPhoneAuth(context, ref),
  icon: const Icon(Icons.phone),
  label: const Text('Sign in with Phone'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
  ),
),

// Uncomment the import at the top:
import '../widgets/phone_auth_dialog.dart';
```

**Step 2:** Uncomment in [signup_screen.dart](../app/lib/features/auth/screens/signup_screen.dart):
```dart
// Remove the /* and */ around the phone button (same as above)
// Uncomment the import (same as above)
```

That's it! The phone auth infrastructure is already in place. Once you configure an SMS provider in Supabase and uncomment these lines, phone authentication will work.

---

## 3. Google OAuth Setup

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

## 4. Facebook OAuth Setup

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

## 5. Test the Integration

### Local Testing

1. Run your Flutter app:
   ```bash
   cd app
   flutter run -d chrome
   ```

2. Navigate to the login page
3. Test each auth method:
   - ✅ Email/Password signup and login   - ✅ Phone/OTP login   - ✅ Google OAuth login
   - ✅ Facebook OAuth login

### Verify in Supabase Dashboard

1. Go to **Authentication** → **Users**
2. Verify users are created after successful login
3. Check user metadata for provider information

---

## 6. Environment Configuration

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

## 7. Code Implementation

### AuthService (Already Implemented)

The `AuthService` in `app/lib/services/auth_service.dart` provides:

```dart
// Email/Password
await authService.signUpWithPassword(email: email, password: password);
await authService.signInWithPassword(email: email, password: password);

// Phone/OTP
await authService.signInWithPhone(phoneNumber); // Sends OTP
await authService.verifyPhoneOTP(phoneNumber: phone, otpCode: otp);

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
- Phone number authentication button (opens `PhoneAuthDialog`)
- Google OAuth button
- Facebook OAuth button

### Phone Auth Dialog

The `PhoneAuthDialog` widget (`app/lib/features/auth/widgets/phone_auth_dialog.dart`) provides:
- Country code selector (11 countries pre-configured)
- Phone number input with validation
- OTP input (6-digit code)
- Resend OTP functionality
- Auto-navigation after successful verification

---

## 8. Troubleshooting

### Phone/OTP Issues

**Problem**: "Failed to send OTP" or "Invalid phone number"

**Solution**:
1. Verify phone number includes country code: `+919876543210`
2. Check SMS provider is configured in Supabase
3. Verify Twilio credentials are correct
4. Check Twilio account has sufficient credits
5. Ensure phone number is not on any block lists

**Problem**: "OTP verification failed" or "Invalid token"

**Solution**:
1. Check OTP is entered within expiry time (60 seconds default)
2. Verify OTP code is exactly 6 digits
3. Don't include spaces or dashes in OTP
4. Try resending OTP if expired

**Problem**: "No SMS received"

**Solution**:
1. **If using Twilio trial**: Phone number must be verified in Twilio Console first
2. Check phone number is correct and includes country code (+919876543210)
3. Verify SMS provider credits/balance in provider dashboard
4. Check SMS delivery logs in Twilio Console → **Monitor** → **Logs**
5. Ensure phone carrier supports SMS (some carriers block promotional SMS)
6. Check spam/blocked messages on phone
7. Try different phone number

**Problem**: "Rate limit exceeded" or "Too many requests"

**Solution**:
1. Twilio has rate limits per account tier
2. Check Twilio Console for your current limits
3. Wait for rate limit window to reset (usually 1 hour)
4. Implement frontend rate limiting to prevent abuse
5. Consider upgrading Twilio account tier if hitting limits frequently

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

## 9. Production Deployment

### Checklist

- [ ] Configure production redirect URLs in Google Cloud Console
- [ ] Configure production redirect URLs in Facebook Developers
- [ ] **[Phone Auth]** Upgrade Twilio trial to paid account (remove trial restrictions)
- [ ] **[Phone Auth]** Verify Twilio has sufficient credits/balance
- [ ] **[Phone Auth]** Set up SMS delivery monitoring and alerts
- [ ] Add production domain to Supabase URL Configuration
- [ ] Switch Facebook app to Live mode
- [ ] Update `.env` files with production URLs
- [ ] Test all auth methods in production environment
- [ ] Set up proper SSL/HTTPS for production domain
- [ ] **[Phone Auth]** Monitor SMS delivery rates and costs in Twilio dashboard

### SMS Provider Costs

**Twilio Pricing (most common):**
- **India**: ~₹0.60 per SMS (~$0.0075)
- **USA**: ~₹0.80 per SMS (~$0.01)
- **Phone Number Rental**: ~₹80-100/month (~$1/month)

**Real-world examples:**
- 100 auth messages = ~₹60-80 (~$1)
- 1,000 auth messages = ~₹600-800 (~$8-10)
- 10,000 auth messages = ~₹6,000-8,000 (~$75-100)

**Monthly estimates:**
- Small app (100 users, 3 logins/month each) = ~₹180 (~$2.25)
- Medium app (1000 users) = ~₹1,800 (~$22)
- Large app (10,000 users) = ~₹18,000 (~$225)

**Note:** If NOT using Phone Auth, all other auth methods (Email, Google, Facebook) are completely FREE! ✅

### Security Best Practices

1. **Never commit credentials**: Keep `.env` files in `.gitignore`
2. **Use environment variables**: Different credentials for dev/staging/prod
3. **Rotate secrets regularly**: Update OAuth secrets periodically
4. **Monitor auth logs**: Check Supabase logs for suspicious activity
5. **Enable rate limiting**: Protect against brute force attacks
6. **Verify email addresses**: Enable email confirmation for production

---

## 10. Additional Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Supabase Phone Auth Documentation](https://supabase.com/docs/guides/auth/phone-login)
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Facebook Login Documentation](https://developers.facebook.com/docs/facebook-login)
- [Twilio SMS Documentation](https://www.twilio.com/docs/sms)
- [Supabase Auth UI Components](https://supabase.com/docs/guides/auth/auth-helpers/auth-ui)

---

## 11. Summary

Your app is using **Supabase as the single authentication provider** with:
- ✅ Native email/password authentication (**FREE**)
- ✅ Google OAuth (no separate SDK needed) (**FREE**)
- ✅ Facebook OAuth (no separate SDK needed) (**FREE**)
- ⏸️ Phone/SMS OTP authentication (**DISABLED** - can enable later)

**Current Setup:**
- 🎉 **100% FREE authentication** - No SMS costs
- 📊 Covers 95%+ of users with email/social options
- 🔧 Phone auth code is included (commented out) for future use
- 💰 Zero ongoing costs for authentication

All authentication flows are handled consistently through Supabase, providing:
- Unified session management
- Consistent user experience
- Simplified codebase
- Centralized user management
- Multiple options for different user needs

### 🎯 Quick Stats

**Current auth options:** 3 free methods
**Monthly cost:** ₹0 / $0 ✅
**User coverage:** 95%+ (email/Google/Facebook)
**Setup time:** ~30 minutes for all three
**Ongoing maintenance:** Minimal

### 💡 When to Add Phone Auth

Consider adding phone auth if you notice:
- Users struggling to sign up with email/social
- High dropout rates on signup
- Specific user segment requests for phone login
- Targeting demographics without email/social access

Until then, enjoy **completely free authentication!** 🎉
