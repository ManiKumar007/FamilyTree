# Run Profile Setup Integration Test
# Automated test for the profile creation feature

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Profile Setup Integration Test" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Prerequisites:" -ForegroundColor Yellow
Write-Host "  ✓ Backend must be running (port 3000)" -ForegroundColor Gray
Write-Host "  ✓ Supabase must be accessible" -ForegroundColor Gray
Write-Host ""

# Check if backend is running
Write-Host "Checking backend status..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:3000/api/health" -Method Get -TimeoutSec 3
    Write-Host "✓ Backend is running" -ForegroundColor Green
}
catch {
    Write-Host "✗ Backend is not running!" -ForegroundColor Red
    Write-Host "  Please run .\start-backend.ps1 first" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Running integration test..." -ForegroundColor Cyan
Write-Host "This will:" -ForegroundColor Yellow
Write-Host "  1. Create a new test account" -ForegroundColor Gray
Write-Host "  2. Log in with the account" -ForegroundColor Gray
Write-Host "  3. Fill out profile setup form" -ForegroundColor Gray
Write-Host "  4. Submit profile to backend API" -ForegroundColor Gray
Write-Host "  5. Verify profile creation succeeded" -ForegroundColor Gray
Write-Host ""

# Change to app directory
Set-Location app

# Run the integration test
Write-Host "Executing: flutter test integration_test/profile_setup_test.dart -d chrome" -ForegroundColor Gray
Write-Host ""

flutter test integration_test/profile_setup_test.dart -d chrome

# Check result
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "  ✓ All tests PASSED!" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Red
    Write-Host "  ✗ Tests FAILED" -ForegroundColor Red
    Write-Host "=========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check the output above for error details" -ForegroundColor Yellow
}

# Return to root directory
Set-Location ..

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
