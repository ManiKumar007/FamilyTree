# Stop All Services Script
# Kills all Node.js and Flutter/Dart processes

Write-Host "=====================================" -ForegroundColor Red
Write-Host "  MyFamilyTree - Stop All Services" -ForegroundColor Red
Write-Host "=====================================" -ForegroundColor Red
Write-Host ""

Write-Host "Stopping all processes..." -ForegroundColor Yellow

$nodeProcesses = Get-Process -Name node -ErrorAction SilentlyContinue
$dartProcesses = Get-Process | Where-Object { $_.ProcessName -match 'dart|flutter' }

$totalProcesses = @($nodeProcesses; $dartProcesses).Count

if ($totalProcesses -gt 0) {
    Write-Host "Found $totalProcesses process(es) to stop:" -ForegroundColor Cyan
    
    if ($nodeProcesses) {
        Write-Host "  - Node.js: $($nodeProcesses.Count) process(es)" -ForegroundColor Gray
        $nodeProcesses | Stop-Process -Force
    }
    if ($dartProcesses) {
        Write-Host "  - Flutter/Dart: $($dartProcesses.Count) process(es)" -ForegroundColor Gray
        $dartProcesses | Stop-Process -Force
    }
    
    Write-Host ""
    Write-Host "All processes stopped successfully!" -ForegroundColor Green
} else {
    Write-Host "No running processes found." -ForegroundColor Gray
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
