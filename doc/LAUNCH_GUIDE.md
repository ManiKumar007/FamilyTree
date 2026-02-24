# MyFamilyTree - Quick Launch Guide

## 🚀 One-Command Launches

### Start Everything (Backend + Web)
```powershell
.\start-all.ps1
```
- Starts backend on port 3000
- Starts web app on port 5500
- Access: http://localhost:5500

### Start Backend Only
```powershell
.\start-backend.ps1
```
- Node.js/Express server on port 3000
- API: http://localhost:3000/api

### Start Web Only
```powershell
.\start-frontend.ps1
```
- Flutter web on Chrome, port 5500
- Requires backend running

### Start Android 📱 NEW!
```powershell
.\start-android.ps1
```
- Launches Android emulator (if needed)
- Runs Flutter app on Android
- Requires backend running

### Stop Everything
```powershell
.\stop-all.ps1
```
- Stops all backend and frontend processes

## 📋 Platform Support

| Platform | Status | Command | Port/Device |
|----------|--------|---------|-------------|
| **Web** | ✅ Ready | `.\start-frontend.ps1` | 5500 (Chrome) |
| **Android** | ✅ Ready | `.\start-android.ps1` | Emulator/Device |
| **iOS** | ⚠️ Mac Only | N/A | - |
| **Windows Desktop** | 🔧 Possible | `flutter run -d windows` | Native app |

## 🎯 Quick Start

### First Time Setup
1. Install dependencies:
   ```powershell
   cd backend
   npm install
   cd ../app
   flutter pub get
   ```

2. Configure environment:
   - Copy `app/.env.example` to `app/.env`
   - Update Supabase credentials

3. Start everything:
   ```powershell
   .\start-all.ps1
   ```

### Daily Development

**Web Development:**
```powershell
.\start-all.ps1
# Open http://localhost:5500
```

**Android Development:**
```powershell
.\start-backend.ps1    # Terminal 1
.\start-android.ps1    # Terminal 2
```

## 🔧 Advanced Options

### Run on Specific Android Emulator
```powershell
cd app
flutter run -d Pixel_9
# OR
flutter run -d Medium_Phone_API_36.1
```

### Run on Physical Android Device
1. Enable USB debugging on phone
2. Connect via USB
3. Run:
   ```powershell
   flutter run
   ```

### Build for Production

**Android APK:**
```powershell
cd app
flutter build apk --release
# Output: app/build/app/outputs/flutter-apk/app-release.apk
```

**Web (optimized):**
```powershell
cd app
flutter build web --release
# Output: app/build/web/
```

## 📱 Android-Specific Notes

### Backend Access
- **Emulator**: Automatically uses `http://10.0.2.2:3000/api`
- **Physical Device**: Edit `app/.env` to use your PC's IP:
  ```
  API_BASE_URL=http://192.168.1.100:3000/api
  ```

### Find Your PC's IP
```powershell
ipconfig
# Look for "IPv4 Address" under your WiFi adapter
```

### Allow Firewall (for physical devices)
```powershell
New-NetFirewallRule -DisplayName "MyFamilyTree Backend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

## 🧪 Testing

### Run Backend Tests
```powershell
cd backend
npm test
```

### Run Flutter Tests
```powershell
cd app
flutter test
```

### Run Integration Tests
```powershell
.\run-integration-tests.ps1
```

## 📚 Documentation

- [Android Setup](ANDROID_SETUP.md) - Complete Android guide
- [How To Setup Development Environment](How-To-Setup-DevelopmentEnv.md)
- [Testing Guide](TESTING_GUIDE.md)
- [API Documentation](API_TROUBLESHOOTING.md)

## 🐛 Common Issues

### Port 3000 Already in Use
```powershell
# Kill process on port 3000
$port3000 = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
if ($port3000) { Stop-Process -Id $port3000 -Force }
```

### Flutter Not Found
- Add Flutter to PATH, or
- Scripts auto-detect from `C:\flutter\bin` or `C:\src\flutter\bin`

### Android Emulator Won't Start
```powershell
# List available emulators
flutter emulators

# Launch manually
flutter emulators --launch Pixel_9
```

### Hot Reload Lost
- Press `R` in Flutter terminal (hot restart)
- Or stop and restart

## 🎨 UI Navigation

After login, you'll see:

**Desktop Sidebar / Mobile Bottom Nav:**
1. Family Tree 🌳
2. Search 🔍
3. Connection 🔗
4. Invite ➕
5. Forum 💬
6. Calendar 📅
7. Statistics 📊

**Top-Right Header:**
- 🔔 Notifications (with unread badge)

## 🔄 Development Workflow

1. **Make changes** in code
2. **Save file**
3. **Hot reload** happens automatically
4. If UI doesn't update, press `r` or `R` in terminal
5. Check logs for errors

## 👨‍💻 Team Collaboration

### Git Workflow
```bash
git pull origin main          # Get latest changes
# Make your changes
git add .
git commit -m "Description"
git push origin your-branch
```

### Share Backend API
- Use ngrok or similar for remote testing
- Update `API_BASE_URL` in `.env` for remote backend

## 📞 Support

For issues:
1. Check documentation files
2. Run `flutter doctor` for Flutter issues
3. Check `backend/logs` for API errors
4. View browser console (F12) for web errors
5. Use `flutter logs` for Android errors
