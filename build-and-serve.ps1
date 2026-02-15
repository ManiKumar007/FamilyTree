# Build and Serve Flutter Web App (FASTEST for testing)
# Builds optimized production bundle and serves it locally
# First build: 1-2 minutes
# Subsequent page loads: 2-5 seconds!

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  Build & Serve Flutter Web App" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Set-Location app

Write-Host "Building optimized web bundle..." -ForegroundColor Yellow
Write-Host "This will take 1-2 minutes (one time)..." -ForegroundColor Gray
Write-Host ""

C:\src\flutter\bin\flutter.bat build web --release

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Build completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Starting local web server..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host "  App running at:" -ForegroundColor Green
    Write-Host "  http://localhost:5500" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Gray
    Write-Host ""
    
    # Serve the built files using Python (if available) or PHP
    if (Get-Command python -ErrorAction SilentlyContinue) {
        Set-Location build\web
        python -m http.server 5500
    }
    elseif (Get-Command php -ErrorAction SilentlyContinue) {
        Set-Location build\web
        php -S localhost:5500
    }
    else {
        Write-Host "Error: Neither Python nor PHP found." -ForegroundColor Red
        Write-Host "Please install Python or use 'flutter run -d chrome --release' instead" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Or manually serve the 'app/build/web' folder with any web server" -ForegroundColor Gray
        pause
    }
}
else {
    Write-Host ""
    Write-Host "Build failed. Please check the errors above." -ForegroundColor Red
    pause
}
