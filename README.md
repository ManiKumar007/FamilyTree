# FamilyTree - Digital Family Tree Application

A comprehensive family tree management application built with Flutter, Node.js, and Supabase.

## 📁 Project Structure

```
FamilyTree/
├── app/                    # Flutter mobile/web application
├── backend/                # Node.js/Express API server
├── supabase/              # Supabase database migrations & functions
├── scripts/               # Utility scripts for development & deployment
├── doc/                   # Documentation and guides
├── e2e-tests/            # End-to-end tests
├── screenshots/          # Application screenshots
└── test-results/         # Test execution results
```

## 🚀 Quick Start

### Prerequisites

- Flutter SDK (latest stable)
- Node.js 18+ and npm
- Supabase account and project
- PowerShell 5.1+ (for scripts)

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd FamilyTree
   ```

2. **Install dependencies**
   ```powershell
   # Backend
   cd backend
   npm install
   
   # Flutter app
   cd ../app
   flutter pub get
   ```

3. **Configure environment variables**
   - Copy `.env.example` to `.env` in both `app/` and `backend/` directories
   - Update with your Supabase credentials

4. **Run the application**
   ```powershell
   # From project root
   .\scripts\start-all.ps1
   ```

## 📚 Documentation

All documentation is located in the [`doc/`](doc/) directory:

- [Quick Start Guide](doc/QUICK-START.md)
- [Launch Guide](doc/LAUNCH_GUIDE.md)
- [Authentication Setup](doc/AUTH_SETUP.md)
- [Deployment Guide](doc/DEPLOYMENT.md)
- [API Documentation](doc/API_TROUBLESHOOTING.md)
- [Testing Best Practices](doc/TESTING_BEST_PRACTICES.md)

## 🛠️ Development Scripts

Common development scripts in the [`scripts/`](scripts/) directory:

```powershell
# Start development servers
.\scripts\start-all.ps1           # Start backend + frontend
.\scripts\start-backend.ps1       # Backend only
.\scripts\start-frontend.ps1      # Frontend only

# Testing
.\scripts\run-tests.ps1           # Run all tests
.\scripts\run-flutter-tests.ps1   # Flutter tests only

# Database
.\scripts\run-migration.ps1       # Run migrations
.\scripts\seed-test-data.ps1      # Seed test data

# Deployment
.\scripts\deploy-vercel.ps1       # Deploy to Vercel
```

See [scripts/README.md](scripts/README.md) for full list of available scripts.

## 🏗️ Technology Stack

### Frontend (Flutter)
- **Framework**: Flutter 3.x
- **State Management**: Riverpod
- **Routing**: go_router
- **UI**: Material Design 3

### Backend (Node.js)
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage

### Infrastructure
- **Hosting**: Vercel (Frontend & Backend)
- **Database**: Supabase Cloud
- **Authentication**: Supabase Auth with Email/Password & OAuth (Google, Facebook)

## ✨ Features

- 🌳 **Interactive Family Tree** - Visualize and navigate your family connections
- 👤 **User Profiles** - Rich user profiles with photos and details
- 🔍 **Advanced Search** - Find family members by name, relationship, or attributes
- 🔗 **Connection Finder** - Discover how two people are related
- 📅 **Calendar** - Track birthdays, anniversaries, and family events
- 💬 **Family Forum** - Discuss and share family stories
- 📊 **Statistics** - Insights about your family tree
- 📱 **Cross-Platform** - Web, Android, and iOS support
- 🔐 **Secure Authentication** - Email/password and social login
- 🌐 **Multi-User** - Collaborate with family members

## 🧪 Testing

```powershell
# Run all tests
.\scripts\run-tests.ps1

# Run specific test suites
.\scripts\run-flutter-tests.ps1      # Flutter unit/widget tests
.\scripts\run-integration-tests.ps1  # Integration tests
.\scripts\test-api.ps1               # API tests
```

## 📦 Deployment

The application is deployed on Vercel:

```powershell
# Deploy to production
.\scripts\deploy-vercel.ps1

# Check deployment status
.\scripts\deploy-check.ps1
```

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Run tests: `.\scripts\run-tests.ps1`
4. Submit a pull request

## 📄 License

[Your License Here]

## 📞 Support

For issues and questions:
- Check the [documentation](doc/)
- Review [troubleshooting guides](doc/API_TROUBLESHOOTING.md)
- Open an issue on GitHub

---

**Last Updated**: February 24, 2026
