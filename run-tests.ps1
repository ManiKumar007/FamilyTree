# Run E2E Tests Script
# Ensures backend and frontend are running before executing Playwright tests

Write-Host "MyFamilyTree E2E Test Runner" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

# Check if backend is running
Write-Host "Checking backend status..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
    Write-Host "✓ Backend is running" -ForegroundColor Green
}
catch {
    Write-Host "✗ Backend is NOT running" -ForegroundColor Red
    Write-Host "  Start backend with: .\start-backend.ps1" -ForegroundColor Yellow
    Write-Host ""
    $startBackend = Read-Host "Would you like to start the backend now? (y/n)"
    if ($startBackend -eq 'y') {
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot'; .\start-backend.ps1"
        Write-Host "Waiting for backend to start..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    }
    else {
        Write-Host "Cannot run tests without backend. Exiting." -ForegroundColor Red
        exit 1
    }
}

# Check if frontend is running
Write-Host "Checking frontend status..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5500" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
    Write-Host "✓ Frontend is running" -ForegroundColor Green
}
catch {
    Write-Host "✗ Frontend is NOT running" -ForegroundColor Red
    Write-Host "  Start frontend with: .\start-frontend.ps1" -ForegroundColor Yellow
    Write-Host ""
    $startFrontend = Read-Host "Would you like to start the frontend now? (y/n)"
    if ($startFrontend -eq 'y') {
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot'; .\start-frontend.ps1"
        Write-Host "Waiting for frontend to start (this may take 60-90 seconds)..." -ForegroundColor Yellow
        Start-Sleep -Seconds 90
    }
    else {
        Write-Host "Cannot run tests without frontend. Exiting." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Both services are running!" -ForegroundColor Green
Write-Host "Starting Playwright tests..." -ForegroundColor Cyan
Write-Host ""

# Navigate to e2e-tests and run tests
Set-Location e2e-tests

# Check if node_modules exists
if (-not (Test-Path "node_modules")) {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    npm install
}

# Run tests
npm test

Write-Host ""
Write-Host "Tests completed!" -ForegroundColor Green
Write-Host "View detailed report with: cd e2e-tests; npm run report" -ForegroundColor Cyan
