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

# Load .env file and pass as dart-define
$envFile = "app\.env"
if (Test-Path $envFile) {
    Write-Host "Loading environment variables from .env..." -ForegroundColor Cyan
    $envVars = Get-Content $envFile | Where-Object { $_ -match '^\s*[^#]' -and $_ -match '=' } | ForEach-Object {
        $parts = $_ -split '=', 2
        @{Key = $parts[0].Trim(); Value = $parts[1].Trim()}
    }
    
    $dartDefines = @()
    foreach ($var in $envVars) {
        $dartDefines += "--dart-define=$($var.Key)=$($var.Value)"
    }
    
    Set-Location app
    & $flutterCmd run -d chrome --web-port=5500 --profile @dartDefines
} else {
    Write-Host "Warning: .env file not found, starting without environment variables" -ForegroundColor Yellow
    Set-Location app
    & $flutterCmd run -d chrome --web-port=5500 --profile
}
