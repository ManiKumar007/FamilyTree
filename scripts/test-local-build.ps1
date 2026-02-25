<#
.SYNOPSIS
    Script to test local builds - mirrors GitHub Actions CI pipeline
.DESCRIPTION
    Tests both Flutter web and backend builds locally
.PARAMETER SkipFlutter
    Skip Flutter web build test
.PARAMETER SkipBackend
    Skip backend build test
#>

param(
    [switch]$SkipFlutter,
    [switch]$SkipBackend
)

$ErrorActionPreference = "Stop"
$rootDir = Split-Path -Parent $PSScriptRoot

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Local Build Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$buildSuccess = $true

# Flutter Web Build Test
if (-not $SkipFlutter) {
    Write-Host ""
    Write-Host "Testing Flutter Web Build" -ForegroundColor Blue
    Write-Host "-------------------------------------" -ForegroundColor Blue
    Write-Host ""

    Push-Location "$rootDir\app"
    
    try {
        # Check Flutter installation
        Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
        $flutterVersion = flutter --version 2>&1 | Select-String "Flutter"
        if (-not $flutterVersion) {
            throw "Flutter is not installed or not in PATH"
        }
        Write-Host "  $flutterVersion" -ForegroundColor Gray

        # Create .env file (CI does this)
        Write-Host ""
        Write-Host "Creating .env for CI testing..." -ForegroundColor Yellow
        Set-Content -Path ".env" -Value @(
            "SUPABASE_URL=https://vojwwcolmnbzogsrmwap.supabase.co",
            "SUPABASE_ANON_KEY=placeholder_for_ci",
            "API_BASE_URL=https://backend-five-blue-16.vercel.app/api",
            "APP_URL=https://familytree-web.vercel.app",
            "GOOGLE_CLIENT_ID=placeholder_for_ci"
        ) -Encoding UTF8
        
        # Enable web platform
        Write-Host ""
        Write-Host "Checking web platform..." -ForegroundColor Yellow
        if (-not (Test-Path "web")) {
            Write-Host "  Enabling web platform..." -ForegroundColor Gray
            flutter create . --platforms web
        } else {
            Write-Host "  Web platform already enabled" -ForegroundColor Gray
        }

        # Install dependencies
        Write-Host ""
        Write-Host "Installing Flutter dependencies..." -ForegroundColor Yellow
        flutter pub get
        if ($LASTEXITCODE -ne 0) { throw "Flutter pub get failed" }

        # Run analyzer
        Write-Host ""
        Write-Host "Running Flutter analyze (errors only)..." -ForegroundColor Yellow
        flutter analyze --no-fatal-infos --no-fatal-warnings
        if ($LASTEXITCODE -ne 0) { 
            Write-Host "  Flutter analyze found errors!" -ForegroundColor Red
            $buildSuccess = $false
        } else {
            Write-Host "  No errors found" -ForegroundColor Green
        }

        # Build web
        Write-Host ""
        Write-Host "Building Flutter Web (release)..." -ForegroundColor Yellow
        flutter build web --release
        if ($LASTEXITCODE -ne 0) { 
            throw "Flutter build web failed"
        }

        Write-Host ""
        Write-Host "SUCCESS: Flutter Web Build" -ForegroundColor Green
        Write-Host "Build output: app\build\web" -ForegroundColor Gray

    } catch {
        Write-Host ""
        Write-Host "FAILED: Flutter Web Build" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        $buildSuccess = $false
    } finally {
        Pop-Location
    }
}

# Backend Build Test
if (-not $SkipBackend) {
    Write-Host ""
    Write-Host "Testing Backend Build" -ForegroundColor Blue
    Write-Host "-------------------------------------" -ForegroundColor Blue
    Write-Host ""

    Push-Location "$rootDir\backend"
    
    try {
        # Check Node installation
        Write-Host "Checking Node.js installation..." -ForegroundColor Yellow
        $nodeVersion = node --version 2>&1
        if (-not $nodeVersion) {
            throw "Node.js is not installed or not in PATH"
        }
        Write-Host "  Node.js: $nodeVersion" -ForegroundColor Gray
        
        $npmVersion = npm --version 2>&1
        Write-Host "  npm: $npmVersion" -ForegroundColor Gray

        # Install dependencies
        Write-Host ""
        Write-Host "Installing backend dependencies..." -ForegroundColor Yellow
        npm ci
        if ($LASTEXITCODE -ne 0) { 
            Write-Host "  npm ci failed, trying npm install..." -ForegroundColor Yellow
            npm install
            if ($LASTEXITCODE -ne 0) { throw "npm install failed" }
        }

        # TypeScript compile check
        Write-Host ""
        Write-Host "Running TypeScript compile check..." -ForegroundColor Yellow
        npx tsc --noEmit
        if ($LASTEXITCODE -ne 0) { 
            Write-Host "  TypeScript errors detected!" -ForegroundColor Red
            $buildSuccess = $false
        } else {
            Write-Host "  No TypeScript errors" -ForegroundColor Green
        }

        # Build
        Write-Host ""
        Write-Host "Building backend..." -ForegroundColor Yellow
        npm run build
        if ($LASTEXITCODE -ne 0) { 
            throw "Backend build failed"
        }

        Write-Host ""
        Write-Host "SUCCESS: Backend Build" -ForegroundColor Green
        Write-Host "Build output: backend\dist" -ForegroundColor Gray

    } catch {
        Write-Host ""
        Write-Host "FAILED: Backend Build" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        $buildSuccess = $false
    } finally {
        Pop-Location
    }
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($buildSuccess) {
    Write-Host "ALL BUILDS PASSED" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    exit 0
} else {
    Write-Host "SOME BUILDS FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}
