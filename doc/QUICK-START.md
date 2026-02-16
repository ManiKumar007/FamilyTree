# MyFamilyTree - Quick Start Guide

## 🚀 Starting the Application

### Option 1: Start Everything at Once (Recommended)

Right-click on `start-all.ps1` and select **Run with PowerShell**

This will:

- ✅ Automatically kill any existing instances
- ✅ Start backend server (http://localhost:3000)
- ✅ Start Flutter app in Chrome
- ✅ Open in separate PowerShell windows so you can see logs

### Option 2: Start Services Individually

#### Backend Only:

Right-click on `start-backend.ps1` and select **Run with PowerShell**

#### Frontend Only:

**Choose based on your needs:**

- **`start-frontend.ps1`** - Debug mode (3+ min load, hot reload available)
- **`start-frontend-fast.ps1`** ⚡ - Profile mode (30-60 sec load, recommended)
- **`start-frontend-release.ps1`** 🚀 - Release mode (20-40 sec load, fastest)
- **`build-and-serve.ps1`** 💎 - Production build (2-5 sec page loads after initial build)

### 🛑 Stopping the Application

Right-click on `stop-all.ps1` and select **Run with PowerShell**

This will kill all Node.js and Flutter/Dart processes.

## 📝 What Each Script Does

| Script                       | Purpose                                              | Load Time      |
| ---------------------------- | ---------------------------------------------------- | -------------- |
| `start-all.ps1`              | Starts both backend and frontend in separate windows | 3+ min (debug) |
| `start-backend.ps1`          | Starts only the backend server                       | ~5 sec         |
| `start-frontend.ps1`         | Starts Flutter app in DEBUG mode (slow, hot reload)  | 3+ min         |
| `start-frontend-fast.ps1`    | Starts Flutter app in PROFILE mode ⚡                | 30-60 sec      |
| `start-frontend-release.ps1` | Starts Flutter app in RELEASE mode 🚀                | 20-40 sec      |
| `build-and-serve.ps1`        | Builds & serves production app 💎                    | 2-5 sec loads  |
| `stop-all.ps1`               | Stops all running instances                          | instant        |

## ⚡ Performance Comparison

| Mode              | Initial Load | Hot Reload | Debugging  | Best For            |
| ----------------- | ------------ | ---------- | ---------- | ------------------- |
| **Debug**         | 3-4 min      | ✅ Yes     | ✅ Full    | Finding bugs        |
| **Profile**       | 30-60 sec    | ✅ Yes     | ⚠️ Limited | Development         |
| **Release**       | 20-40 sec    | ❌ No      | ❌ No      | Testing performance |
| **Build & Serve** | 2-5 sec      | ❌ No      | ❌ No      | Final testing       |

**Recommendation:** Use `start-frontend-fast.ps1` for daily development!

## ⚡ Features

- **Auto-cleanup**: All scripts automatically detect and kill existing instances before starting
- **No conflicts**: Never worry about multiple instances running
- **Separate windows**: Each service runs in its own window so you can see logs
- **Color-coded output**: Easy to see what's happening

## 🔧 Manual Commands (if needed)

If you prefer to use the terminal:

```powershell
# Start everything (debug mode - slow)
.\start-all.ps1

# Start backend only
.\start-backend.ps1

# Start frontend (choose one):
.\start-frontend.ps1           # Debug: 3+ min, hot reload
.\start-frontend-fast.ps1      # Profile: 30-60 sec, hot reload (recommended)
.\start-frontend-release.ps1   # Release: 20-40 sec, no hot reload
.\build-and-serve.ps1          # Production: 2-5 sec loads

# Stop everything
.\stop-all.ps1
```

## 🌐 Access URLs

- **Backend API**: http://localhost:3000
- **Frontend**: Opens automatically in Chrome
- **Backend Health Check**: http://localhost:3000/api/health

## 💡 Tips

- The backend window shows API request logs
- The Flutter window shows hot-reload messages (press 'r' to hot reload)
- Keep both windows open to see real-time logs
- Use `stop-all.ps1` to cleanly shut down everything
- **For faster development**: Use `start-frontend-fast.ps1` instead of `start-frontend.ps1`
- **Hot reload trick**: After first load, make code changes and press 'r' in Flutter terminal - updates in 2-5 seconds!
- **Production testing**: Use `build-and-serve.ps1` to test final optimized version

## 🐛 Troubleshooting

**Problem**: "Cannot be loaded because running scripts is disabled"
**Solution**: Run this in PowerShell as Administrator:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Problem**: Port already in use
**Solution**: Run `stop-all.ps1` to kill all instances, then start again

**Problem**: App takes 3+ minutes to load
**Solution**: This is normal for debug mode. Use `start-frontend-fast.ps1` (30-60 sec) or `start-frontend-release.ps1` (20-40 sec) for faster loading

**Problem**: Need to test changes quickly
**Solution**: After app loads once, use hot reload (press 'r' in Flutter terminal) - changes apply in seconds!
