# Start Flutter App Script (RELEASE MODE - Fastest)
# Release mode: Production-optimized, minimal debugging
# Typical load time: 20-40 seconds

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
Write-Host "Starting MyFamilyTree Flutter App in RELEASE MODE (fastest)..." -ForegroundColor Green
Write-Host "Expected load time: 20-40 seconds" -ForegroundColor Yellow
Write-Host "Note: No hot reload available in release mode" -ForegroundColor Gray
Write-Host ""

Set-Location app
C:\src\flutter\bin\flutter.bat run -d chrome --release
