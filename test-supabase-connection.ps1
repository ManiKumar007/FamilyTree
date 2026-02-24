# Quick Network Test for Supabase Connectivity
# Run this to verify if Supabase is accessible from your current network

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  SUPABASE CONNECTION TEST" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan

$supabaseUrl = "vojwwcolmnbzogsrmwap.supabase.co"

Write-Host "Testing connection to: $supabaseUrl`n" -ForegroundColor Yellow

# Test 1: DNS Resolution
Write-Host "[1/3] DNS Resolution..." -ForegroundColor Cyan
$dnsOk = $false
try {
    $dns = Resolve-DnsName -Name $supabaseUrl -ErrorAction Stop
    Write-Host "  ✓ DNS OK - IP: $($dns[0].IPAddress)" -ForegroundColor Green
    $dnsOk = $true
}
catch {
    Write-Host "  ✗ DNS FAILED" -ForegroundColor Red
}

# Test 2: Port 443 Connectivity
Write-Host "`n[2/3] Port 443 (HTTPS) Connectivity..." -ForegroundColor Cyan
$portOk = $false
$tcpTest = Test-NetConnection -ComputerName $supabaseUrl -Port 443 -WarningAction SilentlyContinue -InformationLevel Quiet
if ($tcpTest) {
    Write-Host "  ✓ Port 443 is OPEN" -ForegroundColor Green
    $portOk = $true
}
else {
    Write-Host "  ✗ Port 443 is BLOCKED" -ForegroundColor Red
    Write-Host "    → Corporate firewall is likely blocking Supabase" -ForegroundColor Yellow
}

# Test 3: HTTP Request
Write-Host "`n[3/3] HTTPS Request..." -ForegroundColor Cyan
$httpOk = $false
try {
    $response = Invoke-WebRequest -Uri "https://$supabaseUrl/auth/v1/health" -TimeoutSec 10 -UseBasicParsing
    Write-Host "  ✓ HTTP OK - Status: $($response.StatusCode)" -ForegroundColor Green
    $httpOk = $true
}
catch {
    Write-Host "  ✗ HTTP FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  RESULT" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan

if ($dnsOk -and $portOk -and $httpOk) {
    Write-Host "✓ ALL TESTS PASSED" -ForegroundColor Green
    Write-Host "  Supabase is accessible from this network.`n" -ForegroundColor White
}
else {
    Write-Host "✗ CONNECTION BLOCKED" -ForegroundColor Red
    Write-Host "`nYour app won't work on this network.`n" -ForegroundColor Yellow
    
    Write-Host "SOLUTIONS:" -ForegroundColor Cyan
    Write-Host "  1. Switch to mobile hotspot" -ForegroundColor White
    Write-Host "  2. Use home WiFi" -ForegroundColor White
    Write-Host "  3. Connect to VPN (if allowed)" -ForegroundColor White
    Write-Host "  4. Contact IT to whitelist *.supabase.co`n" -ForegroundColor White
    
    Write-Host "See NETWORK_TROUBLESHOOTING.md for details.`n" -ForegroundColor Yellow
}
