# Start Flutter App for E2E Testing
# Runs Flutter web-server mode with HTML renderer for Playwright testing

Write-Host "Checking for running Flutter/Dart processes..." -ForegroundColor Cyan

$dartProcesses = Get-Process | Where-Object { $_.ProcessName -match 'dart|flutter' }

if ($dartProcesses) {
    Write-Host "Found $($dartProcesses.Count) running Flutter/Dart process(es). Stopping them..." -ForegroundColor Yellow
    $dartProcesses | Stop-Process -Force
    Start-Sleep -Seconds 2
    Write-Host "All Flutter/Dart processes stopped." -ForegroundColor Green
}
else {
    Write-Host "No existing Flutter/Dart processes found." -ForegroundColor Green
}

Write-Host ""
Write-Host "Starting MyFamilyTree Flutter App (web-server mode with HTML renderer on port 5500)..." -ForegroundColor Green
Write-Host "NOTE: Using HTML renderer for E2E testing (DOM elements accessible to Playwright)" -ForegroundColor Yellow
Write-Host ""

# Auto-detect Flutter path
$flutterCmd = $null
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    $flutterCmd = "flutter"
} elseif (Test-Path "C:\flutter\bin\flutter.bat") {
    $flutterCmd = "C:\flutter\bin\flutter.bat"
} elseif (Test-Path "C:\src\flutter\bin\flutter.bat") {
    $flutterCmd = "C:\src\flutter\bin\flutter.bat"
} else {
    Write-Host "❌ Flutter not found. Please install Flutter or add it to PATH." -ForegroundColor Red
    exit 1
}

Write-Host "Using Flutter: $flutterCmd" -ForegroundColor Cyan
Write-Host ""

Set-Location app
& $flutterCmd run -d web-server --web-port=5500 --web-renderer html

