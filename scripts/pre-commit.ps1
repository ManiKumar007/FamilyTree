#!/usr/bin/env pwsh
# Pre-commit hook: Validates builds before allowing commits
# Install: Copy-Item scripts\pre-commit.ps1 .git\hooks\pre-commit -Force
# This runs the same checks as GitHub CI to catch issues locally

Write-Host "🔍 Running pre-commit validation..." -ForegroundColor Cyan

# Get staged files
$dartFiles = git diff --cached --name-only --diff-filter=ACM | Where-Object { $_ -match '\.dart$' }
$backendFiles = git diff --cached --name-only --diff-filter=ACM | Where-Object { $_ -match '^backend/' }

$hasErrors = $false

# Flutter validation
if ($dartFiles) {
    Write-Host "`n📱 Flutter files changed - running analyze..." -ForegroundColor Yellow
    Push-Location app
    
    # Run Flutter analyze (same as CI)
    Write-Host "   Running: flutter analyze --no-fatal-infos --no-fatal-warnings" -ForegroundColor Gray
    flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1 | Out-String
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Flutter analyze found errors. Fix them before committing." -ForegroundColor Red
        $hasErrors = $true
    } else {
        Write-Host "✅ Flutter analyze passed" -ForegroundColor Green
    }
    
    Pop-Location
}

# Backend validation
if ($backendFiles) {
    Write-Host "`n🖥️  Backend files changed - running TypeScript check..." -ForegroundColor Yellow
    Push-Location backend
    
    # Run TypeScript check (same as CI)
    Write-Host "   Running: npx tsc --noEmit" -ForegroundColor Gray
    npx tsc --noEmit 2>&1 | Out-String
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ TypeScript compilation failed. Fix errors before committing." -ForegroundColor Red
        $hasErrors = $true
    } else {
        Write-Host "✅ Backend TypeScript check passed" -ForegroundColor Green
    }
    
    Pop-Location
}

if ($hasErrors) {
    Write-Host "`n❌ Pre-commit validation FAILED. Please fix errors and try again." -ForegroundColor Red
    Write-Host "   Tip: Run the commands shown above to see detailed errors." -ForegroundColor Gray
    exit 1
}

Write-Host "`n✅ Pre-commit validation passed - ready to commit!" -ForegroundColor Green
exit 0
