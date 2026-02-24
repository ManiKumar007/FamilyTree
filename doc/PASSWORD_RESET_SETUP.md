# Password Reset Setup Guide

This guide explains how to configure password reset functionality for the FamilyTree application.

## Overview

The password reset flow works as follows:

1. User clicks "Forgot Password?" on the login screen
2. User enters their email address
3. Supabase sends a password reset email with a magic link
4. User clicks the link in their email
5. User is redirected to the reset password screen in the app
6. User enters and confirms their new password
7. Password is updated and user is logged in

## Common Issue: "Site Can't Be Reached"

If you get a "site can't be reached" error when clicking the password reset link, it means the **Redirect URLs** are not configured in Supabase.

## Setup Instructions

### 1. Configure Supabase Redirect URLs

1. Go to your **Supabase Dashboard**
2. Select your project
3. Navigate to **Authentication** → **URL Configuration**

4. **Set Site URL**:
   - Development: `http://localhost:5500`
   - Production: `https://your-production-domain.com`

5. **Add Redirect URLs** (click "Add URL" for each):

   ```
   http://localhost:5500/**
   http://localhost:5500/#/reset-password
   https://your-production-domain.com/**
   https://your-production-domain.com/#/reset-password
   ```

6. Click **Save**

### 2. Update Code for Production

When deploying to production, update the redirect URL in the code:

**File**: `app/lib/services/auth_service.dart`

```dart
// Find the resetPasswordForEmail method and update:
await _supabase.auth.resetPasswordForEmail(
  email,
  redirectTo: kIsWeb
    ? 'https://your-production-domain.com/#/reset-password'  // Update this
    : null,
);
```

### 3. Test the Flow

1. **Start the app**:

   ```powershell
   .\start-frontend.ps1
   ```

2. **Navigate to login screen**

3. **Click "Forgot Password?"**

4. **Enter your email** and submit

5. **Check your email** for the reset link

6. **Click the link** - it should open the app at `http://localhost:5500/#/reset-password`

7. **Enter new password** and submit

8. **Verify** you're logged in and redirected to the tree view

## Troubleshooting

### Error: "Site can't be reached"

- **Cause**: Redirect URLs not configured in Supabase
- **Solution**: Follow Step 1 above

### Error: "Invalid redirect URL"

- **Cause**: The URL in the code doesn't match allowed URLs in Supabase
- **Solution**: Ensure the URL in `auth_service.dart` matches one of the URLs in Supabase settings

### Email not received

- **Cause**: Email might be in spam, or email rate limiting
- **Solution**:
  - Check spam folder
  - Wait a few minutes before trying again
  - Check Supabase logs: Dashboard → Authentication → Logs

### "Password update failed"

- **Cause**: Session might have expired
- **Solution**: Click the password reset link again to get a fresh session

### Wrong port (not 5500)

If your frontend runs on a different port:

1. Update the redirect URL in `auth_service.dart`
2. Add the new URL to Supabase redirect URLs
3. Update the Site URL in Supabase

## Code Structure

### Files Involved

- **`app/lib/services/auth_service.dart`**: Contains `resetPasswordForEmail()` and `updatePassword()` methods
- **`app/lib/features/auth/screens/reset_password_screen.dart`**: UI for entering new password
- **`app/lib/features/auth/screens/login_screen.dart`**: Contains "Forgot Password?" dialog
- **`app/lib/router/app_router.dart`**: Defines the `/reset-password` route

### Key Methods

**Send Reset Email**:

```dart
await authService.resetPasswordForEmail(email);
```

**Update Password**:

```dart
await authService.updatePassword(newPassword);
```

## Security Notes

- Password reset links expire after a certain time (configured in Supabase)
- Links can only be used once
- Password must be at least 6 characters
- User must confirm password by entering it twice

## Additional Configuration

### Custom Email Templates

You can customize the password reset email in Supabase:

1. Go to **Authentication** → **Email Templates**
2. Select **Reset Password**
3. Customize the email content
4. The `{{ .ConfirmationURL }}` variable contains the reset link

### Rate Limiting

Supabase has built-in rate limiting for password reset emails to prevent abuse. The default is typically 2-3 emails per hour per email address.

## Production Checklist

- [ ] Update `redirectTo` URL in `auth_service.dart`
- [ ] Add production domain to Supabase Redirect URLs
- [ ] Set production Site URL in Supabase
- [ ] Test password reset flow in production
- [ ] Customize email template if needed
- [ ] Configure custom SMTP (optional) for branded emails

## Support

If you continue to have issues:

1. Check Supabase logs for detailed error messages
2. Verify all URLs match exactly (including `http` vs `https`, trailing slashes, etc.)
3. Test with a fresh browser session or incognito mode
4. Ensure your app is running on the expected port
