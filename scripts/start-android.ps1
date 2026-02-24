# Start Flutter Android App Script
# Launches Android emulator and runs the app

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  MyFamilyTree - Android Launch" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
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
    Write-Host "Flutter not found. Please install Flutter or add it to PATH." -ForegroundColor Red
    exit 1
}

Write-Host "Using Flutter: $flutterCmd" -ForegroundColor Cyan
Write-Host ""

# Check for connected devices/emulators
Write-Host "Checking for Android devices..." -ForegroundColor Cyan
Set-Location app
$devicesOutput = & $flutterCmd devices | Out-String

if ($devicesOutput -match "android") {
    Write-Host "Android device/emulator found!" -ForegroundColor Green
} else {
    Write-Host "No Android device detected. Available emulators:" -ForegroundColor Yellow
    & $flutterCmd emulators
    Write-Host ""
    Write-Host "Launch an emulator? (y/n)" -ForegroundColor Cyan
    $launch = Read-Host
    
    if ($launch -match "[yY]") {
        Write-Host ""
        Write-Host "Available emulators:" -ForegroundColor Cyan
        Write-Host "1. Pixel 9"
        Write-Host "2. Medium Phone API 36.1"
        Write-Host ""
        Write-Host "Select emulator (1 or 2):" -ForegroundColor Cyan
        $choice = Read-Host
        
        $emulatorId = "Pixel_9"
        if ($choice -eq "2") {
            $emulatorId = "Medium_Phone_API_36.1"
        }
        
        Write-Host ""
        Write-Host "Launching $emulatorId..." -ForegroundColor Green
        Start-Process -FilePath $flutterCmd -ArgumentList "emulators","--launch",$emulatorId -NoNewWindow
        
        Write-Host "Waiting for emulator to boot (30 seconds)..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
    } else {
        Write-Host "Cannot run without an Android device or emulator." -ForegroundColor Red
        Write-Host "Launch an emulator manually or connect a physical device." -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "Starting MyFamilyTree on Android..." -ForegroundColor Green
Write-Host "Note: Backend must be running on http://localhost:3000" -ForegroundColor Yellow
Write-Host ""

# Run the app on Android
& $flutterCmd run
