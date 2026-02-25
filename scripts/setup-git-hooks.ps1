#!/usr/bin/env pwsh
# ============================================================================
# Setup Git Pre-Commit Hook
# ============================================================================
# This installs a pre-commit hook that runs the same validation as GitHub CI
# to catch build errors before pushing to GitHub.
# ============================================================================

Write-Host "Installing pre-commit hook..." -ForegroundColor Cyan

$hookSource = "scripts\pre-commit.ps1"
$hookDest = ".git\hooks\pre-commit"

if (-not (Test-Path $hookSource)) {
    Write-Host "❌ Error: $hookSource not found!" -ForegroundColor Red
    Write-Host "   Make sure you're in the project root directory." -ForegroundColor Yellow
    exit 1
}

# Copy the PowerShell script
Copy-Item $hookSource $hookDest -Force

# Git hooks on Windows can be PowerShell scripts or bash scripts
# We'll create a wrapper that calls PowerShell
$wrapper = @"
#!/bin/sh
# Git hook wrapper for PowerShell pre-commit script
pwsh.exe .git/hooks/pre-commit 2>&1
"@

# Also create a bash wrapper for Git Bash users
Set-Content -Path "$hookDest.sh" -Value $wrapper -NoNewline

Write-Host "Pre-commit hook installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "What happens now:" -ForegroundColor Cyan
Write-Host "  - Every time you commit, Git will run validation checks" -ForegroundColor Gray
Write-Host "  - Flutter analyze (if .dart files changed)" -ForegroundColor Gray
Write-Host "  - TypeScript compile check (if backend files changed)" -ForegroundColor Gray
Write-Host "  - Same checks that run in GitHub CI" -ForegroundColor Gray
Write-Host ""
Write-Host "To skip the hook (not recommended):" -ForegroundColor Yellow
Write-Host "  git commit --no-verify" -ForegroundColor Gray
Write-Host ""
Write-Host "To test the hook manually:" -ForegroundColor Yellow
Write-Host "  pwsh scripts\pre-commit.ps1" -ForegroundColor Gray
