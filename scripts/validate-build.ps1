# Validate Build Before Deploy
# Run this script before pushing to ensure Vercel deployment won't fail

param(
    [switch]$SkipBackend,
    [switch]$SkipFrontend
)

Write-Host "=====================================" -ForegroundColor Magenta
Write-Host "  Build Validation Before Deploy" -ForegroundColor Magenta
Write-Host "=====================================" -ForegroundColor Magenta
Write-Host ""

$failed = $false

# ── Flutter Frontend ──
if (-not $SkipFrontend) {
    Write-Host "📱 Validating Flutter Web Build..." -ForegroundColor Cyan
    Push-Location "$PSScriptRoot\..\app"
    
    Write-Host "  Running flutter analyze..." -ForegroundColor Yellow
    $analyzeOutput = flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ Flutter analyze found errors:" -ForegroundColor Red
        Write-Host $analyzeOutput
        $failed = $true
    } else {
        Write-Host "  ✅ Flutter analyze passed" -ForegroundColor Green
    }
    
    Write-Host "  Running flutter build web..." -ForegroundColor Yellow
    $buildOutput = flutter build web --release 2>&1 | Out-String
    if ($buildOutput -match "Built build\\web" -or $buildOutput -match "Built build/web") {
        Write-Host "  ✅ Flutter web build succeeded" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Flutter web build failed:" -ForegroundColor Red
        Write-Host $buildOutput
        $failed = $true
    }
    
    Pop-Location
    Write-Host ""
}

# ── Backend ──
if (-not $SkipBackend) {
    Write-Host "🖥️  Validating Backend Build..." -ForegroundColor Cyan
    Push-Location "$PSScriptRoot\..\backend"
    
    Write-Host "  Running TypeScript check..." -ForegroundColor Yellow
    $tscOutput = npx tsc --noEmit 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ TypeScript check passed" -ForegroundColor Green
    } else {
        Write-Host "  ❌ TypeScript errors:" -ForegroundColor Red
        Write-Host $tscOutput
        $failed = $true
    }
    
    Write-Host "  Running npm build..." -ForegroundColor Yellow
    $buildOutput = npm run build 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Backend build succeeded" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Backend build failed:" -ForegroundColor Red
        Write-Host $buildOutput
        $failed = $true
    }
    
    Pop-Location
    Write-Host ""
}

# ── Result ──
if ($failed) {
    Write-Host "❌ VALIDATION FAILED - Do NOT push/deploy until errors are fixed" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ ALL VALIDATIONS PASSED - Safe to push and deploy!" -ForegroundColor Green
    exit 0
}
