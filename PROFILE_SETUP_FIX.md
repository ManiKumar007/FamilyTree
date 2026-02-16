# Profile Setup Fix - February 16, 2026

## Problem

The "Save & Continue" button on the profile setup page was showing "Invalid or expired token" error, preventing users from completing their profile.

## Root Causes Identified

1. Session/token expiration during profile setup
2. Insufficient error handling and debugging information
3. Lack of automatic session recovery
4. Poor error messages that didn't help diagnose the issue

## Fixes Implemented

### 1. Enhanced Session Management (profile_setup_screen.dart)

**Changes:**

- Added comprehensive session state checking before API calls
- Implemented automatic session refresh before profile creation
- Added detailed logging to track the entire authentication flow
- Better error recovery with automatic sign-out and redirect on session failure

**Key Improvements:**

- Checks user session state BEFORE attempting profile creation
- Refreshes session token to ensure it's valid
- Validates token exists after refresh
- Provides clear error messages for different failure scenarios

### 2. Improved API Service Logging (api_service.dart)

**Changes:**

- Added detailed logging for the createPerson API call
- Logs token presence, length, and preview
- Logs request URL, headers, and response status
- Logs full response body for debugging

**Benefits:**

- Easy to see exactly what's being sent to the backend
- Can identify if token is missing or malformed
- Clear visibility into API responses

### 3. Better Error Handling

**Changes:**

- Categorizes errors by type (session expired, duplicate, network)
- Provides user-friendly error messages
- Auto-redirects to login on session expiration
- Shows specific guidance based on error type

**Error Types Now Handled:**

- Session expired → Clear message + auto redirect to login
- Duplicate profile → Specific "already exists" message
- Network errors → Connection-specific guidance
- Generic errors → Detailed error message

### 4. Test Script Created (test-profile-setup.ps1)

**Purpose:**

- Verify backend is running
- Test login flow with credentials
- Test profile creation API directly
- Diagnose authentication issues without the UI

## How to Test

### Step 1: Ensure Backend is Running

```powershell
.\start-backend.ps1
```

Wait for: "✅ Server is running on http://localhost:3000"

### Step 2: Hot Reload the Flutter App

In VS Code, press `r` in the terminal running Flutter, or restart the app completely.

### Step 3: Test the Profile Setup Flow

#### Option A: Test via UI

1. Sign up with a new account or log in
2. Go to the profile setup page
3. Fill in all required fields:
   - Phone number (10 digits)
   - Date of Birth
   - Gender
   - City, State, Occupation, Community (all optional)
4. Click "Save & Continue"
5. Watch the console for detailed logging output

**Expected Console Output:**

```
========================================
🔍 Profile Setup - Initial State
========================================
User: <your-email>
User ID: <uuid>
Has Session: true
Token Length: <number>
Token Preview: eyJhbGciOiJIUzI1NiI...
========================================

🔄 Refreshing session before profile creation...
✅ Session refreshed successfully
New Token Length: <number>

📝 Creating profile for: <your-name>
Phone: +91<number>
Auth User ID: <uuid>
Profile data prepared: name, given_name, phone, gender, date_of_birth, ...

📡 API Service - Creating person
URL: http://localhost:3000/api/persons
Has Token: true
Token Length: <number>
Token Preview: eyJhbGciOiJIUzI1NiI...
Response Status: 201
Response Body: {"data":{...}}

✅ Profile created successfully!
```

#### Option B: Test via Script

```powershell
.\test-profile-setup.ps1 -Email "your@email.com" -Password "yourpassword"
```

This will:

1. Check if backend is running
2. Attempt login with your credentials
3. Try to create a profile using the API directly
4. Show detailed results

### Step 4: Verify Success

After clicking "Save & Continue", you should:

1. See no error message
2. Be redirected to the family tree page
3. See your name in the tree (or empty tree if no members added yet)

## Debugging Tips

### If You Still See "Invalid or expired token"

1. **Check Console Logs:**
   Look for the detailed session state output. If you see:
   - `Token Length: 0` → Session is expired, try logging out and back in
   - `User: null` → No session found, redirect to login
   - `Has Session: false` → Session not persisted

2. **Check Backend Logs:**
   The backend terminal should show:

   ```
   POST /api/persons - User: <uuid>
   ```

   If you see "401 Unauthorized", the token validation failed

3. **Verify Supabase Configuration:**

   ```powershell
   # Check .env file exists
   ls .\app\.env

   # Check backend .env
   ls .\backend\.env
   ```

4. **Test Backend Directly:**

   ```powershell
   .\test-profile-setup.ps1 -Email "test@example.com" -Password "password123"
   ```

5. **Clear App Cache:**

   ```powershell
   # Stop the app
   # Clear Flutter cache
   flutter clean
   cd app
   flutter pub get
   cd ..

   # Restart
   .\start-frontend.ps1
   ```

### If Profile Creation Succeeds but Data Doesn't Show

1. **Check Database:**
   Go to Supabase Dashboard → Table Editor → persons
   Look for a record with your auth_user_id

2. **Check Tree Fetch:**
   Look for console logs about tree fetching:

   ```
   🌲 Fetching family tree...
   ✅ Family tree fetched: X nodes, Y relationships
   ```

3. **Invalidate Providers:**
   The profile setup screen automatically invalidates providers,
   but you can manually refresh by pulling down on the tree screen

## Files Modified

1. `app/lib/features/auth/screens/profile_setup_screen.dart`
   - Enhanced \_submitProfile() with comprehensive session handling
   - Added detailed logging throughout the flow
   - Improved error handling with specific error types

2. `app/lib/services/api_service.dart`
   - Added dart:math import
   - Enhanced createPerson() with detailed logging
   - Logs token, request, and response data

3. `test-profile-setup.ps1` (new file)
   - Standalone test script for backend and auth flow
   - Can test without running the Flutter app

## Success Indicators

✅ Backend health check passes
✅ Session refresh succeeds
✅ Token is present and has length > 0
✅ API call returns 201 Created status
✅ Profile appears in database
✅ User redirected to family tree
✅ Tree shows user's profile node

## Next Steps if Issue Persists

If after all these fixes the issue still occurs:

1. **Capture Full Logs:**
   - Copy all console output from Flutter
   - Copy all output from backend terminal
   - Take screenshot of error

2. **Check Token Validity:**
   The backend validates tokens using Supabase Admin client.
   Ensure `SUPABASE_JWT_SECRET` in backend/.env matches your Supabase project.

3. **Verify Supabase Project Status:**
   - Go to Supabase Dashboard
   - Check Authentication → Users (your user should be listed)
   - Check Authentication → Policies (RLS should allow insert for authenticated users)

4. **Check Network:**
   ```powershell
   # Test backend API directly
   curl http://localhost:3000/api/health
   ```

## Contact for Support

If you need further assistance, provide:

1. Console output from Flutter (with the detailed logs)
2. Backend terminal output
3. Screenshot of the error
4. Output from test-profile-setup.ps1 script
