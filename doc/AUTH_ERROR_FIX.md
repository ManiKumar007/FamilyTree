# Authentication Error Fix

## Problem
Sign-in failed with error: `ClientFailed to fetch, uri=https://voiwwcolmnbzogsrmwap.supabase.co/auth/v1/token`

**Root Cause**: Flutter web doesn't load `.env` files at runtime like mobile apps do. The app was running without proper environment variables, causing it to use default or cached values.

## What Was Fixed

### 1. Updated Startup Scripts
Modified `start-frontend.ps1` and `start-frontend-fast.ps1` to:
- Load environment variables from `.env` file
- Pass them as `--dart-define` compile-time flags to Flutter
- This ensures the values are embedded in the web build

### 2. Updated Configuration Layer
Modified `app/lib/config/constants.dart` to:
- Prioritize `--dart-define` values over `.env` values
- Provide proper fallbacks
- Support both web and mobile platforms

### 3. Updated Main Entry Point
Modified `app/lib/main.dart` to:
- Handle missing `.env` file gracefully
- Use `--dart-define` values with `.env` as fallback
- Add debug logging for Supabase configuration

## How to Fix

### Step 1: Clear Browser Cache
1. Open Chrome DevTools (F12)
2. Go to Application tab → Storage
3. Click "Clear site data"
4. Or use Incognito mode for testing

### Step 2: Stop All Flutter Processes
```powershell
Get-Process | Where-Object { $_.ProcessName -match 'dart|flutter' } | Stop-Process -Force
```

### Step 3: Verify Configuration
```powershell
.\verify-frontend-config.ps1
```

This will:
- Check if `.env` file exists
- Display environment variables
- Test Supabase connectivity

### Step 4: Start Fresh
```powershell
# Clean build artifacts
cd app
flutter clean

# Return to root and start
cd ..
.\start-frontend.ps1
```

## Verify the Fix

1. Watch the console output when the app starts
2. Look for these debug messages:
   ```
   🔧 Supabase URL: https://vojwwcolmnbzogsrmwap.supabase.co
   🔧 Anon Key length: 183
   ```

3. The URL should be **`vojwwcolmnbzogsrmwap`** (with 'j'), not 'voiwwcolmnbzogsrmwap' (with 'i')

4. Try signing in again with your credentials

## If Still Not Working

### Check Backend is Running
```powershell
# In a separate terminal
.\start-backend.ps1
```

Backend should be running on `http://localhost:3000`

### Verify .env File
Make sure `app/.env` has correct values:
```env
SUPABASE_URL=https://vojwwcolmnbzogsrmwap.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
API_BASE_URL=http://localhost:3000/api
APP_URL=http://localhost:5500
```

### Check Supabase Dashboard
1. Go to https://app.supabase.com
2. Verify your project is active
3. Check Settings → API for correct URL and keys

### Test with Curl
```powershell
$url = "https://vojwwcolmnbzogsrmwap.supabase.co/rest/v1/"
Invoke-WebRequest -Uri $url -Method GET
```

Should return HTTP 200 or 400 (not connection refused)

## For Deployed Version (Vercel)

If deploying to Vercel, ensure environment variables are set:

1. Go to Vercel Dashboard → Your Project → Settings → Environment Variables
2. Add:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `API_BASE_URL`
   - `APP_URL`

3. Redeploy the application

## Technical Details

### Why This Happened
- **Mobile apps**: Can read `.env` files at runtime using `flutter_dotenv`
- **Web apps**: Files are bundled at compile time, runtime file access is restricted
- **Solution**: Pass environment variables as compile-time constants using `--dart-define`

### The Fix Flow
```
.env file → PowerShell script → --dart-define flags → Flutter compile → Embedded in JS bundle → Runtime access
```

### Alternative Approaches Considered
1. ✅ **Compile-time variables** (chosen): Most reliable, works everywhere
2. ❌ Copy .env to web/assets: Security risk, exposes secrets
3. ❌ Hardcode values: Not flexible, requires rebuild for changes
4. ❌ Load from server: Extra network call, complicated setup

## Files Modified
- [start-frontend.ps1](start-frontend.ps1) - Added env loading and dart-define
- [start-frontend-fast.ps1](start-frontend-fast.ps1) - Added env loading and dart-define
- [app/lib/config/constants.dart](app/lib/config/constants.dart) - Prioritize dart-define values
- [app/lib/main.dart](app/lib/main.dart) - Graceful env loading with fallbacks

## Files Created
- [verify-frontend-config.ps1](verify-frontend-config.ps1) - Configuration verification tool
