# E2E Testing TODO - Production Tests

## Current Status (Feb 28, 2026)

### ✅ Completed
- [x] Made Playwright tests environment-configurable (`TEST_ENV=production`)
- [x] Installed `cross-env` for Windows compatibility
- [x] Created Flutter Web test helpers (`flutter-helpers.ts`)
- [x] Created Flutter semantics exploration tests (`flutter-semantics-debug.spec.ts`)
- [x] Rewrote `user-flows-simple.spec.ts` for Flutter Web canvas rendering
- [x] **4 of 7 tests passing** on production:
  - ✅ App loads and Flutter initializes
  - ✅ Hash route navigation works
  - ✅ Login page correct form structure
  - ✅ Signup page correct form structure
- [x] Debug-elements tests (3/3) passing on production
- [x] Confirmed login form interaction works (email/password typing, button click triggers API)

### 🚫 Blocked (Waiting on Supabase)
- [ ] **Login test fails** - Supabase is down (technical issues)
  - Email: `chinni070707@gmail.com` ✅ typed correctly
  - Password: `Ssd@88788` ✅ typed correctly
  - API call triggered: `POST https://vojwwcolmnbzogsrmwap.supabase.co/auth/v1/token?grant_type=password` ✅
  - **Problem**: Request times out, no response (Supabase down)
- [ ] Session persistence test (depends on login)
- [ ] Authenticated routes navigation test (depends on login)

## Next Steps (When Supabase is Back Up)

### 1. Verify Supabase is Live ⏳
```powershell
# Test Supabase directly
$headers = @{
    "apikey" = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvand3Y29sbW5iem9nc3Jtd2FwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExNDgyNDYsImV4cCI6MjA4NjcyNDI0Nn0.xVU1_igSVhUm4iFGtV7bPLkHGZG-VtRBBfBugPEa-7g"
    "Content-Type" = "application/json"
}
$body = '{"email":"chinni070707@gmail.com","password":"Ssd@88788"}'
Invoke-RestMethod -Uri "https://vojwwcolmnbzogsrmwap.supabase.co/auth/v1/token?grant_type=password" -Method POST -Headers $headers -Body $body
```

If this succeeds, Supabase is back up. Proceed to step 2.

### 2. Run Login Test 🧪
```powershell
cd e2e-tests
$env:TEST_ENV="production"
npx playwright test tests/user-flows-simple.spec.ts --project chromium -g "Login with existing"
```

**Expected**: Test should now **pass** (navigate away from `/login` to `/` or `/tree`)

### 3. Run Full Test Suite 🚀
```powershell
cd e2e-tests
npm run test:prod
```

**Expected**: All 7 tests in `user-flows-simple.spec.ts` should pass

### 4. Commit and Push Changes 📦
```bash
git add e2e-tests/
git commit -m "feat: make e2e tests configurable for production + Flutter Web compatibility

- Add TEST_ENV=production support to playwright.config.ts
- Create flutter-helpers.ts for Flutter Web canvas interaction
- Rewrite user-flows-simple.spec.ts for Flutter semantics tree
- Add flutter-semantics-debug.spec.ts for exploration
- Install cross-env for Windows env var compatibility

Tests now work against production Vercel deployments:
- Frontend: https://familytree-web.vercel.app
- Backend: https://backend-five-blue-16.vercel.app

Current: 4/7 tests passing (login blocked by Supabase downtime)"

git push
```

## Technical Notes

### Flutter Web Testing Approach
- Flutter Web renders to `<canvas>` via CanvasKit, NOT standard HTML DOM
- Standard selectors (`input[type="email"]`, `button`) don't work
- **Solution**: Enable accessibility → use semantic tree for element discovery → click at coordinates on glass-pane

### Key Files Modified
- `e2e-tests/playwright.config.ts` - Environment config
- `e2e-tests/package.json` - Added `test:prod` scripts, cross-env
- `e2e-tests/tests/flutter-helpers.ts` - New helper module
- `e2e-tests/tests/flutter-semantics-debug.spec.ts` - New diagnostic tests
- `e2e-tests/tests/user-flows-simple.spec.ts` - Completely rewritten

### Production URLs
- Frontend: `https://familytree-web.vercel.app`
- Backend: `https://backend-five-blue-16.vercel.app`
- Supabase: `https://vojwwcolmnbzogsrmwap.supabase.co`

### Test Credentials
- Email: `chinni070707@gmail.com`
- Password: `Ssd@88788`

### Network Evidence (from last test run)
```
REQ: POST https://vojwwcolmnbzogsrmwap.supabase.co/auth/v1/token?grant_type=password
(no response - timeout)
```

This proves the Flutter app is correctly:
1. Capturing typed email/password values
2. Detecting Sign In button clicks
3. Calling the Supabase auth API

The only failure is Supabase not responding.

## Optional Future Improvements
- [ ] Add API-level auth tests (bypass UI, test endpoints directly)
- [ ] Add visual regression tests (screenshots comparison)
- [ ] Add performance tests (page load times, interaction latency)
- [ ] Add mobile viewport tests (responsive design verification)
- [ ] Add network throttling tests (slow connection simulation)

---

**Last Updated**: February 28, 2026  
**Status**: Blocked waiting for Supabase to resolve technical issues  
**Next Action**: Rerun tests when Supabase is back online
