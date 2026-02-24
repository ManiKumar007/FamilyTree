# Manually Confirm User Email in Supabase
# This script bypasses email verification for development

param(
    [string]$Email = "chinni070707@gmail.com"
)

Write-Host ""
Write-Host "Supabase Email Confirmation Tool" -ForegroundColor Cyan
Write-Host ""

# Load environment variables
$envFile = "backend\.env"
if (-not (Test-Path $envFile)) {
    Write-Host "Error: $envFile not found" -ForegroundColor Red
    exit 1
}

$envVars = @{}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        $envVars[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$supabaseUrl = $envVars['SUPABASE_URL']
$serviceRoleKey = $envVars['SUPABASE_SERVICE_ROLE_KEY']

if (-not $supabaseUrl -or -not $serviceRoleKey) {
    Write-Host "Error: Missing Supabase credentials in $envFile" -ForegroundColor Red
    exit 1
}

Write-Host "Loaded Supabase configuration" -ForegroundColor Green
Write-Host "  URL: $supabaseUrl" -ForegroundColor Gray
Write-Host "  Target Email: $Email" -ForegroundColor Gray
Write-Host ""

# Step 1: Get user by email
Write-Host "Looking up user..." -ForegroundColor Yellow

$headers = @{
    "apikey" = $serviceRoleKey
    "Authorization" = "Bearer $serviceRoleKey"
    "Content-Type" = "application/json"
}

try {
    # List users and find by email
    $usersResponse = Invoke-RestMethod -Uri "$supabaseUrl/auth/v1/admin/users" -Method GET -Headers $headers
    
    $user = $usersResponse.users | Where-Object { $_.email -eq $Email } | Select-Object -First 1
    
    if (-not $user) {
        Write-Host "User not found: $Email" -ForegroundColor Red
        Write-Host ""
        Write-Host "Available users:" -ForegroundColor Gray
        $usersResponse.users | ForEach-Object { Write-Host "  - $($_.email)" -ForegroundColor Gray }
        exit 1
    }
    
    Write-Host "Found user: $($user.email)" -ForegroundColor Green
    Write-Host "  User ID: $($user.id)" -ForegroundColor Gray
    Write-Host "  Created: $($user.created_at)" -ForegroundColor Gray
    Write-Host "  Email Confirmed: $($user.email_confirmed_at -ne $null)" -ForegroundColor Gray
    
    if ($user.email_confirmed_at) {
        Write-Host ""
        Write-Host "Email already confirmed!" -ForegroundColor Green
        Write-Host "You can now sign in with this account." -ForegroundColor White
        Write-Host ""
        exit 0
    }
    
    # Step 2: Confirm email
    Write-Host ""
    Write-Host "Confirming email..." -ForegroundColor Yellow
    
    $updateBody = @{
        email_confirm = $true
    } | ConvertTo-Json
    
    $updateResponse = Invoke-RestMethod `
        -Uri "$supabaseUrl/auth/v1/admin/users/$($user.id)" `
        -Method PUT `
        -Headers $headers `
        -Body $updateBody
    
    Write-Host "Email confirmed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Updated User Details:" -ForegroundColor Cyan
    Write-Host "  Email: $($updateResponse.email)" -ForegroundColor White
    Write-Host "  ID: $($updateResponse.id)" -ForegroundColor Gray
    $confirmStatus = if ($updateResponse.email_confirmed_at) { "Yes" } else { "No" }
    Write-Host "  Email Confirmed: $confirmStatus" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now sign in at: http://localhost:5500" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails) {
        $errorMsg = $_.ErrorDetails.Message
        Write-Host "Details: $errorMsg" -ForegroundColor Red
    }
    exit 1
}
