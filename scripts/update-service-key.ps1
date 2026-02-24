#!/usr/bin/env pwsh
# Update Supabase SERVICE_ROLE_KEY in backend/.env

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Update Supabase Service Role Key" -ForegroundColor Cyan  
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check if backend .env exists
if (-not (Test-Path ".\backend\.env")) {
    Write-Host "ERROR: backend\.env not found!" -ForegroundColor Red
    exit 1
}

# Show current configuration
Write-Host "Current Configuration:" -ForegroundColor Yellow
$currentUrl = (Get-Content ".\backend\.env" | Select-String "^SUPABASE_URL=").ToString()
Write-Host "  $currentUrl" -ForegroundColor White
Write-Host ""

Write-Host "Instructions:" -ForegroundColor Cyan
Write-Host "1. Go to: https://supabase.com/dashboard" -ForegroundColor White
Write-Host "2. Select your project (vojwwcolmnbzogsrmwap)" -ForegroundColor White
Write-Host "3. Go to Settings > API" -ForegroundColor White
Write-Host "4. Find 'service_role' key (labeled 'secret' - DO NOT SHARE!)" -ForegroundColor White
Write-Host "5. Click 'Reveal' and copy the ENTIRE key" -ForegroundColor White
Write-Host ""

# Prompt for new key
Write-Host "Paste the new SERVICE_ROLE_KEY below:" -ForegroundColor Yellow
Write-Host "(Press Ctrl+C to cancel)" -ForegroundColor Gray
Write-Host ""
$newKey = Read-Host "SERVICE_ROLE_KEY"

if ([string]::IsNullOrWhiteSpace($newKey)) {
    Write-Host "ERROR: No key provided. Cancelled." -ForegroundColor Red
    exit 1
}

# Validate key format (should start with eyJ and be long)
if (-not $newKey.StartsWith("eyJ")) {
    Write-Host "WARNING: Key doesn't start with 'eyJ' - are you sure this is correct?" -ForegroundColor Yellow
    $confirm = Read-Host "Continue anyway? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit 0
    }
}

if ($newKey.Length -lt 100) {
    Write-Host "WARNING: Key seems too short (should be 200+ characters)" -ForegroundColor Yellow
    $confirm = Read-Host "Continue anyway? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Backup current .env
Write-Host ""
Write-Host "Creating backup..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item ".\backend\.env" ".\backend\.env.backup_$timestamp"
Write-Host "Backed up to: backend\.env.backup_$timestamp" -ForegroundColor Green

# Update the key
Write-Host "Updating SERVICE_ROLE_KEY..." -ForegroundColor Yellow
$envContent = Get-Content ".\backend\.env"
$updatedContent = $envContent | ForEach-Object {
    if ($_ -match "^SUPABASE_SERVICE_ROLE_KEY=") {
        "SUPABASE_SERVICE_ROLE_KEY=$newKey"
    }
    else {
        $_
    }
}
$updatedContent | Set-Content ".\backend\.env"

Write-Host "Updated successfully!" -ForegroundColor Green
Write-Host ""

# Show preview
Write-Host "New configuration:" -ForegroundColor Yellow
Write-Host "  SUPABASE_SERVICE_ROLE_KEY=$($newKey.Substring(0, 30))..." -ForegroundColor White
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Restart backend: .\stop-all.ps1 then .\start-all.ps1" -ForegroundColor White
Write-Host "2. Try creating your profile again" -ForegroundColor White
Write-Host "3. Check backend console for 'Token validated for user: your-email'" -ForegroundColor White
Write-Host ""
Write-Host "Done!" -ForegroundColor Green
