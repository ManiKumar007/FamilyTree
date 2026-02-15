# 🚀 Quick Reference Guide

## Start Application

```powershell
# Start everything
.\start-all.ps1

# Or start individually
.\start-backend.ps1    # Backend API on port 3000
.\start-frontend.ps1   # Flutter app on port 8080
```

## Test API

```powershell
# Quick API health check
.\test-api.ps1

# Manual health check
Invoke-WebRequest http://localhost:3000/api/health -UseBasicParsing

# Test specific endpoint
$body = @{name="Test"; phone="9876543210"; gender="male"} | ConvertTo-Json
Invoke-WebRequest -Uri http://localhost:3000/api/persons `
    -Method POST -Headers @{"Content-Type"="application/json"} `
    -Body $body -UseBasicParsing
```

## Run Tests

```powershell
# Backend unit tests
cd backend
npm test                      # Run all tests
npm run test:watch            # Watch mode (auto-rerun)
npm run test:coverage         # With coverage report

# Frontend tests
cd app
flutter test                  # Run all widget/unit tests
flutter test --coverage       # With coverage
```

## Common Issues & Fixes

### "API endpoint not available"

```powershell
# 1. Check backend is running
Invoke-WebRequest http://localhost:3000/api/health -UseBasicParsing

# 2. Check environment variables
cat backend\.env
cat app\.env

# 3. Restart everything
.\stop-all.ps1
.\start-all.ps1
```

### "CORS error"

Check `backend/.env`:

```env
APP_URL=http://localhost:8080
```

Restart backend after changes.

### "500 Internal Server Error"

```powershell
# Check backend logs in terminal
# Verify Supabase credentials in backend/.env
# Ensure database is accessible
```

### "Port already in use"

```powershell
# Find process on port 3000
Get-NetTCPConnection -LocalPort 3000

# Kill process (replace PID)
Stop-Process -Id <PID> -Force
```

## Debug Mode

**Backend - Add verbose logging:**

Edit `backend/src/index.ts` (before routes):

```typescript
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.path}`);
  next();
});
```

**Frontend - Check DevTools:**

1. Press F12 in browser
2. Go to Network tab
3. Filter by "XHR/Fetch"
4. Try the operation
5. Check failed requests

## Environment Variables

**Backend (`backend/.env`):**

```env
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=xxx
SUPABASE_ANON_KEY=xxx
PORT=3000
APP_URL=http://localhost:8080
INVITE_BASE_URL=http://localhost:8080/invite
```

**Frontend (`app/.env`):**

```env
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=xxx
API_BASE_URL=http://localhost:3000/api
```

## Useful Commands

```powershell
# Backend
cd backend
npm run dev          # Start dev server
npm test             # Run tests
npm run lint         # Check code quality
npm run build        # Build for production

# Frontend
cd app
flutter run          # Run app
flutter test         # Run tests
flutter analyze      # Static analysis
flutter clean        # Clean build cache
flutter pub get      # Install dependencies

# Database
# (Use Supabase Dashboard for now)
```

## File Locations

| File/Folder                         | Purpose                 |
| ----------------------------------- | ----------------------- |
| `backend/src/routes/`               | API endpoints           |
| `backend/src/__tests__/`            | Backend tests           |
| `app/lib/features/`                 | Flutter screens & logic |
| `app/lib/services/api_service.dart` | API client              |
| `backend/.env`                      | Backend config          |
| `app/.env`                          | Frontend config         |
| `test-api.ps1`                      | API testing script      |

## Response Codes

| Code | Meaning      | Action              |
| ---- | ------------ | ------------------- |
| 200  | OK           | ✅ Success          |
| 201  | Created      | ✅ Resource created |
| 400  | Bad Request  | Check input data    |
| 401  | Unauthorized | Check auth token    |
| 404  | Not Found    | Check URL/endpoint  |
| 409  | Conflict     | Duplicate data      |
| 500  | Server Error | Check backend logs  |

## Getting Help

1. **Check documentation:**
   - [TESTING_BEST_PRACTICES.md](TESTING_BEST_PRACTICES.md)
   - [API_TROUBLESHOOTING.md](API_TROUBLESHOOTING.md)
   - [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)

2. **Run diagnostics:**

   ```powershell
   .\test-api.ps1
   ```

3. **Check logs:**
   - Backend: Terminal running `npm run dev`
   - Frontend: Browser DevTools Console

4. **Reset everything:**

   ```powershell
   .\stop-all.ps1

   # Backend
   cd backend
   Remove-Item -Recurse node_modules
   npm install

   # Frontend
   cd app
   flutter clean
   flutter pub get

   # Restart
   cd ..
   .\start-all.ps1
   ```

---

**Quick Links:**

- 📝 [Full Best Practices](TESTING_BEST_PRACTICES.md)
- 🔧 [Troubleshooting Guide](API_TROUBLESHOOTING.md)
- 📋 [Implementation Summary](IMPLEMENTATION_SUMMARY.md)
- 🚀 [Quick Start](QUICK-START.md)
