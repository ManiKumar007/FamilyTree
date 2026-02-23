# Render MCP Setup Guide

## What is the Render MCP?

The Render MCP (Model Context Protocol) allows you to interact with Render.com services programmatically through AI assistants like GitHub Copilot. It provides tools to create, manage, and monitor your Render deployments.

## 📋 Prerequisites

1. **Render.com Account** - [Sign up free](https://render.com)
2. **Render API Key** - Get from Render Dashboard
3. **VS Code with GitHub Copilot** (you already have this ✓)

## 🔑 Step 1: Get Your Render API Key

1. **Login to Render Dashboard**
   - Go to https://dashboard.render.com/

2. **Navigate to API Keys**
   - Click your profile (top right)
   - Select "Account Settings"
   - Click "API Keys" in the left sidebar

3. **Create New API Key**
   - Click "Create API Key"
   - Name: `FamilyTree Deployment`
   - Expiration: Choose (e.g., 1 year)
   - Click "Create"
   - **Copy the key immediately** (you won't see it again!)

4. **Save Your API Key**
   - Store it securely (password manager recommended)
   - Example key format: `rnd_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

## 🛠️ Step 2: Configure the Render MCP

The Render MCP needs to be configured in your VS Code settings. There are typically two ways to do this:

### Method A: VS Code Settings (Recommended)

1. **Open VS Code Settings**
   - Press `Ctrl+,` (Windows) or `Cmd+,` (Mac)
   - Or File → Preferences → Settings

2. **Search for "MCP" or "GitHub Copilot Chat MCP"**

3. **Add Render MCP Configuration**
   
   If you see an "MCP Servers" or "Chat: MCP Servers" setting:
   
   ```json
   {
     "github.copilot.chat.mcpServers": {
       "render": {
         "command": "npx",
         "args": ["-y", "@render/mcp-server"],
         "env": {
           "RENDER_API_KEY": "your_render_api_key_here"
         }
       }
     }
   }
   ```

### Method B: Configuration File

1. **Create MCP Configuration Directory**
   ```powershell
   # Windows
   mkdir $env:APPDATA\Code\User\globalStorage\github.copilot-chat\mcpServers
   ```

2. **Create Configuration File**
   
   Create: `%APPDATA%\Code\User\globalStorage\github.copilot-chat\mcpServers\render.json`
   
   ```json
   {
     "command": "npx",
     "args": ["-y", "@render/mcp-server"],
     "env": {
       "RENDER_API_KEY": "rnd_your_actual_api_key_here"
     }
   }
   ```

3. **Reload VS Code**
   - Press `Ctrl+Shift+P`
   - Type "Reload Window"
   - Press Enter

## 🔍 Step 3: Verify MCP is Available

After reloading VS Code:

1. **Open Copilot Chat** (if not already open)
   - Press `Ctrl+Shift+I` or click chat icon

2. **Ask Copilot to search for Render tools:**
   ```
   Search for render tools available
   ```

3. **Expected Response:**
   - You should see tools like:
     - `mcp_render_create_service`
     - `mcp_render_list_services`
     - `mcp_render_deploy`
     - `mcp_render_get_logs`
     - etc.

## 🚀 Step 4: Deploy Using MCP

Once the MCP is configured, you can use it to deploy:

### Example Commands in Copilot Chat:

**List existing services:**
```
List all my Render services
```

**Create backend service:**
```
Create a new Render web service:
- Name: familytree-backend
- Repo: https://github.com/ManiKumar007/FamilyTree
- Branch: master
- Build command: cd backend && npm install && npm run build
- Start command: cd backend && npm start
- Environment: Node
```

**Set environment variables:**
```
Set these environment variables for familytree-backend service:
- SUPABASE_URL=https://vojwwcolmnbzogsrmwap.supabase.co
- SUPABASE_SERVICE_ROLE_KEY=[your_key]
- SUPABASE_ANON_KEY=[your_key]
- NODE_ENV=production
- PORT=10000
```

**Create frontend static site:**
```
Create a Render static site:
- Name: familytree-web
- Repo: https://github.com/ManiKumar007/FamilyTree
- Branch: master
- Build command: [Flutter build command from render.yaml]
- Publish directory: public
```

**View logs:**
```
Show me the latest logs for familytree-backend
```

## 🎯 Alternative: Use Render Blueprint (Easier!)

If the MCP isn't working or you prefer a simpler approach:

1. **Use the Dashboard Method** (recommended for first deployment)
   - The `render.yaml` file I created makes this super easy
   - See [QUICK-DEPLOY.md](QUICK-DEPLOY.md) for steps

2. **After Initial Setup:**
   - Use MCP for monitoring and updates
   - Use dashboard for major changes

## 🔧 Troubleshooting MCP Setup

### MCP Not Loading

**Check VS Code Extensions:**
```powershell
code --list-extensions | Select-String "copilot"
```

You should see:
- `GitHub.copilot`
- `GitHub.copilot-chat`

**Verify API Key Format:**
- Should start with `rnd_`
- No quotes around the key in config
- No extra spaces

**Check MCP Server Process:**
```powershell
# Check if npx is available
npx --version

# Should show npm version (comes with Node.js)
```

### MCP Commands Not Working

**Reload Window:**
```
Ctrl+Shift+P → "Reload Window"
```

**Check Render API Key Permissions:**
- Go to Render Dashboard → Account Settings → API Keys
- Verify key is active and not expired

**View VS Code Logs:**
```
Ctrl+Shift+P → "Developer: Show Logs"
```

## 📚 Common MCP Commands for Render

Once configured, you can use these conversational commands in Copilot Chat:

### Service Management
- "Create a new web service on Render for my backend"
- "List all my Render services"
- "Delete the service named [service-name]"
- "Get details about familytree-backend service"

### Deployment
- "Deploy the latest commit to familytree-backend"
- "Trigger a manual deploy for my frontend"
- "Show deployment history for my services"

### Monitoring
- "Show me the logs for familytree-backend"
- "What's the status of my familytree-web service?"
- "Get the URL for my deployed frontend"

### Configuration
- "Add environment variable API_KEY=xyz to backend service"
- "Update the build command for my service"
- "Change the auto-deploy setting"

## 🆕 If Render MCP Doesn't Exist Yet

If the Render MCP package doesn't exist (or isn't publicly available), you have these options:

### Option 1: Use Render API Directly

Create a helper script that uses the Render API:

```javascript
// deploy-to-render.js
const axios = require('axios');

const RENDER_API_KEY = process.env.RENDER_API_KEY;
const API_BASE = 'https://api.render.com/v1';

async function createService(config) {
  const response = await axios.post(
    `${API_BASE}/services`,
    config,
    {
      headers: {
        'Authorization': `Bearer ${RENDER_API_KEY}`,
        'Content-Type': 'application/json'
      }
    }
  );
  return response.data;
}

// Usage
createService({
  type: 'web_service',
  name: 'familytree-backend',
  repo: 'https://github.com/ManiKumar007/FamilyTree',
  // ... more config
});
```

### Option 2: Use Render Dashboard

This is actually the **recommended approach** for most users:
- More visual and intuitive
- See [QUICK-DEPLOY.md](QUICK-DEPLOY.md)
- The `render.yaml` blueprint makes it one-click

### Option 3: Use Render CLI

Install Render CLI:
```powershell
npm install -g @render/cli

# Authenticate
render login

# Deploy using blueprint
render blueprint apply
```

## 📖 Documentation Links

- **Render API Docs**: https://api-docs.render.com/
- **Render Dashboard**: https://dashboard.render.com/
- **MCP Protocol**: https://modelcontextprotocol.io/
- **Render Support**: https://render.com/docs

## 🎯 Recommended Approach

For your FamilyTree app, I recommend:

1. **Initial Deploy**: Use Render Dashboard with `render.yaml` blueprint
   - Fastest and most reliable
   - Visual feedback
   - See [QUICK-DEPLOY.md](QUICK-DEPLOY.md)

2. **After Setup**: Use MCP for monitoring
   - Check logs
   - View deployment status
   - Quick updates

3. **Continuous Deployment**: Let GitHub auto-deploy
   - Every push to master triggers deploy
   - No manual intervention needed

## ⚡ Quick Start (No MCP Needed)

If you want to deploy **right now** without MCP:

```powershell
# 1. Run deployment check
.\deploy-check.ps1

# 2. Go to Render Dashboard
# https://dashboard.render.com/

# 3. New → Blueprint
# Connect: ManiKumar007/FamilyTree

# 4. Add environment variables
# (See QUICK-DEPLOY.md for values)

# 5. Click Apply
# ☕ Wait 15-20 minutes

# Done! 🎉
```

---

**Need help?** Ask in Copilot Chat:
- "How do I check if Render MCP is loaded?"
- "Show me available Render tools"
- "Help me deploy to Render"
