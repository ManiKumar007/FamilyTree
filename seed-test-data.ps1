#!/usr/bin/env pwsh
# Script to seed test/demo data into MyFamilyTree database

Write-Host "`n🌱 MyFamilyTree - Seed Test Data" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "❌ Error: .env file not found!" -ForegroundColor Red
    Write-Host "Please create a .env file with your Supabase credentials." -ForegroundColor Yellow
    exit 1
}

# Load environment variables
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim().Trim('"').Trim("'")
        [Environment]::SetEnvironmentVariable($key, $value)
    }
}

$SUPABASE_URL = $env:SUPABASE_URL
$SUPABASE_SERVICE_KEY = $env:SUPABASE_SERVICE_KEY

if (-not $SUPABASE_URL -or -not $SUPABASE_SERVICE_KEY) {
    Write-Host "❌ Error: Missing Supabase credentials in .env file" -ForegroundColor Red
    Write-Host "Required: SUPABASE_URL and SUPABASE_SERVICE_KEY" -ForegroundColor Yellow
    exit 1
}

Write-Host "📍 Supabase URL: $SUPABASE_URL" -ForegroundColor Gray
Write-Host ""

# Extract project reference from URL
if ($SUPABASE_URL -match 'https://([^.]+)\.supabase\.co') {
    $PROJECT_REF = $matches[1]
} else {
    Write-Host "❌ Error: Invalid Supabase URL format" -ForegroundColor Red
    exit 1
}

# Confirmation prompt
Write-Host "⚠️  WARNING: This will add test data to your database!" -ForegroundColor Yellow
Write-Host ""
Write-Host "This script will create:" -ForegroundColor White
Write-Host "  • 12 test persons (3 generations)" -ForegroundColor Gray
Write-Host "  • 6 forum posts with various types" -ForegroundColor Gray
Write-Host "  • Multiple comments and likes" -ForegroundColor Gray
Write-Host "  • Life events for key persons" -ForegroundColor Gray
Write-Host "  • 8 calendar events" -ForegroundColor Gray
Write-Host "  • 5 test notifications" -ForegroundColor Gray
Write-Host ""
$confirm = Read-Host "Do you want to continue? (yes/no)"

if ($confirm -notmatch "^(y|yes)$") {
    Write-Host "`n❌ Seed cancelled by user" -ForegroundColor Yellow
    exit 0
}

Write-Host "`n🔄 Running seed script..." -ForegroundColor Cyan

# Read the SQL file
$sqlFile = "supabase\seed_test_data.sql"
if (-not (Test-Path $sqlFile)) {
    Write-Host "❌ Error: Seed file not found at $sqlFile" -ForegroundColor Red
    exit 1
}

$sql = Get-Content $sqlFile -Raw

# Execute via Supabase REST API
$headers = @{
    "apikey" = $SUPABASE_SERVICE_KEY
    "Authorization" = "Bearer $SUPABASE_SERVICE_KEY"
    "Content-Type" = "application/json"
    "Prefer" = "return=representation"
}

# Note: Direct SQL execution via REST API is limited
# Better to use Supabase CLI or psql
Write-Host ""
Write-Host "📝 Options for running the seed script:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option 1: Using Supabase CLI (Recommended)" -ForegroundColor Green
Write-Host "  npx supabase db reset" -ForegroundColor Gray
Write-Host "  npx supabase db push" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 2: Using psql directly" -ForegroundColor Yellow
Write-Host "  psql -h db.$PROJECT_REF.supabase.co -U postgres -d postgres -f supabase\seed_test_data.sql" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 3: Via Supabase Dashboard" -ForegroundColor Yellow
Write-Host "  1. Go to: https://supabase.com/dashboard/project/$PROJECT_REF/sql/new" -ForegroundColor Gray
Write-Host "  2. Copy contents of supabase\seed_test_data.sql" -ForegroundColor Gray
Write-Host "  3. Paste and run in SQL Editor" -ForegroundColor Gray
Write-Host ""

# Try to execute using psql if available
if (Get-Command psql -ErrorAction SilentlyContinue) {
    $usePostgres = Read-Host "psql is available. Do you want to run the seed script now? (yes/no)"
    
    if ($usePostgres -match "^(y|yes)$") {
        Write-Host "`n🔄 Executing SQL script via psql..." -ForegroundColor Cyan
        Write-Host "You will be prompted for the database password." -ForegroundColor Yellow
        Write-Host "Get it from: https://supabase.com/dashboard/project/$PROJECT_REF/settings/database" -ForegroundColor Gray
        Write-Host ""
        
        $env:PGPASSWORD = Read-Host "Enter database password" -AsSecureString | ConvertFrom-SecureString -AsPlainText
        
        psql -h "db.$PROJECT_REF.supabase.co" -U postgres -d postgres -f $sqlFile
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✅ Seed data created successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "🎉 Your database now has test data!" -ForegroundColor Cyan
            Write-Host "   Refresh your application to see the changes." -ForegroundColor Gray
        } else {
            Write-Host "`n❌ Error running seed script" -ForegroundColor Red
            Write-Host "Please check the error messages above." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "💡 Tip: Install PostgreSQL client to run seeds automatically" -ForegroundColor Cyan
    Write-Host "   Download from: https://www.postgresql.org/download/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📋 For now, use Option 3 (Dashboard) above to run the seed manually." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
