# Simple Supabase Connection Test
# This will help determine if logs appear in Supabase Dashboard

$url = "https://vojwwcolmnbzogsrmwap.supabase.co"
$key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvand3Y29sbW5iem9nc3Jtd2FwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExNDgyNDYsImV4cCI6MjA4NjcyNDI0Nn0.xVU1_igSVhUm4iFGtV7bPLkHGZG-VtRBBfBugPEa-7g"

Write-Host "`nSUPABASE CONNECTION TEST" -ForegroundColor Cyan
Write-Host "========================`n" -ForegroundColor Cyan

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "Test Time: $timestamp" -ForegroundColor Gray
Write-Host "Look for this timestamp in Supabase logs`n" -ForegroundColor Yellow

# Test 1: Health Check
Write-Host "[1/3] Testing health endpoint..." -ForegroundColor Cyan
try {
    $health = Invoke-WebRequest -Uri "$url/auth/v1/health" -TimeoutSec 10 -UseBasicParsing
    Write-Host "  SUCCESS - Status: $($health.StatusCode)`n" -ForegroundColor Green
}
catch {
    Write-Host "  FAILED - $($_.Exception.Message)`n" -ForegroundColor Red
}

# Test 2: REST API
Write-Host "[2/3] Testing REST API..." -ForegroundColor Cyan
try {
    $headers = @{ "apikey" = $key }
    $rest = Invoke-WebRequest -Uri "$url/rest/v1/" -Headers $headers -TimeoutSec 10 -UseBasicParsing
    Write-Host "  SUCCESS - Status: $($rest.StatusCode)`n" -ForegroundColor Green
}
catch {
    Write-Host "  FAILED - $($_.Exception.Message)`n" -ForegroundColor Red
}

# Test 3: Actual Auth Request (This will appear in logs)
Write-Host "[3/3] Attempting login (will fail, but should log)..." -ForegroundColor Cyan
Write-Host "  This request should appear in Auth Logs if server is reachable" -ForegroundColor Gray

try {
    $body = @{
        email = "diagnostic.test@example.com"
        password = "test123"
    } | ConvertTo-Json

    $headers = @{
        "apikey" = $key
        "Content-Type" = "application/json"
    }

    $login = Invoke-WebRequest -Uri "$url/auth/v1/token?grant_type=password" `
        -Method POST `
        -Headers $headers `
        -Body $body `
        -TimeoutSec 10 `
        -UseBasicParsing
}
catch {
    $msg = $_.Exception.Message
    if ($msg -match "400|401") {
        Write-Host "  SUCCESS - Server responded (expected login error)" -ForegroundColor Green
        Write-Host "  This request SHOULD appear in Supabase Auth logs!`n" -ForegroundColor Yellow
    }
    elseif ($msg -match "timeout") {
        Write-Host "  TIMEOUT - Request never reached server (ISP blocking)`n" -ForegroundColor Red
    }
    else {
        Write-Host "  FAILED - $msg`n" -ForegroundColor Red
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "1. Open Supabase Dashboard:" -ForegroundColor White
Write-Host "   https://supabase.com/dashboard/project/vojwwcolmnbzogsrmwap/logs`n" -ForegroundColor Gray

Write-Host "2. Click 'Auth Logs' tab`n" -ForegroundColor White

Write-Host "3. Look for timestamp: $timestamp" -ForegroundColor White
Write-Host "   Email: diagnostic.test@example.com`n" -ForegroundColor Gray

Write-Host "INTERPRETATION:" -ForegroundColor Cyan
Write-Host "  - If log entry EXISTS => Server received request (not ISP blocking)" -ForegroundColor Green
Write-Host "  - If NO log entry => ISP blocking requests (use VPN)`n" -ForegroundColor Red
