#!/usr/bin/env pwsh
# Backend Configuration Checker
Write-Host "Checking Backend Configuration..." -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check if backend .env exists
$backendEnv = ".\backend\.env"
if (-not (Test-Path $backendEnv)) {
    Write-Host "❌ Backend .env file not found!" -ForegroundColor Red
    Write-Host "   Create: backend\.env" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Backend .env exists" -ForegroundColor Green
Write-Host ""

# Read backend .env
Write-Host "📄 Reading backend configuration..." -ForegroundColor Yellow
$backendVars = @{}
Get-Content $backendEnv | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        $backendVars[$key] = $value
    }
}

# Read frontend .env
$frontendEnv = ".\app\.env"
$frontendVars = @{}
if (Test-Path $frontendEnv) {
    Get-Content $frontendEnv | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $frontendVars[$key] = $value
        }
    }
}

# Check required backend variables
$requiredBackendVars = @('SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY', 'SUPABASE_ANON_KEY')
$missing = @()
$empty = @()

foreach ($var in $requiredBackendVars) {
    if (-not $backendVars.ContainsKey($var)) {
        $missing += $var
    }
    elseif ($backendVars[$var] -eq '' -or $backendVars[$var] -eq '""' -or $backendVars[$var] -eq "''") {
        $empty += $var
    }
}

if ($missing.Count -gt 0) {
    Write-Host "❌ Missing required variables in backend\.env:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
    exit 1
}

if ($empty.Count -gt 0) {
    Write-Host "❌ Empty variables in backend\.env:" -ForegroundColor Red
    $empty | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
    Write-Host "💡 These variables must have values!" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "✅ All required backend variables present and not empty" -ForegroundColor Green
Write-Host ""

# Compare backend and frontend Supabase URLs
if ($frontendVars.ContainsKey('SUPABASE_URL')) {
    if ($backendVars['SUPABASE_URL'] -ne $frontendVars['SUPABASE_URL']) {
        Write-Host "⚠️  WARNING: Supabase URLs don't match!" -ForegroundColor Yellow
        Write-Host "   Backend:  $($backendVars['SUPABASE_URL'])" -ForegroundColor Yellow
        Write-Host "   Frontend: $($frontendVars['SUPABASE_URL'])" -ForegroundColor Yellow
        Write-Host "   This will cause token validation to fail!" -ForegroundColor Red
        Write-Host ""
    }
    else {
        Write-Host "✅ Supabase URLs match between frontend and backend" -ForegroundColor Green
        Write-Host ""
    }
}

# Display configuration (redacted)
Write-Host "📋 Backend Configuration:" -ForegroundColor Cyan
Write-Host "   SUPABASE_URL: $($backendVars['SUPABASE_URL'])" -ForegroundColor White

if ($backendVars['SUPABASE_URL'] -notmatch '^https://[a-z0-9-]+\.supabase\.co$') {
    Write-Host "   ⚠️  URL format looks incorrect!" -ForegroundColor Yellow
    Write-Host "   Expected: https://your-project.supabase.co" -ForegroundColor Gray
}

$anonKeyLength = $backendVars['SUPABASE_ANON_KEY'].Length
$serviceKeyLength = $backendVars['SUPABASE_SERVICE_ROLE_KEY'].Length

Write-Host "   SUPABASE_ANON_KEY: $($backendVars['SUPABASE_ANON_KEY'].Substring(0, [Math]::Min(20, $anonKeyLength)))... (length: $anonKeyLength)" -ForegroundColor White
Write-Host "   SUPABASE_SERVICE_ROLE_KEY: $($backendVars['SUPABASE_SERVICE_ROLE_KEY'].Substring(0, [Math]::Min(20, $serviceKeyLength)))... (length: $serviceKeyLength)" -ForegroundColor White
Write-Host ""

if ($anonKeyLength -lt 100) {
    Write-Host "   ⚠️  ANON_KEY seems too short!" -ForegroundColor Yellow
}
if ($serviceKeyLength -lt 100) {
    Write-Host "   ⚠️  SERVICE_ROLE_KEY seems too short!" -ForegroundColor Yellow
}

# Test Supabase connection
Write-Host "🔍 Testing Supabase connection..." -ForegroundColor Yellow
try {
    $healthUrl = $backendVars['SUPABASE_URL'] + "/rest/v1/"
    $headers = @{
        "apikey" = $backendVars['SUPABASE_ANON_KEY']
    }
    
    $response = Invoke-RestMethod -Uri $healthUrl -Headers $headers -Method Get -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Supabase connection successful!" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Host "❌ Failed to connect to Supabase!" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Possible issues:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   1. SUPABASE_URL is incorrect" -ForegroundColor Gray
    Write-Host "   2. SUPABASE_ANON_KEY is incorrect" -ForegroundColor Gray
    Write-Host "   3. Network/firewall blocking connection" -ForegroundColor Gray
    Write-Host "   4. Supabase project is paused or deleted" -ForegroundColor Gray
    Write-Host ""
}

# Check if backend is running
Write-Host "🔍 Checking if backend is running..." -ForegroundColor Yellow
try {
    $healthCheck = Invoke-RestMethod -Uri "http://localhost:3000/health" -Method Get -TimeoutSec 3 -ErrorAction Stop
    Write-Host "✅ Backend is running" -ForegroundColor Green
    Write-Host "   Status: $($healthCheck.status)" -ForegroundColor White
    Write-Host "   Database: $($healthCheck.database.status)" -ForegroundColor White
    Write-Host ""
}
catch {
    Write-Host "❌ Backend is not running!" -ForegroundColor Red
    Write-Host "   Start it with: .\\start-backend.ps1" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""  
Write-Host "Configuration check complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps if you see Invalid or expired token errors:" -ForegroundColor Cyan
Write-Host "   1. Make sure SUPABASE_URL matches in both backend\.env and app\.env" -ForegroundColor White
Write-Host "   2. Verify SERVICE_ROLE_KEY is correct (from Supabase dashboard Settings > API)" -ForegroundColor White
Write-Host "   3. Check backend console for detailed error messages" -ForegroundColor White
Write-Host "   4. Restart backend after fixing .env: stop-all.ps1 then start-all.ps1" -ForegroundColor White
