# MyFamilyTree Quick Start Script
# This script starts both backend and frontend applications

Write-Host "🚀 MyFamilyTree Application Quick Start" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if backend and frontend directories exist
if (-not (Test-Path "backend")) {
    Write-Host "❌ Error: backend directory not found" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "app")) {
    Write-Host "❌ Error: app directory not found" -ForegroundColor Red
    exit 1
}

# Display seed data information
Write-Host "📊 Sample Data Available:" -ForegroundColor Yellow
Write-Host "   The application is pre-loaded with sample family tree data:" -ForegroundColor Gray
Write-Host "   • Main User: Mani Kumar (Software Engineer)" -ForegroundColor Gray
Write-Host "   • Parents: Rajesh Kumar & Lakshmi Devi" -ForegroundColor Gray
Write-Host "   • Spouse: Priya Sharma (Doctor)" -ForegroundColor Gray
Write-Host "   • Children: Aarav Kumar (Son), Ananya Kumar (Daughter)" -ForegroundColor Gray
Write-Host "   • Sibling: Kavya Kumar (Sister)" -ForegroundColor Gray
Write-Host "   Total: 7 family members with complete relationships" -ForegroundColor Green
Write-Host ""

# Start Backend
Write-Host "🔧 Starting Backend Server..." -ForegroundColor Yellow
$backendJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    cd backend
    npm run dev
}

Write-Host "   Backend starting in background (Job ID: $($backendJob.Id))..." -ForegroundColor Gray

# Wait a moment for backend to initialize
Start-Sleep -Seconds 3

# Check if backend is running
Write-Host "   Checking backend health..." -ForegroundColor Gray
$retries = 0
$maxRetries = 10
$backendReady = $false

while ($retries -lt $maxRetries -and -not $backendReady) {
    try {
        $health = Invoke-WebRequest -Uri "http://localhost:3000/api/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($health.StatusCode -eq 200) {
            $backendReady = $true
            Write-Host "   ✅ Backend is ready!" -ForegroundColor Green
        }
    }
    catch {
        $retries++
        if ($retries -lt $maxRetries) {
            Write-Host "   ⏳ Waiting for backend... ($retries/$maxRetries)" -ForegroundColor Gray
            Start-Sleep -Seconds 2
        }
    }
}

if (-not $backendReady) {
    Write-Host "   ⚠️  Backend may still be starting. Continuing anyway..." -ForegroundColor Yellow
}

Write-Host ""

# Start Frontend
Write-Host "📱 Starting Frontend Application..." -ForegroundColor Yellow
$frontendJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    cd app
    flutter run -d chrome --web-port 5500
}

Write-Host "   Frontend starting in background (Job ID: $($frontendJob.Id))..." -ForegroundColor Gray
Write-Host ""

# Display status and instructions
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Application Started Successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📍 Access Points:" -ForegroundColor Yellow
Write-Host "   🌐 Frontend: http://localhost:5500" -ForegroundColor Cyan
Write-Host "   🔌 Backend API: http://localhost:3000/api" -ForegroundColor Cyan
Write-Host "   ❤️  Health Check: http://localhost:3000/api/health" -ForegroundColor Cyan
Write-Host ""
Write-Host "👤 Test User Credentials:" -ForegroundColor Yellow
Write-Host "   📧 Email: manich623@gmail.com" -ForegroundColor Cyan
Write-Host "   👨 User: Mani Kumar" -ForegroundColor Cyan
Write-Host "   📱 Phone: +919876543210" -ForegroundColor Cyan
Write-Host ""
Write-Host "🧪 Testing Commands:" -ForegroundColor Yellow
Write-Host "   Test API:  " -NoNewline -ForegroundColor Gray
Write-Host ".\test-api.ps1" -ForegroundColor Cyan
Write-Host "   Run Tests: " -NoNewline -ForegroundColor Gray
Write-Host "cd backend; npm test" -ForegroundColor Cyan
Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Yellow
Write-Host "   • SEED_DATA.md - Sample data documentation" -ForegroundColor Gray
Write-Host "   • QUICK_REFERENCE.md - Quick commands reference" -ForegroundColor Gray
Write-Host "   • TESTING_BEST_PRACTICES.md - Testing guide" -ForegroundColor Gray
Write-Host "   • API_TROUBLESHOOTING.md - Debug help" -ForegroundColor Gray
Write-Host ""
Write-Host "🛑 To Stop:" -ForegroundColor Yellow
Write-Host "   Run: " -NoNewline -ForegroundColor Gray
Write-Host ".\stop-all.ps1" -ForegroundColor Cyan
Write-Host "   Or press Ctrl+C to view job status, then run:" -ForegroundColor Gray
Write-Host "   " -NoNewline
Write-Host "Stop-Job $($backendJob.Id), $($frontendJob.Id); Remove-Job $($backendJob.Id), $($frontendJob.Id)" -ForegroundColor Cyan
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📝 Press Ctrl+C to view logs or stop" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Monitor jobs
Write-Host "📊 Application Status:" -ForegroundColor Yellow
Write-Host ""

# Keep script running and show logs
try {
    while ($true) {
        # Check job status
        $backendStatus = (Get-Job -Id $backendJob.Id).State
        $frontendStatus = (Get-Job -Id $frontendJob.Id).State
        
        if ($backendStatus -eq "Failed" -or $frontendStatus -eq "Failed") {
            Write-Host "❌ One or more services failed!" -ForegroundColor Red
            
            if ($backendStatus -eq "Failed") {
                Write-Host "`n🔴 Backend Error:" -ForegroundColor Red
                Receive-Job -Id $backendJob.Id
            }
            
            if ($frontendStatus -eq "Failed") {
                Write-Host "`n🔴 Frontend Error:" -ForegroundColor Red
                Receive-Job -Id $frontendJob.Id
            }
            
            break
        }
        
        Start-Sleep -Seconds 5
    }
}
finally {
    Write-Host "`nCleaning up..." -ForegroundColor Yellow
    Stop-Job $backendJob.Id, $frontendJob.Id -ErrorAction SilentlyContinue
    Remove-Job $backendJob.Id, $frontendJob.Id -ErrorAction SilentlyContinue
    Write-Host "✅ Stopped all services" -ForegroundColor Green
}
