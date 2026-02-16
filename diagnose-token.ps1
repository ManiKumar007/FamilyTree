#!/usr/bin/env pwsh
# Token Diagnostics Script
# This script helps diagnose token validation issues

Write-Host "🔍 Token Diagnostics Script" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Read .env file
$envFile = ".\.env"
if (-not (Test-Path $envFile)) {
    Write-Host "❌ .env file not found!" -ForegroundColor Red
    exit 1
}

Write-Host "📄 Reading .env configuration..." -ForegroundColor Yellow
$envVars = @{}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        $envVars[$key] = $value
    }
}

# Check required variables
$requiredVars = @('SUPABASE_URL', 'SUPABASE_ANON_KEY', 'SUPABASE_SERVICE_ROLE_KEY')
$missing = @()
foreach ($var in $requiredVars) {
    if (-not $envVars.ContainsKey($var)) {
        $missing += $var
    }
}

if ($missing.Count -gt 0) {
    Write-Host "❌ Missing required environment variables:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "✅ All required environment variables present`n" -ForegroundColor Green

# Display configuration (redacted)
Write-Host "📋 Configuration:" -ForegroundColor Cyan
Write-Host "   SUPABASE_URL: $($envVars['SUPABASE_URL'])" -ForegroundColor White
Write-Host "   SUPABASE_ANON_KEY: $($envVars['SUPABASE_ANON_KEY'].Substring(0, 20))..." -ForegroundColor White
Write-Host "   SUPABASE_SERVICE_ROLE_KEY: $($envVars['SUPABASE_SERVICE_ROLE_KEY'].Substring(0, 20))...`n" -ForegroundColor White

# Check if backend is running
Write-Host "🔍 Checking if backend is running..." -ForegroundColor Yellow
try {
    $healthCheck = Invoke-RestMethod -Uri "http://localhost:3000/health" -Method Get -ErrorAction Stop
    Write-Host "✅ Backend is running" -ForegroundColor Green
    Write-Host "   Status: $($healthCheck.status)" -ForegroundColor White
    Write-Host "   Database: $($healthCheck.database.status)`n" -ForegroundColor White
}
catch {
    Write-Host "❌ Backend is not running or not accessible" -ForegroundColor Red
    Write-Host "   Please start the backend with .\start-backend.ps1`n" -ForegroundColor Yellow
    exit 1
}

# Instructions for user
Write-Host "📝 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Log into the Flutter app" -ForegroundColor White
Write-Host "   2. Try to create/update your profile" -ForegroundColor White
Write-Host "   3. Check the backend console for detailed token validation logs" -ForegroundColor White
Write-Host "   4. Check the Flutter console for token refresh logs" -ForegroundColor White
Write-Host "`n🔍 Look for these log messages:" -ForegroundColor Cyan
Write-Host "   Backend:" -ForegroundColor Yellow
Write-Host "      - 🔐 Validating token..." -ForegroundColor Gray
Write-Host "      - Token length: ..." -ForegroundColor Gray
Write-Host "      - Supabase URL: ..." -ForegroundColor Gray
Write-Host "      - ✅ Token validated for user: ..." -ForegroundColor Gray
Write-Host "      - ❌ Token validation error: ..." -ForegroundColor Gray
Write-Host "`n   Frontend:" -ForegroundColor Yellow
Write-Host "      - 🔄 Refreshing session..." -ForegroundColor Gray
Write-Host "      - Token BEFORE refresh: ..." -ForegroundColor Gray
Write-Host "      - Token AFTER refresh: ..." -ForegroundColor Gray
Write-Host "      - Token changed: ..." -ForegroundColor Gray

Write-Host "`n💡 Common Issues:" -ForegroundColor Cyan
Write-Host "   1. Email not confirmed - Check Supabase dashboard" -ForegroundColor White
Write-Host "   2. Token expired - Session refresh should fix this" -ForegroundColor White
Write-Host "   3. Mismatched Supabase projects between frontend/backend" -ForegroundColor White
Write-Host "   4. Wrong SERVICE_ROLE_KEY in backend .env" -ForegroundColor White

Write-Host "`n✅ Diagnostics complete!" -ForegroundColor Green
