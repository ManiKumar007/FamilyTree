#!/usr/bin/env pwsh
# Run Flutter Integration Tests
# Usage: .\run-integration-tests.ps1 [test-file] [device]

param(
    [string]$TestFile = "app_test.dart",
    [string]$Device = "chrome"
)

Write-Host "`n🧪 Flutter Integration Test Runner`n" -ForegroundColor Cyan

# Auto-detect Flutter path
$flutterCmd = $null
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    $flutterCmd = "flutter"
} elseif (Test-Path "C:\flutter\bin\flutter.bat") {
    $flutterCmd = "C:\flutter\bin\flutter.bat"
} elseif (Test-Path "C:\src\flutter\bin\flutter.bat") {
    $flutterCmd = "C:\src\flutter\bin\flutter.bat"
} else {
    Write-Host "✗ Flutter not found. Please install Flutter first." -ForegroundColor Red
    exit 1
}

# Check if Flutter is available
try {
    $flutterVersion = & $flutterCmd --version 2>&1 | Select-Object -First 1
    Write-Host "✓ Flutter found: $flutterVersion" -ForegroundColor Green
    Write-Host "  Using: $flutterCmd" -ForegroundColor Cyan
}
catch {
    Write-Host "✗ Error running Flutter. Please check your installation." -ForegroundColor Red
    exit 1
}

# Navigate to app directory
$appDir = Join-Path $PSScriptRoot "app"
Set-Location $appDir

Write-Host "`n📦 Installing dependencies..." -ForegroundColor Yellow
& $flutterCmd pub get

Write-Host "`n🔍 Available devices:" -ForegroundColor Yellow
& $flutterCmd devices

Write-Host "`n▶️  Running integration tests..." -ForegroundColor Cyan
Write-Host "   Test file: integration_test/$TestFile" -ForegroundColor White
Write-Host "   Target device: $Device`n" -ForegroundColor White

# Run the tests
$testPath = "integration_test/$TestFile"
& $flutterCmd test $testPath -d $Device --verbose

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ All tests passed!" -ForegroundColor Green
}
else {
    Write-Host "`n❌ Some tests failed. Check output above." -ForegroundColor Red
    exit 1
}

Write-Host ""
