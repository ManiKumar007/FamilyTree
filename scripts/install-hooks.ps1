# Install Pre-Commit Hook
# Copies the pre-commit hook to .git/hooks so it runs automatically before every commit

$hookSource = "$PSScriptRoot\pre-commit"
$hookDest = "$PSScriptRoot\..\.git\hooks\pre-commit"

if (Test-Path $hookSource) {
    Copy-Item -Path $hookSource -Destination $hookDest -Force
    Write-Host "✅ Pre-commit hook installed successfully!" -ForegroundColor Green
    Write-Host "   It will validate Flutter & backend builds before each commit." -ForegroundColor Cyan
}
else {
    Write-Host "❌ pre-commit script not found at $hookSource" -ForegroundColor Red
}
