# Cloudflare Worker Proxy Setup Helper
# This script helps deploy and verify Cloudflare Worker proxy for Supabase

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

function Write-Header {
    param([string]$Text)
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Text)
    Write-Host "✓ $Text" -ForegroundColor Green
}

function Write-Error {
    param([string]$Text)
    Write-Host "✗ $Text" -ForegroundColor Red
}

function Write-Info {
    param([string]$Text)
    Write-Host "ℹ $Text" -ForegroundColor Cyan
}

function Write-Warning {
    param([string]$Text)
    Write-Host "⚠ $Text" -ForegroundColor Yellow
}

# Install Wrangler
function Install-Wrangler {
    Write-Header "Installing Cloudflare Wrangler CLI"
    
    Write-Info "Checking if Wrangler is installed..."
    $wrangler = npm list -g wrangler 2>&1 | Select-String "wrangler"
    
    if ($wrangler) {
        Write-Success "Wrangler is already installed"
        return
    }
    
    Write-Info "Installing wrangler globally..."
    npm install -g wrangler
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Wrangler installed successfully"
    }
    else {
        Write-Error "Failed to install Wrangler"
        exit 1
    }
}

# Authenticate with Cloudflare
function Authenticate-Cloudflare {
    Write-Header "Authenticating with Cloudflare"
    
    Write-Info "Opening Cloudflare authentication..."
    wrangler auth
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Authentication successful"
    }
    else {
        Write-Error "Authentication failed"
        exit 1
    }
}

# Deploy Worker
function Deploy-Worker {
    param([string]$Environment = "production")
    
    Write-Header "Deploying Cloudflare Worker"
    
    if (-not (Test-Path "cloudflare-worker")) {
        Write-Error "cloudflare-worker directory not found"
        exit 1
    }
    
    Push-Location "cloudflare-worker"
    
    Write-Info "Installing dependencies..."
    npm install
    
    Write-Info "Deploying to $Environment..."
    
    if ($Environment -eq "staging") {
        npm run deploy:staging
    }
    else {
        npm run deploy:production
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Worker deployed successfully"
        Write-Info "Check your Cloudflare dashboard for the worker URL"
    }
    else {
        Write-Error "Deployment failed"
        Pop-Location
        exit 1
    }
    
    Pop-Location
}

# Test Proxy
function Test-Proxy {
    param([string]$ProxyUrl, [string]$AnonKey)
    
    Write-Header "Testing Cloudflare Proxy"
    
    if (-not $ProxyUrl) {
        Write-Error "Proxy URL is required"
        return $false
    }
    
    if (-not $AnonKey) {
        Write-Error "Anon key is required"
        return $false
    }
    
    Write-Info "Testing proxy: $ProxyUrl"
    
    try {
        $testUrl = "$ProxyUrl/rest/v1/users?limit=1"
        $headers = @{
            "Authorization" = "Bearer $AnonKey"
            "Content-Type"  = "application/json"
        }
        
        $response = Invoke-WebRequest -Uri $testUrl -Headers $headers -TimeoutSec 10 -ErrorAction Continue
        
        if ($response.StatusCode -eq 200) {
            Write-Success "Proxy test successful"
            Write-Info "Response: $($response.Content.Substring(0, 100))..."
            return $true
        }
        else {
            Write-Error "Proxy returned status $($response.StatusCode)"
            return $false
        }
    }
    catch {
        Write-Error "Proxy test failed: $($_.Exception.Message)"
        return $false
    }
}

# Check Dependencies
function Check-Dependencies {
    Write-Header "Checking Dependencies"
    
    $dependencies = @("node", "npm", "git")
    
    foreach ($dep in $dependencies) {
        if (Get-Command $dep -ErrorAction SilentlyContinue) {
            Write-Success "$dep is installed"
        }
        else {
            Write-Error "$dep is not installed or not in PATH"
            Write-Info "Please install $dep and try again"
            exit 1
        }
    }
}

# Setup Environment
function Setup-Environment {
    Write-Header "Setting up Environment Variables"
    
    $envFile = "cloudflare-worker\.env"
    $exampleFile = "cloudflare-worker\.env.example"
    
    if (-not (Test-Path $envFile) -and (Test-Path $exampleFile)) {
        Write-Info "Creating .env file from template..."
        Copy-Item $exampleFile $envFile
        Write-Success ".env file created"
        Write-Info "Please edit the .env file with your Cloudflare credentials"
    }
}

# Main Menu
function Show-Menu {
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "Cloudflare Worker Proxy Setup" -ForegroundColor Cyan
    Write-Host "1. Check dependencies" -ForegroundColor White
    Write-Host "2. Install Wrangler CLI" -ForegroundColor White
    Write-Host "3. Authenticate with Cloudflare" -ForegroundColor White
    Write-Host "4. Deploy Worker (Production)" -ForegroundColor White
    Write-Host "5. Deploy Worker (Staging)" -ForegroundColor White
    Write-Host "6. Test Proxy Connection" -ForegroundColor White
    Write-Host "7. Setup Environment" -ForegroundColor White
    Write-Host "8. Run All Setup Steps" -ForegroundColor White
    Write-Host "9. Exit" -ForegroundColor White
    Write-Host "" -ForegroundColor White
}

# Main execution
if ($Arguments.Count -eq 0) {
    # Interactive mode
    do {
        Show-Menu
        $choice = Read-Host "Select an option [1-9]"
        
        switch ($choice) {
            "1" { Check-Dependencies }
            "2" { Install-Wrangler }
            "3" { Authenticate-Cloudflare }
            "4" { Deploy-Worker "production" }
            "5" { Deploy-Worker "staging" }
            "6" {
                $proxyUrl = Read-Host "Enter Proxy URL (e.g., https://familytree-supabase-proxy.your-subdomain.workers.dev)"
                $anonKey = Read-Host "Enter Supabase Anon Key"
                Test-Proxy $proxyUrl $anonKey
            }
            "7" { Setup-Environment }
            "8" {
                Check-Dependencies
                Install-Wrangler
                Authenticate-Cloudflare
                Setup-Environment
                Deploy-Worker "production"
                Write-Header "Setup Complete"
                Write-Success "Cloudflare Worker deployed successfully"
                Write-Info "Next steps:"
                Write-Info "1. Note the worker URL from deployment output"
                Write-Info "2. Update SUPABASE_PROXY_URL in backend .env"
                Write-Info "3. Run: node scripts/verify-proxy.js"
            }
            "9" { 
                Write-Info "Exiting..."
                exit 0
            }
            default { Write-Warning "Invalid option. Please try again." }
        }
    } while ($choice -ne "9")
}
else {
    # Command mode
    $command = $Arguments[0]
    switch ($command) {
        "check" { Check-Dependencies }
        "install" { Install-Wrangler }
        "auth" { Authenticate-Cloudflare }
        "deploy" { 
            $env = if ($Arguments.Count -gt 1) { $Arguments[1] } else { "production" }
            Deploy-Worker $env
        }
        "test" {
            if ($Arguments.Count -lt 3) {
                Write-Error "Usage: deploy-proxy.ps1 test <proxy-url> <anon-key>"
                exit 1
            }
            Test-Proxy $Arguments[1] $Arguments[2]
        }
        "setup" { Setup-Environment }
        default { Write-Error "Unknown command: $command" }
    }
}
