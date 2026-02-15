# Test MyFamilyTree API
Write-Host "Testing MyFamilyTree API..." -ForegroundColor Cyan

# Test 1: Health Check
Write-Host "`n1. Testing /api/health..." -ForegroundColor Yellow
try {
    $health = Invoke-WebRequest -Uri http://localhost:3000/api/health -UseBasicParsing | ConvertFrom-Json
    Write-Host "✅ Health check passed: $($health.status)" -ForegroundColor Green
}
catch {
    Write-Host "❌ Health check failed: $_" -ForegroundColor Red
    Write-Host "   Make sure backend is running: .\start-backend.ps1" -ForegroundColor Gray
    exit 1
}

# Test 2: CORS Headers
Write-Host "`n2. Testing CORS..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri http://localhost:3000/api/health `
        -Headers @{"Origin" = "http://localhost:8080" } `
        -UseBasicParsing
    $corsHeader = $response.Headers["Access-Control-Allow-Origin"]
    if ($corsHeader) {
        Write-Host "✅ CORS configured: $corsHeader" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  CORS header not found" -ForegroundColor Yellow
        Write-Host "   Check backend/.env has APP_URL=http://localhost:8080" -ForegroundColor Gray
    }
}
catch {
    Write-Host "❌ CORS test failed: $_" -ForegroundColor Red
}

# Test 3: Create Person Endpoint
Write-Host "`n3. Testing POST /api/persons..." -ForegroundColor Yellow
try {
    $body = @{
        name   = "Test Person $(Get-Random)"
        phone  = "98765$(Get-Random -Minimum 10000 -Maximum 99999)"
        gender = "male"
    } | ConvertTo-Json

    $response = Invoke-WebRequest -Uri http://localhost:3000/api/persons `
        -Method POST `
        -Headers @{"Content-Type" = "application/json" } `
        -Body $body `
        -UseBasicParsing

    if ($response.StatusCode -eq 201) {
        Write-Host "✅ Create person endpoint working!" -ForegroundColor Green
        $person = $response.Content | ConvertFrom-Json
        Write-Host "   Created person: $($person.person.name)" -ForegroundColor Gray
    }
    else {
        Write-Host "⚠️  Unexpected status: $($response.StatusCode)" -ForegroundColor Yellow
    }
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 400) {
        Write-Host "⚠️  Validation error (400) - Check request format" -ForegroundColor Yellow
    }
    elseif ($statusCode -eq 401) {
        Write-Host "⚠️  Authentication required (401)" -ForegroundColor Yellow
    }
    elseif ($statusCode -eq 409) {
        Write-Host "⚠️  Duplicate entry (409) - Phone already exists" -ForegroundColor Yellow
    }
    else {
        Write-Host "❌ Request failed with status: $statusCode" -ForegroundColor Red
    }
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
}

# Test 4: Get Person (if we created one)
Write-Host "`n4. Testing GET /api/persons/me..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri http://localhost:3000/api/persons/me `
        -UseBasicParsing
    Write-Host "✅ Get person endpoint working!" -ForegroundColor Green
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 404) {
        Write-Host "⚠️  No person found (404) - Create your profile first" -ForegroundColor Yellow
    }
    else {
        Write-Host "❌ Request failed: $statusCode" -ForegroundColor Red
    }
}

# Test 5: Search Endpoint
Write-Host "`n5. Testing GET /api/search..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/search?q=test" `
        -UseBasicParsing
    Write-Host "✅ Search endpoint working!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Search failed: $_" -ForegroundColor Red
}

Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
Write-Host "API Testing Complete!" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  • If all tests passed, your API is working correctly" -ForegroundColor Gray
Write-Host "  • Run backend tests: cd backend; npm test" -ForegroundColor Gray
Write-Host "  • See API_TROUBLESHOOTING.md for debugging help" -ForegroundColor Gray
