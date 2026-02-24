# Comprehensive Supabase Debugging Guide
# Use this alongside checking Supabase Dashboard logs

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  SUPABASE CONNECTION DIAGNOSTIC" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$supabaseUrl = "https://vojwwcolmnbzogsrmwap.supabase.co"
$anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvand3Y29sbW5iem9nc3Jtd2FwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExNDgyNDYsImV4cCI6MjA4NjcyNDI0Nn0.xVU1_igSVhUm4iFGtV7bPLkHGZG-VtRBBfBugPEa-7g"

Write-Host "Testing connection to Supabase project..." -ForegroundColor Yellow
Write-Host "Project URL: $supabaseUrl`n" -ForegroundColor Gray

# Test 1: Auth Health Endpoint
Write-Host "[1/4] Testing Auth Health Endpoint..." -ForegroundColor Cyan
try {
    $health = Invoke-WebRequest -Uri "$supabaseUrl/auth/v1/health" -TimeoutSec 10 -UseBasicParsing
    Write-Host "  ✓ Auth API is reachable" -ForegroundColor Green
    Write-Host "  Response: $($health.Content)" -ForegroundColor Gray
    $authOk = $true
}
catch {
    Write-Host "  ✗ Auth API FAILED" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    $authOk = $false
}

# Test 2: REST API Endpoint
Write-Host "`n[2/4] Testing REST API Endpoint..." -ForegroundColor Cyan
try {
    $headers = @{
        "apikey" = $anonKey
        "Authorization" = "Bearer $anonKey"
    }
    $rest = Invoke-WebRequest -Uri "$supabaseUrl/rest/v1/" -Headers $headers -TimeoutSec 10 -UseBasicParsing
    Write-Host "  ✓ REST API is reachable" -ForegroundColor Green
    Write-Host "  Status: $($rest.StatusCode)" -ForegroundColor Gray
    $restOk = $true
}
catch {
    Write-Host "  ✗ REST API FAILED" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    $restOk = $false
}

# Test 3: Actual Auth Attempt (This will show in Supabase logs)
Write-Host "`n[3/4] Testing Actual Login Request..." -ForegroundColor Cyan
Write-Host "  (This should appear in Supabase Auth logs if it reaches server)" -ForegroundColor Gray
try {
    $body = @{
        email = "test@example.com"
        password = "testpassword123"
    } | ConvertTo-Json
    
    $headers = @{
        "apikey" = $anonKey
        "Content-Type" = "application/json"
    }
    
    $login = Invoke-WebRequest -Uri "$supabaseUrl/auth/v1/token?grant_type=password" `
        -Method POST `
        -Headers $headers `
        -Body $body `
        -TimeoutSec 10 `
        -UseBasicParsing `
        -ErrorAction Stop
        
    Write-Host "  ✓ Login endpoint reachable (will see error, that's OK)" -ForegroundColor Green
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 400 -or $statusCode -eq 401) {
        Write-Host "  ✓ Login endpoint IS REACHABLE (got HTTP $statusCode - expected)" -ForegroundColor Green
        Write-Host "  → This request SHOULD appear in Supabase Auth logs" -ForegroundColor Yellow
        $loginOk = $true
    }
    elseif ($_.Exception.Message -match "timeout|connection") {
        Write-Host "  ✗ Login endpoint TIMEOUT" -ForegroundColor Red
        Write-Host "  → Request NEVER reached Supabase (ISP blocking)" -ForegroundColor Red
        $loginOk = $false
    }
    else {
        Write-Host "  ? Unexpected error: $($_.Exception.Message)" -ForegroundColor Yellow
        $loginOk = $false
    }
}

# Test 4: Network Path
Write-Host "`n[4/4] Network Path Analysis..." -ForegroundColor Cyan
$dns = Resolve-DnsName -Name "vojwwcolmnbzogsrmwap.supabase.co"
Write-Host "  DNS resolved to: $($dns.IPAddress -join ', ')" -ForegroundColor Gray

# Summary and Next Steps
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  DIAGNOSTIC RESULTS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($authOk -and $restOk -and $loginOk) {
    Write-Host "✓ ALL TESTS PASSED" -ForegroundColor Green
    Write-Host "`nSupabase is accessible from your network!" -ForegroundColor Green
    Write-Host "If your app still fails, check application-level issues.`n" -ForegroundColor Yellow
}
else {
    Write-Host "✗ CONNECTION BLOCKED" -ForegroundColor Red
    Write-Host "`nYour ISP (Jio) is blocking Supabase." -ForegroundColor Yellow
    Write-Host "`nNOW CHECK SUPABASE LOGS:" -ForegroundColor Cyan
    Write-Host "  1. Go to: https://supabase.com/dashboard/project/vojwwcolmnbzogsrmwap/logs" -ForegroundColor White
    Write-Host "  2. Click 'Auth Logs'" -ForegroundColor White
    Write-Host "  3. Look for timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor White
    Write-Host "`nExpected Result:" -ForegroundColor Cyan
    Write-Host "  • If NO logs → Requests blocked by ISP (use VPN)" -ForegroundColor Red
    Write-Host "  • If logs present → Server receiving requests (app issue)`n" -ForegroundColor Yellow
}

Write-Host "========================================" -ForegroundColor Gray
Write-Host "Next: Check Supabase Dashboard Logs" -ForegroundColor Yellow
Write-Host "URL: https://supabase.com/dashboard/project/vojwwcolmnbzogsrmwap/logs" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Gray
