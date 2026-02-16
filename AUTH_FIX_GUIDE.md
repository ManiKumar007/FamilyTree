# Authentication Issue Fix Guide

## 🚨 Problem Identified

**Your authentication is failing because the Supabase ANON_KEY is using a placeholder value instead of the actual JWT token.**

### Current Issue:

```
❌ SUPABASE_ANON_KEY=sb_publishable_7gumsvulTmP1yCPumQLUYQ_PVVGyHqZ
   (This is a placeholder, not a valid Supabase anon key)
```

### Expected Format:

```
✅ SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6...
   (A JWT token starting with "eyJ")
```

---

## 🔧 How to Fix

### Step 1: Get Your Correct Supabase Anon Key

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project: **vojwwcolmnbzogsrmwap**
3. Click on the **Settings** icon (⚙️) in the left sidebar
4. Go to **API** section
5. Copy the **`anon public`** key (it's a long JWT token starting with `eyJ`)

**Example of what it looks like:**

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvand3Y29sbW5iem9nc3Jtd2FwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExNDgyNDYsImV4cCI6MjA4NjcyNDI0Nn0.ABC123DEF456...
```

### Step 2: Update Your .env Files

You need to update **TWO** .env files with the correct key:

#### File 1: `backend/.env`

```bash
# Update this line:
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.YOUR_ACTUAL_ANON_KEY_HERE
```

#### File 2: `app/.env`

```bash
# Update this line:
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.YOUR_ACTUAL_ANON_KEY_HERE
```

### Step 3: Restart Both Services

After updating the .env files, restart both backend and frontend:

```powershell
# Kill all processes
Get-Process | Where-Object { $_.ProcessName -match 'node|dart|flutter' } | Stop-Process -Force

# Wait a moment
Start-Sleep -Seconds 3

# Start backend
cd "C:\Users\1000299723\Desktop\Mani Kumar\FamilyTree"
.\start-backend.ps1

# Wait for backend to start
Start-Sleep -Seconds 5

# Start frontend
.\start-frontend.ps1
```

---

## ✅ How to Verify the Fix

### 1. Check Services are Running

```powershell
Get-NetTCPConnection -LocalPort 3000,5500 | Select-Object LocalPort, State
```

Expected output:

```
LocalPort State
--------- -----
     3000 Listen
     5500 Listen
```

### 2. Test Authentication Flow

1. Open browser: http://localhost:5500
2. Click **"Sign Up"**
3. Fill in the form:
   - Full Name: `Test User`
   - Email: `test@example.com`
   - Password: `Test123!`
   - Confirm Password: `Test123!`
4. Click **"Sign Up"** button

**Expected Result:**

- ✅ Success message
- ✅ Redirect to login page
- ✅ No errors in browser console (F12)

5. Now **Login** with the same credentials:
   - Email: `test@example.com`
   - Password: `Test123!`
   - Click **"Sign In"**

**Expected Result:**

- ✅ Redirect to family tree view
- ✅ User is logged in
- ✅ Console shows successful auth logs

### 3. Check Browser Console for Logs

Open browser console (F12) and look for these logs during signup/login:

**Successful Signup:**

```
📝 Attempting sign up
📡 Calling Supabase auth.signUp
✅ Supabase sign up successful
{ user_id: "...", email: "test@example.com", has_session: true }
```

**Successful Login:**

```
🔑 Attempting password sign in
📡 Calling Supabase auth.signInWithPassword
✅ Supabase sign in successful
{ user_id: "...", email: "test@example.com", has_session: true }
```

---

## 🐛 Troubleshooting

### Issue: "Invalid API key"

- **Cause:** Anon key is still incorrect or missing
- **Fix:** Double-check you copied the correct `anon public` key from Supabase Dashboard

### Issue: "Failed to connect to Supabase"

- **Cause:** Network issue or incorrect SUPABASE_URL
- **Fix:** Verify `SUPABASE_URL=https://vojwwcolmnbzogsrmwap.supabase.co` is correct

### Issue: Authentication still fails after fixing key

- **Cause:** Flutter app cached old .env values
- **Fix:** Run these commands:
  ```powershell
  cd app
  C:\src\flutter\bin\flutter.bat clean
  C:\src\flutter\bin\flutter.bat pub get
  cd ..
  .\start-frontend.ps1
  ```

### Issue: Backend errors

- **Cause:** Backend might need the service_role_key update too
- **Fix:** Get the `service_role secret` from Supabase Dashboard → Settings → API
  - Update `backend/.env`: `SUPABASE_SERVICE_ROLE_KEY=eyJ...`
  - Restart backend

---

## 📋 Summary

1. ✅ **Identified Problem:** Placeholder anon key instead of real JWT token
2. 🔑 **Get Real Key:** From Supabase Dashboard → Settings → API → anon public
3. 📝 **Update Files:** Both `backend/.env` and `app/.env`
4. 🔄 **Restart Services:** Kill processes, restart backend & frontend
5. ✅ **Test:** Try signup/login at http://localhost:5500
6. 🎉 **Success:** Authentication should now work!

---

## 🎯 Default Test Credentials

**Important:** There are NO default credentials in this application. You must create your own account:

1. Go to http://localhost:5500
2. Click "Sign Up"
3. Create an account (e.g., `admin@test.com` / `Admin123!`)
4. After signup, to promote to admin, follow [TESTING_GUIDE.md](TESTING_GUIDE.md) Section 3

---

## Need Help?

If authentication still doesn't work after following these steps:

1. Check browser console (F12) for specific error messages
2. Check backend logs for Supabase connection errors
3. Verify your Supabase project is active at https://supabase.com/dashboard
4. Make sure you're using the correct project URL: `vojwwcolmnbzogsrmwap`
