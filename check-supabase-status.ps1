# Quick check if Supabase project is alive
# Run this AFTER restoring your paused project

$url = "https://vojwwcolmnbzogsrmwap.supabase.co/auth/v1/health"

Write-Host "`nChecking Supabase project status..." -ForegroundColor Cyan
Write-Host "URL: $url`n" -ForegroundColor Gray

try {
    $response = Invoke-WebRequest -Uri $url -TimeoutSec 10 -UseBasicParsing
    
    Write-Host "✓ SUCCESS!" -ForegroundColor Green
    Write-Host "  Status Code: $($response.StatusCode)" -ForegroundColor White
    Write-Host "  Response: $($response.Content)" -ForegroundColor White
    Write-Host "`nYour Supabase project is ACTIVE and working!`n" -ForegroundColor Green
    Write-Host "You can now use your app.`n" -ForegroundColor Yellow
    
} catch {
    Write-Host "✗ FAILED" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)`n" -ForegroundColor Red
    
    if ($_.Exception.Message -match "timeout") {
        Write-Host "Project might still be waking up. Wait 1 more minute and try again.`n" -ForegroundColor Yellow
    } else {
        Write-Host "Project might still be paused. Check Supabase dashboard.`n" -ForegroundColor Yellow
    }
}
