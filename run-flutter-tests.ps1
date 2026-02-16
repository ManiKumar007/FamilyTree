# Run Flutter Integration Tests
Write-Host "Running Flutter Integration Tests..." -ForegroundColor Cyan

# Ensure we're in the app directory
Set-Location app

# Run integration tests
C:\flutter\bin\flutter.bat test integration_test/

# Return to root
Set-Location ..
