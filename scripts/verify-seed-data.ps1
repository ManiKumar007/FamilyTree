# Verify Seed Data Script
Write-Host "Verifying MyFamilyTree Seed Data..." -ForegroundColor Cyan
Write-Host ""

# Check backend
try {
    $health = Invoke-WebRequest -Uri "http://localhost:3000/api/health" -UseBasicParsing -ErrorAction Stop
    Write-Host "Backend Status: Running" -ForegroundColor Green
}
catch {
    Write-Host "Backend Status: Not Running" -ForegroundColor Red
    Write-Host "Start backend with: .\start-backend.ps1" -ForegroundColor Yellow
    exit 1
}

# Check profile
Write-Host "`nChecking Main User Profile..." -ForegroundColor Yellow
try {
    $profile = Invoke-WebRequest -Uri "http://localhost:3000/api/persons/me/profile" -UseBasicParsing | ConvertFrom-Json
    Write-Host "Profile Found: $($profile.name)" -ForegroundColor Green
    Write-Host "  Email: $($profile.email)" -ForegroundColor Gray
    Write-Host "  Phone: $($profile.phone)" -ForegroundColor Gray
}
catch {
    Write-Host "Profile: Not Found" -ForegroundColor Red
}

# Check tree
Write-Host "`nChecking Family Tree..." -ForegroundColor Yellow
try {
    $tree = Invoke-WebRequest -Uri "http://localhost:3000/api/tree" -UseBasicParsing | ConvertFrom-Json
    Write-Host "Total Persons: $($tree.persons.Count)" -ForegroundColor Green
    Write-Host "Total Relationships: $($tree.relationships.Count)" -ForegroundColor Green
    
    Write-Host "`nFamily Members:" -ForegroundColor Cyan
    $tree.persons | Sort-Object name | ForEach-Object {
        Write-Host "  - $($_.name) ($($_.gender))" -ForegroundColor Gray
    }
}
catch {
    Write-Host "Failed to retrieve tree" -ForegroundColor Red
}

# Check search
Write-Host "`nTesting Search..." -ForegroundColor Yellow
try {
    $results = Invoke-WebRequest -Uri "http://localhost:3000/api/search?q=Kumar" -UseBasicParsing | ConvertFrom-Json
    Write-Host "Search Results: $($results.Count) found" -ForegroundColor Green
}
catch {
    Write-Host "Search Failed" -ForegroundColor Red
}

Write-Host "`nVerification Complete!" -ForegroundColor Green
