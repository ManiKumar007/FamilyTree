# Start Flutter App Script (PROFILE MODE - Faster)
# Profile mode: Better performance than debug, still allows some profiling
# Typical load time: 30-60 seconds (vs 3+ minutes in debug)

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
Write-Host "Starting MyFamilyTree Flutter App in PROFILE MODE (faster)..." -ForegroundColor Green
Write-Host "Expected load time: 30-60 seconds" -ForegroundColor Yellow
Write-Host ""

Set-Location app
C:\src\flutter\bin\flutter.bat run -d chrome --profile
