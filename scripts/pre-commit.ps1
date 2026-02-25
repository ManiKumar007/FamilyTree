# Pre-commit hook: Validates builds before allowing commits

Write-Host "Running pre-commit validation..." -ForegroundColor Cyan

# Get staged files
$dartFiles = git diff --cached --name-only --diff-filter=ACM | Where-Object { $_ -match '\.dart$' }
$backendFiles = git diff --cached --name-only --diff-filter=ACM | Where-Object { $_ -match '^backend/' }

$hasErrors = $false

# Flutter validation
if ($dartFiles) {
    Write-Host "Flutter files changed - running analyze..." -ForegroundColor Yellow
    Push-Location app
    flutter analyze --no-fatal-infos --no-fatal-warnings
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Flutter analyze found errors" -ForegroundColor Red
        $hasErrors = $true
    } else {
        Write-Host "Flutter analyze passed" -ForegroundColor Green
    }
    Pop-Location
}

# Backend validation
if ($backendFiles) {
    Write-Host "Backend files changed - running TypeScript check..." -ForegroundColor Yellow
    Push-Location backend
    npx tsc --noEmit
    if ($LASTEXITCODE -ne 0) {
        Write-Host "TypeScript compilation failed" -ForegroundColor Red
        $hasErrors = $true
    } else {
        Write-Host "Backend TypeScript check passed" -ForegroundColor Green
    }
    Pop-Location
}

if ($hasErrors) {
    Write-Host "Pre-commit validation FAILED" -ForegroundColor Red
    exit 1
}

Write-Host "Pre-commit validation passed!" -ForegroundColor Green
exit 0
