# Token Validation Error - Fix Guide

## Problem

Getting `401 Invalid or expired token` error when creating profile, even though user is logged in and has an active session.

## Root Causes

### 1. **Email Confirmation Required** (Most Common)

By default, Supabase requires users to confirm their email before they can use protected APIs. If the email is not confirmed:

- User can sign up and get a session
- But the token has limited access
- Backend API calls return 401 "Invalid or expired token"

### 2. **Stale Token**

The access token might have expired between login and profile creation, and wasn't refreshed properly.

### 3. **Configuration Mismatch**

Frontend and backend might be using different Supabase projects or keys.

## Fixes Implemented

### 1. Enhanced Token Refresh in Profile Setup

**File**: `app/lib/features/auth/screens/profile_setup_screen.dart`

- Added explicit session refresh before creating profile
- Added token comparison logging (before/after refresh)
- Added 100ms delay after refresh to ensure token propagates
- If refresh fails, show error instead of continuing

```dart
// Refresh the session to ensure we have a valid token
print('🔄 Refreshing session before profile creation...');
print('Token BEFORE refresh: ${authService.accessToken?.substring(0, 30)}...');

final refreshed = await authService.refreshSession();
if (refreshed) {
  print('✅ Session refreshed successfully');
  await Future.delayed(const Duration(milliseconds: 100));
  print('Token AFTER refresh: ${authService.accessToken?.substring(0, 30)}...');
} else {
  print('⚠️ Session refresh failed - this will likely cause token errors');
  setState(() {
    _error = 'Failed to refresh authentication. Please try logging in again.';
    _isLoading = false;
  });
  return;
}
```

### 2. Email Confirmation Check

**File**: `app/lib/features/auth/screens/profile_setup_screen.dart`

Added logging to check if email is confirmed:

```dart
// Check email confirmation status
final user = authService.currentUser;
if (user != null) {
  print('User Email: ${user.email}');
  print('Email Confirmed: ${user.confirmedAt != null}');
  print('User Created: ${user.createdAt}');

  if (user.confirmedAt == null) {
    print('⚠️ WARNING: Email not confirmed. This may cause token issues.');
  }
}
```

### 3. Improved Token Refresh Logging

**File**: `app/lib/services/auth_service.dart`

Added detailed logging to track token changes:

```dart
Future<bool> refreshSession() async {
  try {
    developer.log('🔄 Refreshing session', name: 'AuthService');
    final oldToken = currentSession?.accessToken;
    print('Old token length: ${oldToken?.length ?? 0}');

    final response = await _supabase.auth.refreshSession();

    if (response.session != null) {
      final newToken = response.session!.accessToken;
      print('New token length: ${newToken.length}');
      print('Token changed: ${oldToken != newToken}');
      developer.log('✅ Session refreshed successfully', name: 'AuthService');
      return true;
    } else {
      developer.log('⚠️ Session refresh returned null', name: 'AuthService');
      print('❌ Session refresh failed: returned null session');
      return false;
    }
  } catch (e, stackTrace) {
    developer.log(
      '❌ Error refreshing session',
      name: 'AuthService',
      error: e,
      stackTrace: stackTrace,
    );
    print('❌ Session refresh exception: $e');
    return false;
  }
}
```

### 4. Enhanced Backend Token Validation Logging

**File**: `backend/src/middleware/auth.ts`

Added detailed logging to understand why tokens are rejected:

```typescript
try {
  console.log("🔐 Validating token...");
  console.log("Token length:", token.length);
  console.log("Token preview:", token.substring(0, 30) + "...");
  console.log("Supabase URL:", env.SUPABASE_URL);

  const { data, error } = await supabaseAdmin.auth.getUser(token);

  if (error) {
    console.error("❌ Token validation error:", error.message);
    console.error("Error details:", JSON.stringify(error, null, 2));
    res
      .status(401)
      .json({ error: "Invalid or expired token", details: error.message });
    return;
  }

  if (!data.user) {
    console.error("❌ No user data returned for token");
    res.status(401).json({ error: "Invalid or expired token" });
    return;
  }

  console.log("✅ Token validated for user:", data.user.email);
  req.userId = data.user.id;
  req.userEmail = data.user.email;
  next();
} catch (err) {
  console.error("❌ Authentication exception:", err);
  res
    .status(401)
    .json({ error: "Authentication failed", exception: String(err) });
}
```

## How to Fix Email Confirmation Issue

### Option 1: Disable Email Confirmation (Development Only)

1. Go to your Supabase Dashboard
2. Navigate to **Authentication → Providers**
3. Click on **Email** provider
4. Scroll to **Email confirmation**
5. Toggle **Enable email confirmation** to OFF
6. Click **Save**

⚠️ **Warning**: Only disable this for development. In production, email confirmation should be enabled for security.

### Option 2: Confirm Email Manually

1. Go to Supabase Dashboard
2. Navigate to **Authentication → Users**
3. Find your user (chinni070707@gmail.com)
4. Click the three dots menu
5. Select **Confirm email**

### Option 3: Check Email for Confirmation Link

1. Check the email inbox for chinni070707@gmail.com
2. Look for Supabase confirmation email
3. Click the confirmation link
4. Try creating profile again

## Testing Instructions

1. **Run the diagnostics script**:

   ```powershell
   .\diagnose-token.ps1
   ```

2. **Restart both frontend and backend**:

   ```powershell
   .\stop-all.ps1
   .\start-all.ps1
   ```

3. **Watch the logs carefully**:
   - Backend console should show:
     - `🔐 Validating token...`
     - `Token length: 978`
     - `Supabase URL: ...`
     - Either `✅ Token validated` or `❌ Token validation error:`
   - Flutter console should show:
     - `🔄 Refreshing session before profile creation...`
     - `Token BEFORE refresh: ...`
     - `Token AFTER refresh: ...`
     - `Token changed: true/false`
     - `Email Confirmed: true/false`

4. **If Email Confirmed is false**:
   - This is likely the issue
   - Use one of the options above to confirm the email or disable confirmation

5. **If Email Confirmed is true**:
   - Check backend logs for specific error message
   - Verify Supabase URL matches between frontend and backend
   - Check that SUPABASE_SERVICE_ROLE_KEY in backend .env is correct

## Expected Log Output (Success)

### Frontend:

```
🔄 Refreshing session before profile creation...
Token BEFORE refresh: eyJhbGciOiJFUzI1NiIsImtpZCI6Im...
Old token length: 978
New token length: 984
Token changed: true
✅ Session refreshed successfully
Token AFTER refresh: eyJhbGciOiJFUzI1NiIsImtpZCI6Im...
User Email: chinni070707@gmail.com
Email Confirmed: true
User Created: 2025-02-17 10:30:00
📝 Creating profile for: John Doe
```

### Backend:

```
🔐 Validating token...
Token length: 984
Token preview: eyJhbGciOiJFUzI1NiIsImtpZCI6Im...
Supabase URL: https://your-project.supabase.co
✅ Token validated for user: chinni070707@gmail.com
```

## Common Error Messages and Fixes

### "Email Confirmed: false"

**Fix**: Confirm email using one of the options above

### "Token changed: false"

**Fix**: Token refresh didn't produce new token. Check:

- Session might already be fresh
- Or there's an issue with Supabase connection

### "Supabase URL: undefined"

**Fix**: Backend .env is missing SUPABASE_URL

### "Token validation error: invalid_token"

**Fix**: Token format is wrong or from different Supabase project

### "Token validation error: expired_token"

**Fix**: Token expired and refresh didn't work. User should log out and log in again.

## Files Modified

1. `app/lib/services/auth_service.dart` - Enhanced token refresh with logging
2. `app/lib/features/auth/screens/profile_setup_screen.dart` - Added refresh before profile creation and email confirmation check
3. `backend/src/middleware/auth.ts` - Enhanced token validation logging
4. `diagnose-token.ps1` - New diagnostic script

## Next Steps

1. Run `.\diagnose-token.ps1` to verify setup
2. Fix email confirmation issue using one of the options above
3. Restart services: `.\stop-all.ps1` then `.\start-all.ps1`
4. Try creating profile again
5. Check logs in both frontend and backend
6. If still failing, share the exact error messages from backend logs

## Prevention

To prevent this in the future:

1. **For Development**: Disable email confirmation in Supabase
2. **For Production**:
   - Keep email confirmation enabled
   - Add UI to show email confirmation status
   - Add "Resend confirmation email" button
   - Handle 401 errors gracefully with message to check email
