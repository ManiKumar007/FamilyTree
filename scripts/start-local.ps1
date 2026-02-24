# =============================================================================
# start-local.ps1 — Start the full stack locally for development
# =============================================================================
# This script starts both backend and frontend locally.
# Your .env files point to localhost, so everything runs on your machine.
# Changes are instant — no need to deploy to Vercel.
# =============================================================================

Write-Host "🏠 Starting FamilyTree in LOCAL development mode" -ForegroundColor Cyan
Write-Host ""

# Ensure we're using local env
$appEnv = Get-Content "app\.env" -ErrorAction SilentlyContinue
if ($appEnv -match "vercel\.app") {
    Write-Host "⚠️  Your app\.env points to Vercel URLs. Switching to local..." -ForegroundColor Yellow
    if (Test-Path "app\.env.local") {
        Copy-Item "app\.env.local" "app\.env" -Force
        Write-Host "✅ Copied .env.local → .env" -ForegroundColor Green
    } else {
        Write-Host "❌ No .env.local found. Please create one from .env.example" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "📋 Environment:" -ForegroundColor Cyan
Write-Host "   Frontend: http://localhost:5500"
Write-Host "   Backend:  http://localhost:3000"
Write-Host "   Supabase: https://vojwwcolmnbzogsrmwap.supabase.co"
Write-Host ""

# Start backend in background
Write-Host "🔧 Starting backend..." -ForegroundColor Yellow
$backendJob = Start-Job -ScriptBlock {
    Set-Location "$using:PWD\backend"
    npm run dev 2>&1
}

# Wait for backend to be ready
Write-Host "⏳ Waiting for backend..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Start frontend
Write-Host "🌐 Starting frontend..." -ForegroundColor Yellow
Set-Location "app"
flutter run -d chrome --web-port 5500

# Cleanup
Stop-Job $backendJob -ErrorAction SilentlyContinue
Remove-Job $backendJob -ErrorAction SilentlyContinue
