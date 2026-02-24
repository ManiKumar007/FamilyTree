# Start Backend Server Script
# Automatically kills existing Node.js processes before starting

Write-Host "Checking for running Node.js processes..." -ForegroundColor Cyan

$nodeProcesses = Get-Process -Name node -ErrorAction SilentlyContinue

if ($nodeProcesses) {
    Write-Host "Found $($nodeProcesses.Count) running Node.js process(es). Stopping them..." -ForegroundColor Yellow
    $nodeProcesses | Stop-Process -Force
    Start-Sleep -Seconds 1
    Write-Host "All Node.js processes stopped." -ForegroundColor Green
}
else {
    Write-Host "No existing Node.js processes found." -ForegroundColor Green
}

Write-Host ""
Write-Host "Starting MyFamilyTree Backend Server..." -ForegroundColor Green
Write-Host ""

Set-Location backend
npm run dev
