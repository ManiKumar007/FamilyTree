# API Troubleshooting Guide

## Issue: `/api/persons` endpoint not available when adding family member

### Quick Diagnostics

Run these commands to diagnose the issue:

#### 1. Check if backend is running

```powershell
Invoke-WebRequest -Uri http://localhost:3000/api/health -UseBasicParsing | ConvertFrom-Json
```

Expected: `{ status: 'ok', timestamp: '...' }`

#### 2. Test the persons endpoint directly

```powershell
# Create a test person (requires auth middleware is configured)
$headers = @{
    "Content-Type" = "application/json"
}

$body = @{
    name = "Test Person"
    phone = "9876543210"
    gender = "male"
} | ConvertTo-Json

Invoke-WebRequest -Uri http://localhost:3000/api/persons `
    -Method POST `
    -Headers $headers `
    -Body $body `
    -UseBasicParsing
```

#### 3. Check CORS configuration

```powershell
# Test CORS headers
$response = Invoke-WebRequest -Uri http://localhost:3000/api/health `
    -Headers @{"Origin" = "http://localhost:8080"} `
    -UseBasicParsing

$response.Headers["Access-Control-Allow-Origin"]
```

Expected: `http://localhost:8080` or `*`

### Common Causes & Solutions

#### Cause 1: Backend Not Running

**Symptoms:** Connection refused, timeout errors

**Solution:**

```powershell
# Start backend
.\start-backend.ps1

# Or manually
cd backend
npm run dev
```

#### Cause 2: CORS Configuration Mismatch

**Symptoms:** CORS errors in browser console

**Check:**

1. `backend/.env` - Ensure `APP_URL=http://localhost:8080`
2. `backend/src/index.ts` - CORS should match:
   ```typescript
   app.use(
     cors({
       origin: env.APP_URL, // Must match frontend URL
       credentials: true,
     }),
   );
   ```

**Fix:** Update `backend/.env`:

```env
APP_URL=http://localhost:8080
```

Then restart backend.

#### Cause 3: Frontend API Base URL Wrong

**Symptoms:** 404 errors when calling API

**Check:** `app/.env` should have:

```env
API_BASE_URL=http://localhost:3000/api
```

**Verify in code:** `app/lib/config/constants.dart`

```dart
static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';
```

#### Cause 4: Authentication Middleware Blocking Requests

**Symptoms:** 401 Unauthorized errors

**Current Configuration:**
The auth middleware is currently in BYPASS mode for testing:

```typescript
// backend/src/middleware/auth.ts
req.userId = "mock-user-123";
req.userEmail = "test@example.com";
next();
return;
```

If you've enabled full auth, ensure:

1. Frontend is sending proper Authorization header
2. Token is valid and not expired
3. Supabase configuration is correct

#### Cause 5: Port Conflicts

**Symptoms:** Backend fails to start

**Check:**

```powershell
# Check what's running on port 3000
Get-NetTCPConnection -LocalPort 3000
```

**Fix:**

```powershell
# Kill process on port 3000
$process = Get-NetTCPConnection -LocalPort 3000 | Select-Object -ExpandProperty OwningProcess -Unique
Stop-Process -Id $process -Force

# Then restart backend
.\start-backend.ps1
```

### Step-by-Step Debugging

1. **Verify Backend Health:**

   ```powershell
   curl http://localhost:3000/api/health
   ```

2. **Check Backend Logs:**
   Look at the terminal running `npm run dev` for error messages

3. **Test API Directly:**
   Use Postman, Insomnia, or PowerShell to test endpoints

4. **Check Browser Console:**
   Open Chrome DevTools → Network tab
   - Look for failed requests
   - Check request headers (Authorization, Content-Type)
   - Check response status codes

5. **Verify Environment Variables:**

   ```powershell
   # Backend
   cat backend\.env

   # Frontend
   cat app\.env
   ```

### Environment Variable Checklist

**Backend (`backend/.env`):**

```env
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
SUPABASE_ANON_KEY=your_anon_key
PORT=3000
APP_URL=http://localhost:8080
INVITE_BASE_URL=http://localhost:8080/invite
```

**Frontend (`app/.env`):**

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
API_BASE_URL=http://localhost:3000/api
```

### Testing the Full Flow

1. **Start Backend:**

   ```powershell
   .\start-backend.ps1
   ```

2. **Start Frontend:**

   ```powershell
   .\start-frontend.ps1
   ```

3. **Test API Call:**
   ```dart
   // In Flutter DevTools console
   final apiService = ref.read(apiServiceProvider);
   final result = await apiService.createPerson({
     'name': 'Test Person',
     'phone': '9876543210',
     'gender': 'male',
   });
   print(result);
   ```

### Network Traffic Inspection

**Chrome DevTools:**

1. Open DevTools (F12)
2. Go to Network tab
3. Filter by "Fetch/XHR"
4. Try adding a family member
5. Click on the failed request
6. Check:
   - Request URL (should be `http://localhost:3000/api/persons`)
   - Request Headers (Authorization, Content-Type)
   - Response (error message)

### API Response Codes Reference

| Code | Meaning      | Likely Cause                        |
| ---- | ------------ | ----------------------------------- |
| 200  | Success      | ✅ Working                          |
| 201  | Created      | ✅ Resource created                 |
| 400  | Bad Request  | Invalid data format                 |
| 401  | Unauthorized | Missing/invalid auth token          |
| 403  | Forbidden    | Insufficient permissions            |
| 404  | Not Found    | Wrong URL or endpoint doesn't exist |
| 409  | Conflict     | Duplicate data (e.g., phone exists) |
| 500  | Server Error | Backend error - check logs          |

### Quick Fix Script

Save this as `test-api.ps1`:

```powershell
# Test MyFamilyTree API
Write-Host "Testing MyFamilyTree API..." -ForegroundColor Cyan

# Test 1: Health Check
Write-Host "`n1. Testing /api/health..." -ForegroundColor Yellow
try {
    $health = Invoke-WebRequest -Uri http://localhost:3000/api/health -UseBasicParsing | ConvertFrom-Json
    Write-Host "✅ Health check passed: $($health.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ Health check failed: $_" -ForegroundColor Red
    exit 1
}

# Test 2: CORS Headers
Write-Host "`n2. Testing CORS..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri http://localhost:3000/api/health `
        -Headers @{"Origin" = "http://localhost:8080"} `
        -UseBasicParsing
    $corsHeader = $response.Headers["Access-Control-Allow-Origin"]
    if ($corsHeader) {
        Write-Host "✅ CORS configured: $corsHeader" -ForegroundColor Green
    } else {
        Write-Host "⚠️  CORS header not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ CORS test failed: $_" -ForegroundColor Red
}

# Test 3: Create Person Endpoint
Write-Host "`n3. Testing POST /api/persons..." -ForegroundColor Yellow
try {
    $body = @{
        name = "Test Person"
        phone = "9876543210"
        gender = "male"
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri http://localhost:3000/api/persons `
        -Method POST `
        -Headers @{"Content-Type" = "application/json"} `
        -Body $body `
        -UseBasicParsing

    Write-Host "✅ Create person endpoint working: Status $($response.StatusCode)" -ForegroundColor Green
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "⚠️  Create person returned: $statusCode" -ForegroundColor Yellow
    Write-Host "   This might be expected if validation/auth is configured" -ForegroundColor Gray
}

Write-Host "`nAPI Testing Complete!" -ForegroundColor Cyan
```

Run with:

```powershell
.\test-api.ps1
```

### Still Having Issues?

1. **Restart everything:**

   ```powershell
   .\stop-all.ps1
   .\start-all.ps1
   ```

2. **Clear caches:**

   ```powershell
   # Backend
   cd backend
   Remove-Item -Recurse -Force node_modules
   npm install

   # Frontend
   cd app
   flutter clean
   flutter pub get
   ```

3. **Check firewall/antivirus:** Ensure localhost connections are allowed

4. **Try different port:** Edit `backend/.env` to use a different PORT

5. **Enable verbose logging:** Add to `backend/src/index.ts`:
   ```typescript
   app.use((req, res, next) => {
     console.log(`${req.method} ${req.path}`);
     next();
   });
   ```

### Getting Help

If the issue persists:

1. Check backend terminal for error messages
2. Check frontend console for errors
3. Review `TESTING_BEST_PRACTICES.md`
4. Check API tests: `cd backend && npm test`
