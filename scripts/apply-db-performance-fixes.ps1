# Apply Database Performance Fixes to Supabase
# This script applies migration 020 to fix all performance issues

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectRef = "",
    
    [Parameter(Mandatory=$false)]
    [string]$DbPassword = ""
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Supabase Performance Fixes - Migration 020  " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Supabase CLI is available
$supabaseCli = Get-Command supabase -ErrorAction SilentlyContinue

if (-not $supabaseCli) {
    Write-Host "❌ Supabase CLI not found in PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "1. Install Supabase CLI: " -ForegroundColor White
    Write-Host "   scoop install supabase" -ForegroundColor Gray
    Write-Host "   # or #" -ForegroundColor Gray
    Write-Host "   npm install -g supabase" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Apply migration manually via Supabase Dashboard:" -ForegroundColor White
    Write-Host "   - Go to https://supabase.com/dashboard/project/$ProjectRef/sql/new" -ForegroundColor Gray
    Write-Host "   - Copy contents of supabase/migrations/020_comprehensive_performance_fixes.sql" -ForegroundColor Gray
    Write-Host "   - Run the SQL query" -ForegroundColor Gray
    exit 1
}

Write-Host "✅ Supabase CLI found" -ForegroundColor Green
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "supabase\migrations\020_comprehensive_performance_fixes.sql")) {
    Write-Host "❌ Migration file not found" -ForegroundColor Red
    Write-Host "   Please run this script from the project root directory" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Migration file found" -ForegroundColor Green
Write-Host ""

# Show what this migration does
Write-Host "This migration will:" -ForegroundColor Cyan
Write-Host "  [*] Fix 14 RLS policies with auth.uid() performance issues" -ForegroundColor White
Write-Host "  [*] Consolidate 4 multiple permissive policies" -ForegroundColor White
Write-Host "  [*] Add 10 missing foreign key indexes" -ForegroundColor White
Write-Host "  [*] Remove 18 unused indexes" -ForegroundColor White
Write-Host "  [*] Keep 22 strategic indexes for future features" -ForegroundColor White
Write-Host ""

# Ask for confirmation
$confirm = Read-Host "Apply migration to Supabase? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "❌ Migration cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Applying migration..." -ForegroundColor Cyan

# Try to apply the migration
try {
    # Check if local Supabase is running
    $localRunning = docker ps --filter "name=supabase" --format "{{.Names}}" 2>$null
    
    if ($localRunning) {
        Write-Host "📍 Detected local Supabase instance" -ForegroundColor Yellow
        supabase db push
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Migration applied successfully to local Supabase!" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "❌ Migration failed" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "📍 No local Supabase detected" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To apply to production, run:" -ForegroundColor Cyan
        Write-Host "  supabase db push --db-url postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Or apply via Supabase Dashboard:" -ForegroundColor Cyan
        Write-Host "  https://supabase.com/dashboard/project/[YOUR-PROJECT-REF]/sql/new" -ForegroundColor Gray
    }
} catch {
    Write-Host ""
    Write-Host "❌ Error applying migration: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Next Steps                                  " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Verify migration in Supabase Dashboard:" -ForegroundColor White
Write-Host "   - Check Database >> Migrations" -ForegroundColor Gray
Write-Host "   - Run Database Linter to verify fixes" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Test your app to ensure everything works" -ForegroundColor White
Write-Host ""
Write-Host "3. Monitor query performance" -ForegroundColor White
Write-Host "   - Check Database >> Query Performance" -ForegroundColor Gray
Write-Host ""

