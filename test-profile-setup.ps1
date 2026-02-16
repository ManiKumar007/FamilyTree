# Test script to verify backend connection and auth flow
param(
    [string]$Email = "",
    [string]$Password = ""
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Profile Setup Test Script" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if backend is running
Write-Host "1. Checking if backend is running..." -ForegroundColor Yellow
try {
    $healthCheck = Invoke-RestMethod -Uri "http://localhost:3000/api/health" -Method Get -TimeoutSec 5
    Write-Host "   ✓ Backend is running" -ForegroundColor Green
    Write-Host "   Status: $($healthCheck.status)" -ForegroundColor Gray
}
catch {
    Write-Host "   ✗ Backend is NOT running!" -ForegroundColor Red
    Write-Host "   Please start the backend with: .\start-backend.ps1" -ForegroundColor Yellow
    exit 1
}

# If email and password provided, test login flow
if ($Email -and $Password) {
    Write-Host "`n2. Testing login with provided credentials..." -ForegroundColor Yellow
    
    # Load Supabase URL from .env
    $envFile = ".\app\.env"
    if (Test-Path $envFile) {
        $envContent = Get-Content $envFile
        $supabaseUrl = ($envContent | Where-Object { $_ -match "^SUPABASE_URL=" }) -replace "SUPABASE_URL=", ""
        $supabaseKey = ($envContent | Where-Object { $_ -match "^SUPABASE_ANON_KEY=" }) -replace "SUPABASE_ANON_KEY=", ""
        
        if ($supabaseUrl) {
            Write-Host "   Supabase URL: $supabaseUrl" -ForegroundColor Gray
            
            # Test sign in
            try {
                $loginBody = @{
                    email    = $Email
                    password = $Password
                } | ConvertTo-Json
                
                $authUrl = "$supabaseUrl/auth/v1/token?grant_type=password"
                $headers = @{
                    "apikey"       = $supabaseKey
                    "Content-Type" = "application/json"
                }
                
                $loginResponse = Invoke-RestMethod -Uri $authUrl -Method Post -Headers $headers -Body $loginBody
                
                Write-Host "   ✓ Login successful" -ForegroundColor Green
                Write-Host "   User ID: $($loginResponse.user.id)" -ForegroundColor Gray
                Write-Host "   Email: $($loginResponse.user.email)" -ForegroundColor Gray
                Write-Host "   Access Token Length: $($loginResponse.access_token.Length)" -ForegroundColor Gray
                
                # Test creating a profile with the token
                Write-Host "`n3. Testing profile creation..." -ForegroundColor Yellow
                
                $profileData = @{
                    name          = "Test User"
                    given_name    = "Test"
                    surname       = "User"
                    phone         = "+911234567890"
                    gender        = "male"
                    date_of_birth = "1990-01-01"
                    city          = "Test City"
                    state         = "Test State"
                    occupation    = "Tester"
                    email         = $Email
                    auth_user_id  = $loginResponse.user.id
                    verified      = $true
                } | ConvertTo-Json
                
                $apiHeaders = @{
                    "Authorization" = "Bearer $($loginResponse.access_token)"
                    "Content-Type"  = "application/json"
                }
                
                try {
                    $createResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/persons" -Method Post -Headers $apiHeaders -Body $profileData
                    Write-Host "   ✓ Profile creation successful" -ForegroundColor Green
                    Write-Host "   Person ID: $($createResponse.data.id)" -ForegroundColor Gray
                }
                catch {
                    $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
                    Write-Host "   ✗ Profile creation failed" -ForegroundColor Red
                    Write-Host "   Error: $($errorResponse.error)" -ForegroundColor Red
                    
                    # Check if it's a duplicate
                    if ($errorResponse.error -like "*already exists*") {
                        Write-Host "`n   ℹ A profile already exists for this user" -ForegroundColor Yellow
                        Write-Host "   This is expected if you already set up the profile" -ForegroundColor Yellow
                    }
                }
                
            }
            catch {
                Write-Host "   ✗ Login failed" -ForegroundColor Red
                Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        else {
            Write-Host "   ✗ Could not find SUPABASE_URL in .env file" -ForegroundColor Red
        }
    }
    else {
        Write-Host "   ✗ .env file not found at $envFile" -ForegroundColor Red
    }
}
else {
    Write-Host "`nℹ To test login flow, provide email and password:" -ForegroundColor Cyan
    Write-Host "  .\test-profile-setup.ps1 -Email <email> -Password <password>" -ForegroundColor Gray
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Test Complete" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan
