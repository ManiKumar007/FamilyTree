# Application Testing Guide & Admin Setup

## 🚀 Application Status

### Services Running

- ✅ Backend (Node.js): http://localhost:3000
- ✅ Frontend (Flutter Web): http://localhost:5500

### Quick Access

- **Main App**: http://localhost:5500
- **Backend API**: http://localhost:3000/api
- **Health Check**: http://localhost:3000/api/health

---

## 📋 Feature Testing Checklist

### 1. Authentication Features

#### Signup Flow

- [ ] Navigate to http://localhost:5500
- [ ] Click "Sign Up" link
- [ ] Fill in form:
  - Full Name: `Test User`
  - Email: `test@example.com`
  - Password: `test123456`
  - Confirm Password: `test123456`
- [ ] Click "Sign Up" button
- [ ] **Expected**: Success message and redirect to login
- [ ] **Logs**: Check browser console (F12) for detailed logs:
  - 📝 Sign up attempt started
  - 📡 Calling Supabase auth.signUp
  - ✅ Supabase sign up successful

#### Login Flow

- [ ] On login page, enter email: `test@example.com`
- [ ] Enter password: `test123456`
- [ ] Click "Sign In" button
- [ ] **Expected**: Redirect to family tree view
- [ ] **Logs**: Check browser console for:
  - 🔐 Sign in attempt started
  - 📡 Calling Supabase auth.signInWithPassword
  - ✅ Supabase sign in successful
  - 🚀 Navigating to home screen

#### Form Validation

- [ ] **Empty Email**: Try submitting without email → Shows "Please enter your email"
- [ ] **Invalid Email**: Enter "notanemail" → Shows "Please enter a valid email"
- [ ] **Short Password**: Enter "123" → Shows "Password must be at least 6 characters"
- [ ] **Password Mismatch** (Signup): Different passwords → Shows "Passwords do not match"
- [ ] **Password Visibility**: Click eye icon → Password becomes visible

---

### 2. Family Tree Features

#### View Tree

- [ ] After login, navigate to Tree view
- [ ] **Expected**: See family tree visualization
- [ ] **Test**: Pan and zoom canvas
- [ ] **Test**: Click on person cards

#### Add Family Member

- [ ] Click "Add Member" button (+ icon)
- [ ] Fill in member details:
  - Name: `John Doe`
  - Date of Birth: `1990-01-01`
  - Gender: `Male`
  - Phone: `+1234567890`
  - Community: `Test Community`
- [ ] Select relationship type (parent/child/sibling/spouse)
- [ ] Click "Save"
- [ ] **Expected**: New member appears in tree

#### Edit Profile

- [ ] Click on a person card
- [ ] Click "Edit" button
- [ ] Update details (occupation, city, etc.)
- [ ] Click "Save"
- [ ] **Expected**: Changes reflected immediately

#### Search Functionality

- [ ] Navigate to Search screen
- [ ] Enter search term: `Kumar`
- [ ] **Expected**: See matching results
- [ ] **Test**: Search by phone number
- [ ] **Test**: Filter by community

---

### 3. Admin Panel Features

**⚠️ Admin Access Requires Setup (See Section Below)**

#### Dashboard

- [ ] Navigate to `/admin` route
- [ ] **Expected**: Analytics dashboard with charts
- [ ] **See**: Total users, active users, new signups
- [ ] **See**: User growth chart (last 30 days)

#### User Management

- [ ] Navigate to Admin → User Management
- [ ] **Expected**: List of all users
- [ ] **Test**: Search for specific user
- [ ] **Test**: Filter by role (user/admin/super_admin)
- [ ] **Test**: Toggle user active/inactive status
- [ ] **Test**: Update user role (super admin only)

#### Error Logs

- [ ] Navigate to Admin → Error Logs
- [ ] **Expected**: List of application errors
- [ ] **Test**: Filter by severity (error/warning/info)
- [ ] **Test**: Search error messages
- [ ] **Test**: Mark errors as resolved
- [ ] **Test**: Delete old errors

#### Analytics

- [ ] Navigate to Admin → Analytics
- [ ] **Expected**: Visual charts showing:
  - User registrations over time
  - Active users trend
  - Feature usage statistics
- [ ] **Test**: Change date range filters

---

## 🔑 Admin Panel Access Setup

### Problem: No Default Admin Credentials

The application uses **Supabase Authentication**, which means:

- ❌ No pre-created admin users exist in the database
- ❌ Admin credentials are NOT hardcoded anywhere
- ✅ You must create your own admin account manually

### Solution: Create and Promote Admin User

#### Step 1: Create a Regular User Account

1. Navigate to http://localhost:5500
2. Click "Sign Up"
3. Create account:
   - Email: `admin@familytree.com`
   - Password: `AdminPass123!` (choose a strong password)
   - Name: `Admin User`
4. Complete signup process

#### Step 2: Get Your User ID

After signup, check browser console (F12) for the log:

```
✅ Supabase sign up successful
{
  user_id: "123e4567-e89b-12d3-a456-426614174000",  // Copy this
  email: "admin@familytree.com"
}
```

**OR** run this in Supabase SQL Editor:

```sql
SELECT id, email FROM auth.users WHERE email = 'admin@familytree.com';
```

#### Step 3: Promote to Super Admin

Use Supabase SQL Editor or MCP to run:

```sql
-- Insert or update user_metadata to make user a super_admin
INSERT INTO user_metadata (user_id, role, is_active)
VALUES ('YOUR-USER-ID-HERE', 'super_admin', true)
ON CONFLICT (user_id) DO UPDATE
  SET role = 'super_admin', is_active = true;
```

Replace `YOUR-USER-ID-HERE` with the actual UUID from Step 2.

#### Step 4: Verify Admin Access

1. Log out and log back in with admin credentials
2. Navigate to `/admin` route
3. **Expected**: You should see the admin dashboard

If you see "Access Denied", check:

- User role in database: `SELECT * FROM user_metadata WHERE user_id = 'YOUR-ID';`
- Should show `role = 'super_admin'`

---

## 🧪 API Testing (Optional)

### Using PowerShell

```powershell
# Health Check
Invoke-RestMethod -Uri "http://localhost:3000/api/health" -Method GET

# Create an account first, then get the auth token from browser DevTools
# Look for the access_token in localStorage or session storage

$token = "your-supabase-access-token-here"
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Get all persons
Invoke-RestMethod -Uri "http://localhost:3000/api/persons" -Method GET -Headers $headers

# Search
Invoke-RestMethod -Uri "http://localhost:3000/api/search?q=Kumar" -Method GET -Headers $headers

# Admin endpoints (requires admin token)
Invoke-RestMethod -Uri "http://localhost:3000/api/admin/users" -Method GET -Headers $headers
Invoke-RestMethod -Uri "http://localhost:3000/api/admin/analytics/summary" -Method GET -Headers $headers
```

### Using curl (if installed)

```bash
# Health Check
curl http://localhost:3000/api/health

# With authentication
curl -H "Authorization: Bearer YOUR-TOKEN" http://localhost:3000/api/persons
```

---

## 📊 Test Data Available

### Seed Data (Chinni Family)

The database contains pre-loaded sample data:

- **7 Family Members**: 3 generations (grandparents, parents, children)
- **14 Relationships**: Parent-child, spouses, siblings
- **Location**: Vijayawada, Guntur, Hyderabad, Bangalore

You can view this data after logging in.

---

## 🐛 Troubleshooting

### Frontend Not Loading

```powershell
# Check if Flutter is still running
Get-NetTCPConnection -LocalPort 5500

# Restart Frontend
Get-Process | Where-Object { $_.ProcessName -match 'dart|flutter' } | Stop-Process -Force
cd app
C:\src\flutter\bin\flutter.bat run -d web-server --web-port=5500
```

### Backend Not Responding

```powershell
# Check if Node.js is running
Get-NetTCPConnection -LocalPort 3000

# Restart Backend
cd backend
npm run dev
```

### Cannot Sign Up / Sign In

1. Check browser console (F12) for error messages
2. Verify Supabase connection in `app/.env`:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```
3. Check backend `.env` has same Supabase credentials

### Admin Panel Shows "Access Denied"

1. Verify you completed Step 3 (Promote to Super Admin)
2. Check database:
   ```sql
   SELECT * FROM user_metadata WHERE user_id = 'YOUR-USER-ID';
   ```
3. Log out and log back in (token refresh)
4. Clear browser cache and localStorage

### Integration Tests Failing

```powershell
# Run tests
cd app
C:\src\flutter\bin\flutter.bat test integration_test/auth_test.dart -d chrome

# If tests fail, check:
# 1. Services are running (ports 3000 and 5500)
# 2. Supabase connection is working
# 3. No compilation errors in code
```

---

## 📝 Logging & Debugging

### View Authentication Logs

All authentication operations log detailed information:

1. Open browser DevTools (F12)
2. Go to Console tab
3. Perform signup/login
4. See detailed logs:
   - Form validation
   - API calls
   - Success/failure with details
   - Navigation events

### Example Log Output

```
🔐 Sign in attempt started  {email: "test@example.com"}
📞 Calling authService.signInWithPassword
📡 Calling Supabase auth.signInWithPassword
✅ Supabase sign in successful {
  user_id: "123...",
  email: "test@example.com",
  has_session: true,
  access_token_length: 852
}
🚀 Navigating to home screen
```

---

## ✅ Testing Summary

**Total Features**: 15+
**Authentication**: 5 test cases
**Family Tree**: 4 test cases  
**Admin Panel**: 4 test cases
**API Endpoints**: 10+ endpoints

**Next Steps**:

1. ✅ Complete authentication testing
2. ✅ Create admin account using steps above
3. ✅ Test all family tree features
4. ✅ Test admin panel functionality
5. ✅ Run integration tests

---

## 📚 Related Documentation

- [IMPLEMENTATION_SUMMARY_20260216.md](IMPLEMENTATION_SUMMARY_20260216.md) - Recent changes
- [TESTING_MIGRATION.md](TESTING_MIGRATION.md) - Test architecture
- [app/integration_test/README.md](app/integration_test/README.md) - Integration test guide
- [SEED_DATA.md](SEED_DATA.md) - Sample data details

---

**Last Updated**: February 16, 2026  
**Status**: ✅ All services running and ready for testing  
**Admin Setup**: Manual promotion required (see above)
