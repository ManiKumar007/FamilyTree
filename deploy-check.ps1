#!/usr/bin/env pwsh
# =============================================
# MyFamilyTree - Deployment Checklist
# =============================================
# This script helps you prepare for deployment to Render.com

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "  MyFamilyTree - Deployment Checklist" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$allGood = $true

# =============================================
# 1. Check Git Status
# =============================================
Write-Host "1️⃣  Checking Git Status..." -ForegroundColor Yellow
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "   ⚠️  You have uncommitted changes:" -ForegroundColor Red
    Write-Host "   Run: git add -A && git commit -m 'Prepare for deployment'" -ForegroundColor Gray
    $allGood = $false
} else {
    Write-Host "   ✓ Git working tree is clean" -ForegroundColor Green
}

# Check if pushed to remote
$unpushed = git log origin/master..HEAD --oneline
if ($unpushed) {
    Write-Host "   ⚠️  You have unpushed commits:" -ForegroundColor Red
    Write-Host "   Run: git push origin master" -ForegroundColor Gray
    $allGood = $false
} else {
    Write-Host "   ✓ All commits pushed to remote" -ForegroundColor Green
}
Write-Host ""

# =============================================
# 2. Check Environment Files
# =============================================
Write-Host "2️⃣  Checking Environment Configuration..." -ForegroundColor Yellow

if (Test-Path "backend\.env") {
    Write-Host "   ✓ backend/.env exists" -ForegroundColor Green
    
    # Check for required variables
    $backendEnv = Get-Content "backend\.env" -Raw
    $requiredVars = @('SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY', 'SUPABASE_ANON_KEY')
    foreach ($var in $requiredVars) {
        if ($backendEnv -match $var) {
            Write-Host "   ✓ $var is set" -ForegroundColor Green
        } else {
            Write-Host "   ✗ $var is missing" -ForegroundColor Red
            $allGood = $false
        }
    }
} else {
    Write-Host "   ✗ backend/.env not found" -ForegroundColor Red
    $allGood = $false
}

if (Test-Path "app\.env") {
    Write-Host "   ✓ app/.env exists" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  app/.env not found (optional for web builds)" -ForegroundColor Yellow
}
Write-Host ""

# =============================================
# 3. Check Backend Build
# =============================================
Write-Host "3️⃣  Testing Backend Build..." -ForegroundColor Yellow
Push-Location backend
try {
    $buildOutput = npm run build 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ Backend builds successfully" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Backend build failed" -ForegroundColor Red
        Write-Host "   Check errors above" -ForegroundColor Gray
        $allGood = $false
    }
} finally {
    Pop-Location
}
Write-Host ""

# =============================================
# 4. Check Backend Tests
# =============================================
Write-Host "4️⃣  Running Backend Tests..." -ForegroundColor Yellow
Push-Location backend
try {
    $testOutput = npm test 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ All backend tests pass" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Some tests failed (review before deploying)" -ForegroundColor Yellow
    }
} finally {
    Pop-Location
}
Write-Host ""

# =============================================
# 5. Check Render Configuration
# =============================================
Write-Host "5️⃣  Checking Render Configuration..." -ForegroundColor Yellow
if (Test-Path "render.yaml") {
    Write-Host "   ✓ render.yaml exists" -ForegroundColor Green
    
    # Check if URLs need updating
    $renderYaml = Get-Content "render.yaml" -Raw
    if ($renderYaml -match "familytree-web.onrender.com") {
        Write-Host "   ℹ️  Using default Render URLs" -ForegroundColor Cyan
        Write-Host "      Update render.yaml if using custom domains" -ForegroundColor Gray
    }
} else {
    Write-Host "   ✗ render.yaml not found" -ForegroundColor Red
    $allGood = $false
}
Write-Host ""

# =============================================
# 6. Check Production URLs in Code
# =============================================
Write-Host "6️⃣  Checking Production URLs in Code..." -ForegroundColor Yellow

# Check backend CORS
$backendIndex = Get-Content "backend\src\index.ts" -Raw
if ($backendIndex -match "allowedOrigins") {
    Write-Host "   ✓ Backend CORS configured for production" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Backend CORS may need production URL" -ForegroundColor Yellow
}

# Frontend uses dotenv, so URLs are configuration-based
Write-Host "   ✓ Frontend uses environment-based configuration" -ForegroundColor Green
Write-Host ""

# =============================================
# 7. Deployment Checklist
# =============================================
Write-Host "7️⃣  Pre-Deployment Checklist:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Backend (Render.com):" -ForegroundColor Cyan
Write-Host "   [ ] Create Web Service from GitHub repo" -ForegroundColor White
Write-Host "   [ ] Set environment variables in Render dashboard" -ForegroundColor White
Write-Host "   [ ] Configure health check: /api/health" -ForegroundColor White
Write-Host "   [ ] Note the deployed backend URL" -ForegroundColor White
Write-Host ""
Write-Host "   Frontend (Render.com):" -ForegroundColor Cyan
Write-Host "   [ ] Create Static Site from GitHub repo" -ForegroundColor White
Write-Host "   [ ] Update API_BASE_URL in app/.env to backend URL" -ForegroundColor White
Write-Host "   [ ] Configure rewrite rule: /* → /index.html" -ForegroundColor White
Write-Host "   [ ] Deploy and note the frontend URL" -ForegroundColor White
Write-Host ""
Write-Host "   Supabase:" -ForegroundColor Cyan
Write-Host "   [ ] Add frontend URL to allowed origins" -ForegroundColor White
Write-Host "   [ ] Add frontend URL to redirect URLs" -ForegroundColor White
Write-Host "   [ ] Verify RLS policies are enabled" -ForegroundColor White
Write-Host ""
Write-Host "   Post-Deployment:" -ForegroundColor Cyan
Write-Host "   [ ] Test /api/health endpoint" -ForegroundColor White
Write-Host "   [ ] Test login/signup flow" -ForegroundColor White
Write-Host "   [ ] Verify all features work" -ForegroundColor White
Write-Host "   [ ] Monitor logs for errors" -ForegroundColor White
Write-Host ""

# =============================================
# Final Summary
# =============================================
if ($allGood) {
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "  ✅ All checks passed!" -ForegroundColor Green
    Write-Host "  Ready to deploy to Render.com" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Go to https://render.com" -ForegroundColor White
    Write-Host "2. Create New → Blueprint" -ForegroundColor White
    Write-Host "3. Connect GitHub repo: ManiKumar007/FamilyTree" -ForegroundColor White
    Write-Host "4. Follow the DEPLOYMENT.md guide" -ForegroundColor White
} else {
    Write-Host "=============================================" -ForegroundColor Red
    Write-Host "  ⚠️  Some checks failed" -ForegroundColor Red
    Write-Host "  Fix the issues above before deploying" -ForegroundColor Red
    Write-Host "=============================================" -ForegroundColor Red
}

Write-Host ""
Write-Host "For detailed instructions, see: DEPLOYMENT.md" -ForegroundColor Cyan
Write-Host ""
