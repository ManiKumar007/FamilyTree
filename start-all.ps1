# Start All Services Script
# Starts both backend and frontend with automatic cleanup

Write-Host "=====================================" -ForegroundColor Magenta
Write-Host "  MyFamilyTree - Start All Services" -ForegroundColor Magenta
Write-Host "=====================================" -ForegroundColor Magenta
Write-Host ""

# Kill existing processes
Write-Host "Checking for running processes..." -ForegroundColor Cyan

$nodeProcesses = Get-Process -Name node -ErrorAction SilentlyContinue
$dartProcesses = Get-Process | Where-Object { $_.ProcessName -match 'dart|flutter' }

$totalProcesses = @($nodeProcesses; $dartProcesses).Count

if ($totalProcesses -gt 0) {
    Write-Host "Found $totalProcesses running process(es). Stopping them..." -ForegroundColor Yellow
    
    if ($nodeProcesses) {
        $nodeProcesses | Stop-Process -Force
    }
    if ($dartProcesses) {
        $dartProcesses | Stop-Process -Force
    }
    
    Start-Sleep -Seconds 2
    Write-Host "All existing processes stopped." -ForegroundColor Green
}
else {
    Write-Host "No existing processes found." -ForegroundColor Green
}

Write-Host ""
Write-Host "Starting Backend Server..." -ForegroundColor Green

# Start backend in a new window
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot\backend'; npm run dev"

Write-Host "Waiting 3 seconds for backend to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

Write-Host ""
Write-Host "Starting Flutter App..." -ForegroundColor Green

# Auto-detect Flutter path
$flutterCmd = $null
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    $flutterCmd = "flutter"
}
elseif (Test-Path "C:\flutter\bin\flutter.bat") {
    $flutterCmd = "C:\flutter\bin\flutter.bat"
}
elseif (Test-Path "C:\src\flutter\bin\flutter.bat") {
    $flutterCmd = "C:\src\flutter\bin\flutter.bat"
}
else {
    Write-Host "❌ Flutter not found. Please install Flutter or add it to PATH." -ForegroundColor Red
    exit 1
}

Write-Host "Using Flutter: $flutterCmd" -ForegroundColor Cyan

# Start frontend in a new window with fixed port 5500
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot\app'; & '$flutterCmd' run -d chrome --web-port=5500"

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "  All services started!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "Backend:  http://localhost:3000" -ForegroundColor Cyan
Write-Host "Frontend: http://localhost:5500" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit this window..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
