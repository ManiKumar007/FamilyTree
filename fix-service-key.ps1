#!/usr/bin/env pwsh
# Automated Supabase Service Role Key Updater
# This script will open your Supabase dashboard and guide you through updating the key

$PROJECT_ID = "vojwwcolmnbzogsrmwap"
$PROJECT_URL = "https://vojwwcolmnbzogsrmwap.supabase.co"
$CORRECT_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvand3Y29sbW5iem9nc3Jtd2FwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExNDgyNDYsImV4cCI6MjA4NjcyNDI0Nn0.xVU1_igSVhUm4iFGtV7bPLkHGZG-VtRBBfBugPEa-7g"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Supabase Service Key Fixer" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Verify backend .env exists
if (-not (Test-Path ".\backend\.env")) {
    Write-Host "ERROR: backend\.env not found!" -ForegroundColor Red
    exit 1
}

Write-Host "Step 1: Verified configuration files exist" -ForegroundColor Green
Write-Host ""

# Open Supabase dashboard to API settings
Write-Host "Step 2: Opening Supabase Dashboard..." -ForegroundColor Yellow
Write-Host "  Project: $PROJECT_ID" -ForegroundColor White
Write-Host "  Opening: Settings > API" -ForegroundColor White
Write-Host ""

$dashboardUrl = "https://supabase.com/dashboard/project/$PROJECT_ID/settings/api"
Start-Process $dashboardUrl

Write-Host "Browser opened!" -ForegroundColor Green
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "IN THE BROWSER THAT JUST OPENED:" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Find the 'service_role' key section" -ForegroundColor White
Write-Host "   (It's labeled as 'secret' with a lock icon)" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Click the 'Reveal' button" -ForegroundColor White
Write-Host ""
Write-Host "3. Click the 'Copy' button (or select all and Ctrl+C)" -ForegroundColor White
Write-Host ""
Write-Host "4. Come back to this terminal" -ForegroundColor White
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Wait for user to copy the key
Write-Host "Once you've copied the service_role key, press ENTER to continue..." -ForegroundColor Yellow
$null = Read-Host

Write-Host ""
Write-Host "Step 3: Paste the SERVICE_ROLE_KEY below:" -ForegroundColor Yellow
Write-Host "(Right-click or Ctrl+V to paste)" -ForegroundColor Gray
Write-Host ""
$newServiceKey = Read-Host "SERVICE_ROLE_KEY"

# Validate input
if ([string]::IsNullOrWhiteSpace($newServiceKey)) {
    Write-Host ""
    Write-Host "ERROR: No key provided. Cancelled." -ForegroundColor Red
    exit 1
}

# Validate key format
$isValid = $true
if (-not $newServiceKey.StartsWith("eyJ")) {
    Write-Host ""
    Write-Host "WARNING: Key doesn't start with 'eyJ'" -ForegroundColor Yellow
    Write-Host "  This doesn't look like a valid JWT key." -ForegroundColor Yellow
    $isValid = $false
}

if ($newServiceKey.Length -lt 100) {
    Write-Host ""
    Write-Host "WARNING: Key seems too short (got $($newServiceKey.Length) chars, expected 200+)" -ForegroundColor Yellow
    $isValid = $false
}

if (-not $isValid) {
    Write-Host ""
    $confirm = Read-Host "Continue anyway? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "Step 4: Creating backup..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item ".\backend\.env" ".\backend\.env.backup_$timestamp"
Write-Host "  Backed up to: backend\.env.backup_$timestamp" -ForegroundColor Green
Write-Host ""

Write-Host "Step 5: Updating backend\.env..." -ForegroundColor Yellow
$envContent = Get-Content ".\backend\.env"
$updatedContent = $envContent | ForEach-Object {
    if ($_ -match "^SUPABASE_SERVICE_ROLE_KEY=") {
        "SUPABASE_SERVICE_ROLE_KEY=$newServiceKey"
    }
    elseif ($_ -match "^SUPABASE_ANON_KEY=") {
        # Also update anon key to ensure it's correct
        "SUPABASE_ANON_KEY=$CORRECT_ANON_KEY"
    }
    elseif ($_ -match "^SUPABASE_URL=") {
        # Ensure URL is correct
        "SUPABASE_URL=$PROJECT_URL"
    }
    else {
        $_
    }
}
$updatedContent | Set-Content ".\backend\.env"
Write-Host "  Updated backend\.env successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "Step 6: Verifying configuration..." -ForegroundColor Yellow
Write-Host "  Project URL: $PROJECT_URL" -ForegroundColor White
Write-Host "  Anon Key: $($CORRECT_ANON_KEY.Substring(0, 30))..." -ForegroundColor White
Write-Host "  Service Key: $($newServiceKey.Substring(0, 30))..." -ForegroundColor White
Write-Host ""

Write-Host "================================" -ForegroundColor Green
Write-Host "Configuration Updated!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

Write-Host "Step 7: Restarting services..." -ForegroundColor Yellow
Write-Host ""

# Stop services
Write-Host "Stopping services..." -ForegroundColor Cyan
& ".\stop-all.ps1"
Write-Host ""

# Wait a moment
Start-Sleep -Seconds 2

# Start services
Write-Host "Starting services..." -ForegroundColor Cyan
& ".\start-all.ps1"
Write-Host ""

Write-Host "================================" -ForegroundColor Green
Write-Host "All Done!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

Write-Host "What to do next:" -ForegroundColor Cyan
Write-Host "1. Wait for services to start (watch the terminal windows)" -ForegroundColor White
Write-Host "2. Go to your Flutter app (in browser)" -ForegroundColor White
Write-Host "3. Try creating your profile again" -ForegroundColor White
Write-Host "4. Watch the BACKEND console for:" -ForegroundColor White
Write-Host "   'Token validated for user: chinni070707@gmail.com'" -ForegroundColor Green
Write-Host ""

Write-Host "If you see that message, everything is working!" -ForegroundColor Green
Write-Host ""
