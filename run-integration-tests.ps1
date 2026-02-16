#!/usr/bin/env pwsh
# Run Flutter Integration Tests
# Usage: .\run-integration-tests.ps1 [test-file] [device]

param(
    [string]$TestFile = "app_test.dart",
    [string]$Device = "chrome"
)

Write-Host "`n🧪 Flutter Integration Test Runner`n" -ForegroundColor Cyan

# Check if Flutter is available
try {
    $flutterVersion = & C:\src\flutter\bin\flutter.bat --version 2>&1 | Select-Object -First 1
    Write-Host "✓ Flutter found: $flutterVersion" -ForegroundColor Green
}
catch {
    Write-Host "✗ Flutter not found. Please install Flutter first." -ForegroundColor Red
    exit 1
}

# Navigate to app directory
$appDir = Join-Path $PSScriptRoot "app"
Set-Location $appDir

Write-Host "`n📦 Installing dependencies..." -ForegroundColor Yellow
& C:\src\flutter\bin\flutter.bat pub get

Write-Host "`n🔍 Available devices:" -ForegroundColor Yellow
& C:\src\flutter\bin\flutter.bat devices

Write-Host "`n▶️  Running integration tests..." -ForegroundColor Cyan
Write-Host "   Test file: integration_test/$TestFile" -ForegroundColor White
Write-Host "   Target device: $Device`n" -ForegroundColor White

# Run the tests
$testPath = "integration_test/$TestFile"
& C:\src\flutter\bin\flutter.bat test $testPath -d $Device --verbose

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ All tests passed!" -ForegroundColor Green
}
else {
    Write-Host "`n❌ Some tests failed. Check output above." -ForegroundColor Red
    exit 1
}

Write-Host ""
