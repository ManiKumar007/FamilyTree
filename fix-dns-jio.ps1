# Quick DNS fix for Jio blocking Supabase
# This changes your DNS to Google DNS (8.8.8.8, 8.8.4.4)

Write-Host "`n=== FIXING JIO BLOCKING ISSUE ===" -ForegroundColor Cyan
Write-Host "Changing DNS to Google DNS to bypass ISP restrictions...`n" -ForegroundColor Yellow

# Get active network adapter
$adapter = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1

if ($adapter) {
    Write-Host "Active adapter: $($adapter.Name)" -ForegroundColor White
    
    # Set Google DNS
    try {
        Write-Host "Setting DNS servers..." -ForegroundColor Cyan
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("8.8.8.8", "8.8.4.4")
        Write-Host "✓ DNS changed to Google DNS (8.8.8.8, 8.8.4.4)" -ForegroundColor Green
        
        # Flush DNS cache
        Write-Host "`nFlushing DNS cache..." -ForegroundColor Cyan
        Clear-DnsClientCache
        Write-Host "✓ DNS cache cleared" -ForegroundColor Green
        
        Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host "  DNS FIX APPLIED SUCCESSFULLY" -ForegroundColor Green
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
        
        Write-Host "Now testing Supabase connection...`n" -ForegroundColor Yellow
        
        Start-Sleep -Seconds 2
        
        # Test connection
        try {
            $response = Invoke-WebRequest -Uri "https://vojwwcolmnbzogsrmwap.supabase.co/auth/v1/health" -TimeoutSec 10 -UseBasicParsing
            Write-Host "✓ SUCCESS! Supabase is now accessible!" -ForegroundColor Green
            Write-Host "  Status: $($response.StatusCode)" -ForegroundColor White
            Write-Host "`nYou can now use your app!`n" -ForegroundColor Yellow
        }
        catch {
            Write-Host "✗ Supabase still not accessible" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)`n" -ForegroundColor Red
            Write-Host "DNS change alone won't work." -ForegroundColor Yellow
            Write-Host "You MUST use VPN to bypass Jio blocking.`n" -ForegroundColor Yellow
            Write-Host "VPN Options:" -ForegroundColor Cyan
            Write-Host "  • ProtonVPN (free): https://protonvpn.com/download" -ForegroundColor White
            Write-Host "  • Cloudflare WARP: https://1.1.1.1/`n" -ForegroundColor White
        }
        
    }
    catch {
        Write-Host "✗ Failed to change DNS: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nTry running PowerShell as Administrator`n" -ForegroundColor Yellow
    }
}
else {
    Write-Host "✗ No active network adapter found" -ForegroundColor Red
}
