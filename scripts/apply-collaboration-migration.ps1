# Apply Collaboration Migration (021) to Supabase
# Adds tree sharing and collaboration features

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectRef = "",
    
    [Parameter(Mandatory=$false)]
    [string]$DbPassword = ""
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Collaboration Migration - 021               " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if migration file exists
$migrationFile = "supabase\migrations\021_collaboration_tables.sql"

if (-not (Test-Path $migrationFile)) {
    Write-Host "❌ Migration file not found: $migrationFile" -ForegroundColor Red
    Write-Host "   Please run this script from the project root directory" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Migration file found" -ForegroundColor Green
Write-Host ""

# Show what this migration does
Write-Host "This migration will add:" -ForegroundColor Cyan
Write-Host "  [+] tree_collaborators table - Manage who has access to your tree" -ForegroundColor White
Write-Host "  [+] tree_invitations table - Send invitations via email/phone" -ForegroundColor White
Write-Host "  [+] user_active_tree table - Track which tree user is viewing" -ForegroundColor White
Write-Host "  [+] Permission levels: Admin, Editor, Viewer" -ForegroundColor White
Write-Host "  [+] Helper functions for permission checking" -ForegroundColor White
Write-Host "  [+] Auto-accept invitations when users sign up" -ForegroundColor White
Write-Host "  [+] RLS policies for secure access" -ForegroundColor White
Write-Host ""

# Check for required .env variables
if (-not (Test-Path ".env")) {
    Write-Host "⚠️  .env file not found - will need database credentials" -ForegroundColor Yellow
    Write-Host ""
}

# Check if Supabase CLI is available
$supabaseCli = Get-Command supabase -ErrorAction SilentlyContinue

if (-not $supabaseCli) {
    Write-Host "❌ Supabase CLI not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Options to apply this migration:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1: Install Supabase CLI" -ForegroundColor Cyan
    Write-Host "  scoop install supabase" -ForegroundColor Gray
    Write-Host "  # or" -ForegroundColor Gray
    Write-Host "  npm install -g supabase" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Option 2: Apply manually via Supabase Dashboard" -ForegroundColor Cyan
    Write-Host "  1. Go to: https://supabase.com/dashboard" -ForegroundColor Gray
    Write-Host "  2. Navigate to: SQL Editor" -ForegroundColor Gray
    Write-Host "  3. Copy contents of: $migrationFile" -ForegroundColor Gray
    Write-Host "  4. Paste and click 'Run'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Option 3: Use psql directly" -ForegroundColor Cyan
    Write-Host "  psql postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres -f $migrationFile" -ForegroundColor Gray
    Write-Host ""
    
    # Ask if user wants to copy SQL to clipboard
    if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
        $copyToClipboard = Read-Host "Copy SQL to clipboard for manual application? (y/n)"
        if ($copyToClipboard -eq 'y') {
            Get-Content $migrationFile -Raw | Set-Clipboard
            Write-Host "✅ SQL copied to clipboard!" -ForegroundColor Green
            Write-Host "   Paste it in Supabase Dashboard SQL Editor" -ForegroundColor Gray
        }
    }
    
    exit 1
}

Write-Host "✅ Supabase CLI found" -ForegroundColor Green
Write-Host ""

# Ask for confirmation
$confirm = Read-Host "Apply collaboration migration to Supabase? (y/n)"
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
        Write-Host "   Running: supabase db push" -ForegroundColor Gray
        Write-Host ""
        
        supabase db push
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Migration 021 applied successfully to local Supabase!" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "❌ Migration failed" -ForegroundColor Red
            Write-Host "   Check error messages above" -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "📍 No local Supabase detected" -ForegroundColor Yellow
        Write-Host ""
        
        # Check if we have project credentials
        if ($ProjectRef -and $DbPassword) {
            Write-Host "Applying to production database..." -ForegroundColor Cyan
            
            $dbUrl = "postgresql://postgres:$DbPassword@db.$ProjectRef.supabase.co:5432/postgres"
            supabase db push --db-url $dbUrl
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host ""
                Write-Host "✅ Migration applied to production!" -ForegroundColor Green
            } else {
                Write-Host ""
                Write-Host "❌ Migration failed" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "To apply to production, run:" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  supabase db push --db-url postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" -ForegroundColor Gray
            Write-Host ""
            Write-Host "Or apply via Supabase Dashboard:" -ForegroundColor Cyan
            Write-Host "  https://supabase.com/dashboard/project/[PROJECT-REF]/sql/new" -ForegroundColor Gray
            Write-Host ""
            
            # Offer to copy SQL
            if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
                $copyToClipboard = Read-Host "Copy SQL to clipboard for manual application? (y/n)"
                if ($copyToClipboard -eq 'y') {
                    Get-Content $migrationFile -Raw | Set-Clipboard
                    Write-Host "✅ SQL copied to clipboard!" -ForegroundColor Green
                }
            }
        }
    }
} catch {
    Write-Host ""
    Write-Host "❌ Error applying migration: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Try applying manually via Supabase Dashboard:" -ForegroundColor Yellow
    Write-Host "  https://supabase.com/dashboard" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Next Steps                                  " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Backend API Implementation" -ForegroundColor White
Write-Host "   Implement these endpoints:" -ForegroundColor Gray
Write-Host "   - GET  /api/tree/collaborators" -ForegroundColor Gray
Write-Host "   - POST /api/tree/share" -ForegroundColor Gray
Write-Host "   - PUT  /api/tree/collaborators/:userId" -ForegroundColor Gray
Write-Host "   - DELETE /api/tree/collaborators/:userId" -ForegroundColor Gray
Write-Host "   - GET  /api/tree/invitations/pending" -ForegroundColor Gray
Write-Host "   - POST /api/tree/invitations/:id/accept" -ForegroundColor Gray
Write-Host "   - GET  /api/tree/shared-with-me" -ForegroundColor Gray
Write-Host "   - POST /api/tree/switch/:treeId" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Test Collaboration Feature" -ForegroundColor White
Write-Host "   - Navigate to /collaboration route" -ForegroundColor Gray
Write-Host "   - Try sharing your tree with test email" -ForegroundColor Gray
Write-Host "   - Verify permission levels work correctly" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Frontend Already Done! ✅" -ForegroundColor Green
Write-Host "   - Collaboration screen created" -ForegroundColor Gray
Write-Host "   - Service layer implemented" -ForegroundColor Gray
Write-Host "   - Routes configured" -ForegroundColor Gray
Write-Host ""
Write-Host "Documentation: doc/NEW_FEATURES_IMPLEMENTATION.md" -ForegroundColor Cyan
Write-Host ""
