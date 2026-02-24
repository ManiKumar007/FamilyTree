# Update VS Code settings.json with Supabase MCP configuration

$settingsPath = "$env:APPDATA\Code\User\settings.json"

Write-Host "`nUpdating VS Code settings with Supabase MCP..." -ForegroundColor Cyan
Write-Host "Settings path: $settingsPath`n" -ForegroundColor Gray

# Ensure file exists
if (-not (Test-Path $settingsPath)) {
    Write-Host "Creating new settings.json file..." -ForegroundColor Yellow
    New-Item -Path (Split-Path $settingsPath) -ItemType Directory -Force | Out-Null
    "{}" | Out-File -FilePath $settingsPath -Encoding UTF8
}

# Read current settings
$content = Get-Content $settingsPath -Raw

# Parse JSON manually to avoid -AsHashtable issue in older PowerShell
if ([string]::IsNullOrWhiteSpace($content)) {
    $content = "{}"
}

# Check if MCP is already configured
if ($content -match '"github\.copilot\.chat\.mcp"') {
    Write-Host "⚠ MCP configuration already exists in settings.json" -ForegroundColor Yellow
    Write-Host "Please manually add or update the Supabase server configuration.`n" -ForegroundColor Yellow
} else {
    # Add MCP configuration before the last closing brace
    $mcpConfig = @"
  "github.copilot.chat.mcp.enabled": true,
  "github.copilot.chat.mcp.servers": {
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp?project_ref=vojwwcolmnbzogsrmwap"
    }
  }
"@

    # Handle empty settings file
    if ($content.Trim() -eq "{}") {
        $newContent = "{`n$mcpConfig`n}"
    } else {
        # Remove trailing } and add MCP config
        $content = $content.TrimEnd()
        if ($content.EndsWith("}")) {
            $content = $content.Substring(0, $content.Length - 1).TrimEnd()
            if ($content.EndsWith(",")) {
                $newContent = $content + "`n$mcpConfig`n}"
            } else {
                $newContent = $content + ",`n$mcpConfig`n}"
            }
        }
    }

    # Write updated settings
    $newContent | Out-File -FilePath $settingsPath -Encoding UTF8 -NoNewline
    
    Write-Host "✅ Supabase MCP configuration added successfully!`n" -ForegroundColor Green
}

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Reload VS Code window:" -ForegroundColor White
Write-Host "   Press Ctrl+Shift+P -> Type 'Reload Window' -> Select 'Developer: Reload Window'" -ForegroundColor Gray
Write-Host "2. After reload, Supabase MCP tools will be available in Copilot Chat!" -ForegroundColor Green
