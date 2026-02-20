# Android Setup for MyFamilyTree

## ✅ What's Been Configured

### 1. Android Platform Files Created
- Flutter Android platform files generated
- Package name: `com.example.myfamilytree`
- App name: `MyFamilyTree`

### 2. Permissions Added (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```
- Required for API calls to backend and Supabase
- `usesCleartextTraffic="true"` enabled for local development

### 3. Localhost Fix for Android Emulator
Updated `lib/config/constants.dart` to automatically replace `localhost` with `10.0.2.2` when running on Android emulator.

**Why?** Android emulators can't access the host machine's `localhost`. The special IP `10.0.2.2` maps to the host machine.

### 4. Launch Script Created
**File**: `start-android.ps1`
- Auto-detects Flutter installation
- Lists available emulators
- Prompts to launch emulator if none running
- Runs the app on Android

## 🚀 How to Run on Android

### Prerequisites
1. **Backend must be running** on port 3000
2. **Android emulator** or physical device

### Option 1: Use the Launch Script (Recommended)
```powershell
.\start-android.ps1
```

The script will:
1. Check for connected Android devices
2. If none found, offer to launch an emulator:
   - Pixel 9
   - Medium Phone API 36.1
3. Wait for emulator to boot
4. Run the app

### Option 2: Manual Launch
1. **Start backend** (if not running):
   ```powershell
   .\start-backend.ps1
   ```

2. **Launch emulator**:
   ```powershell
   flutter emulators --launch Pixel_9
   # OR
   flutter emulators --launch Medium_Phone_API_36.1
   ```

3. **Run the app**:
   ```powershell
   cd app
   flutter run
   ```

### Option 3: Physical Android Device
1. Enable **Developer Options** on your Android phone
2. Enable **USB Debugging**
3. Connect phone via USB
4. Run: `flutter run`

## 🔧 Important Notes

### API Base URL
- **Web**: Uses `http://localhost:3000/api`
- **Android Emulator**: Automatically uses `http://10.0.2.2:3000/api`
- **Physical Device**: You may need to update `.env` to use your computer's network IP (e.g., `http://192.168.1.100:3000/api`)

### To Use Physical Device with Backend
1. Find your computer's IP address:
   ```powershell
   ipconfig
   ```
   Look for "IPv4 Address" (e.g., 192.168.1.100)

2. Update `app/.env`:
   ```
   API_BASE_URL=http://192.168.1.100:3000/api
   ```

3. Make sure phone and computer are on the same Wi-Fi network

### Backend Firewall
If using a physical device, ensure Windows Firewall allows incoming connections on port 3000:
```powershell
# Allow port 3000 in Windows Firewall
New-NetFirewallRule -DisplayName "MyFamilyTree Backend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

## 🐛 Troubleshooting

### "Unable to connect to backend"
- ✅ Verify backend is running: `http://localhost:3000/api/health`
- ✅ On emulator: App uses `10.0.2.2:3000` automatically
- ✅ On physical device: Update `.env` with your computer's IP

### Emulator won't start
```powershell
# List emulators
flutter emulators

# Launch specific emulator
flutter emulators --launch Pixel_9
```

### App crashes on startup
```powershell
# Check Flutter doctor
flutter doctor

# View logs
flutter logs
```

### Hot reload not working
- Press `r` in terminal for hot reload
- Press `R` for hot restart
- Or stop and restart the app

## 📱 Testing on Android

### Features to Test
1. **Authentication**: Login/Signup with Supabase
2. **Family Tree**: Add/edit persons, relationships
3. **Forum**: Create posts, upload photos (max 5)
4. **Notifications**: Bell icon, badge count
5. **Calendar**: View events
6. **Statistics**: Family stats dashboard
7. **Profile**: Deceased handling, native place, timeline

### Performance
- First build takes 2-5 minutes (Gradle downloads dependencies)
- Subsequent builds are much faster
- Hot reload works instantly for UI changes

## 🎯 Next Steps

### 1. Test on Emulator
```powershell
.\start-android.ps1
```

### 2. Test All Features
- Complete user journey: signup → add family → forum → calendar

### 3. Build APK for Distribution
```powershell
cd app
flutter build apk --release
```
APK location: `app/build/app/outputs/flutter-apk/app-release.apk`

### 4. Optimize for Production
- Add app signing certificate
- Update package name from `com.example.myfamilytree` to your domain
- Add app icon (current is default Flutter icon)
- Test on multiple devices/screen sizes

## 📊 Available Emulators

You have 2 Android emulators configured:

1. **Pixel 9**
   - Latest Google Pixel device
   - Good for testing modern Android features

2. **Medium Phone API 36.1**
   - Medium-sized screen
   - Android API 36

To create more emulators:
```powershell
flutter emulators --create --name MyEmulator
```

## 🔗 Resources

- Flutter Android Setup: https://docs.flutter.dev/get-started/install/windows#android-setup
- Android Emulator: https://developer.android.com/studio/run/emulator
- Flutter Deployment: https://docs.flutter.dev/deployment/android
