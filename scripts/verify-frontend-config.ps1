# Verify Frontend Configuration Script
Write-Host "Verifying Frontend Configuration..." -ForegroundColor Cyan
Write-Host ""

$envFile = "app\.env"

if (-not (Test-Path $envFile)) {
    Write-Host "❌ Error: .env file not found at $envFile" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Found .env file" -ForegroundColor Green
Write-Host ""
Write-Host "Environment Variables:" -ForegroundColor Cyan

$envContent = Get-Content $envFile | Where-Object { $_ -match '^\s*[^#]' -and $_ -match '=' }

foreach ($line in $envContent) {
    $parts = $line -split '=', 2
    $key = $parts[0].Trim()
    $value = $parts[1].Trim()
    
    if ($key -match 'KEY|TOKEN|SECRET') {
        # Mask sensitive values
        $maskedValue = $value.Substring(0, [Math]::Min(20, $value.Length)) + "..."
        Write-Host "  $key = $maskedValue" -ForegroundColor Yellow
    } else {
        Write-Host "  $key = $value" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "Testing Supabase connectivity..." -ForegroundColor Cyan

$supabaseUrl = ($envContent | Where-Object { $_ -match '^SUPABASE_URL=' }) -replace 'SUPABASE_URL=', ''

if ($supabaseUrl) {
    try {
        $response = Invoke-WebRequest -Uri "$supabaseUrl/rest/v1/" -Method GET -TimeoutSec 5 -ErrorAction Stop
        Write-Host "✅ Supabase is reachable (Status: $($response.StatusCode))" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to reach Supabase: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   URL tested: $supabaseUrl/rest/v1/" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ SUPABASE_URL not found in .env" -ForegroundColor Red
}

Write-Host ""
Write-Host "Configuration check complete!" -ForegroundColor Cyan
