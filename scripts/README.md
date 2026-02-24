# Scripts Directory

This directory contains all utility scripts for the FamilyTree project.

## 🚀 Start/Stop Scripts

- **start-all.ps1** - Start both backend and frontend together
- **start-backend.ps1** - Start the backend API server only
- **start-frontend.ps1** - Start the Flutter web frontend
- **start-frontend-fast.ps1** - Start frontend with fast refresh
- **start-frontend-release.ps1** - Start frontend in release mode
- **start-frontend-test.ps1** - Start frontend in test mode
- **start-android.ps1** - Start Android emulator and app
- **start-local.ps1** - Start local development environment
- **stop-all.ps1** - Stop all running services
- **quick-start.ps1** - Quick start script for development

## 🛠️ Build & Deploy Scripts

- **build-and-serve.ps1** - Build and serve the application
- **deploy-vercel.ps1** - Deploy to Vercel
- **deploy-check.ps1** - Check deployment status

## 🧪 Testing Scripts

- **run-tests.ps1** - Run all tests
- **run-flutter-tests.ps1** - Run Flutter widget/unit tests
- **run-integration-tests.ps1** - Run integration tests
- **test-api.ps1** - Test API endpoints
- **test-api-quick.bat** - Quick API test (batch file)
- **test-android-features.ps1** - Test Android-specific features
- **test-profile-setup.ps1** - Test profile setup flow
- **run-profile-setup-test.ps1** - Run profile setup integration test

## 💾 Database Scripts

- **run-migration.ps1** / **run-migration.js** - Run database migrations
- **seed-test-data.ps1** / **seed-test-data.js** - Seed test data into database
- **verify-seed-data.ps1** - Verify seeded data

## 🔧 Utility Scripts

- **check-backend-config.ps1** - Verify backend configuration
- **verify-frontend-config.ps1** - Verify frontend configuration
- **confirm-user-email.ps1** - Confirm user email in Supabase
- **grant-admin-access.ps1** - Grant admin access to users
- **diagnose-token.ps1** - Diagnose authentication token issues
- **update-service-key.ps1** - Update Supabase service key
- **fix-service-key.ps1** - Fix service key configuration issues
- **fix-test-person-constructors.ps1** - Fix test person constructors
- **update-vscode-mcp.ps1** - Update VS Code MCP configuration

## 📝 Usage

Most scripts can be run directly from the project root:

```powershell
# Start development environment
.\scripts\start-all.ps1

# Run tests
.\scripts\run-tests.ps1

# Deploy to production
.\scripts\deploy-vercel.ps1
```

## ⚠️ Prerequisites

- PowerShell 5.1+ (Windows) or PowerShell Core (cross-platform)
- Node.js and npm (for JavaScript scripts)
- Flutter SDK (for Flutter-related scripts)
- Proper environment variables configured (see `.env` files)
