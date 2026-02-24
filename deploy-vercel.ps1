# =============================================================================
# deploy-vercel.ps1 — Deploy both backend and frontend to Vercel production
# =============================================================================
# Run this script when you're ready to push changes to production.
# It deploys both projects and shows the live URLs.
# =============================================================================

param(
    [switch]$BackendOnly,
    [switch]$FrontendOnly
)

Write-Host "🚀 Deploying FamilyTree to Vercel Production" -ForegroundColor Cyan
Write-Host ""

# Ensure we commit any changes first
$gitStatus = git status --porcelain 2>&1
if ($gitStatus) {
    Write-Host "⚠️  You have uncommitted changes:" -ForegroundColor Yellow
    git status --short
    Write-Host ""
    $confirm = Read-Host "Commit and push before deploying? (y/n)"
    if ($confirm -eq 'y') {
        $msg = Read-Host "Commit message"
        git add -A
        git commit -m $msg
        git push origin master
        Write-Host "✅ Pushed to master" -ForegroundColor Green
    }
}

# Deploy Backend
if (-not $FrontendOnly) {
    Write-Host ""
    Write-Host "🔧 Deploying Backend..." -ForegroundColor Yellow
    Push-Location backend
    npx vercel --prod --yes 2>&1
    Pop-Location
    Write-Host "✅ Backend deployed: https://backend-five-blue-16.vercel.app" -ForegroundColor Green
    Write-Host "   Health check: https://backend-five-blue-16.vercel.app/api/health"
}

# Deploy Frontend
if (-not $BackendOnly) {
    Write-Host ""
    Write-Host "🌐 Deploying Frontend..." -ForegroundColor Yellow
    Push-Location app
    npx vercel --prod --yes 2>&1
    Pop-Location
    Write-Host "✅ Frontend deployed: https://familytree-web.vercel.app" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎉 Deployment complete!" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Live URLs:" -ForegroundColor Cyan
Write-Host "   Frontend: https://familytree-web.vercel.app"
Write-Host "   Backend:  https://backend-five-blue-16.vercel.app"
Write-Host "   Health:   https://backend-five-blue-16.vercel.app/api/health"
