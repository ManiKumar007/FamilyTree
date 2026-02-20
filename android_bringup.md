# Android Build with Android Studio

## Issue: Low System Memory

When Flutter CLI builds fail with Java heap allocation errors:
```
Error occurred during initialization of VM
Could not reserve enough space for object heap
```

This indicates your system doesn't have enough available memory for Gradle's Java compiler.

## Solution: Use Android Studio

Android Studio has better memory management for Android builds compared to the command-line Gradle process.

### Steps to Build with Android Studio

1. **Open the Android project in Android Studio**
   - Launch Android Studio
   - Click "Open an Existing Project"
   - Navigate to: `app/android`
   - Click "OK"

2. **Wait for Gradle sync**
   - Android Studio will automatically sync Gradle dependencies
   - Wait for the "Gradle build finished" message in the bottom status bar
   - This may take 2-5 minutes on first sync

3. **Verify emulator is running**
   - In terminal: `flutter emulators --launch Pixel_9`
   - Or use Android Studio's AVD Manager: Tools → Device Manager
   - Wait ~60 seconds for emulator to fully boot

4. **Build and run from Android Studio**
   
   **Option A: Run button (Recommended)**
   - Click the green "Run" button (▶️) in the toolbar
   - Select `emulator-5554` as the target device
   - Android Studio will build and install the APK automatically
   
   **Option B: Build APK only**
   - Menu: Build → Build Bundle(s) / APK(s) → Build APK(s)
   - Wait for "Build successful" notification
   - APK location: `app/build/app/outputs/flutter-apk/app-debug.apk`
   - Install manually: `adb install app-debug.apk`

5. **View build output**
   - Check the "Build" tab at the bottom for progress
   - Any errors will appear in the "Problems" tab
   - Logcat shows runtime logs once app is running

### Memory Configuration

The Gradle memory settings are in `app/android/gradle.properties`:

```properties
org.gradle.jvmargs=-Xmx768m -XX:MaxMetaspaceSize=256m -Dfile.encoding=UTF-8
android.useAndroidX=true
org.gradle.daemon=false
org.gradle.caching=false
org.gradle.parallel=false
```

**Current settings:** 768MB heap, daemon disabled to reduce memory usage.

If Android Studio builds also fail:
- Close other applications (VS Code, Outlook, browsers)
- Increase system RAM
- Use a more powerful machine for Android development

### Alternative: Build on Another Machine

If your development machine has insufficient RAM:

1. **Use a cloud build service**
   - GitHub Actions (free for public repos)
   - Codemagic (Flutter CI/CD)
   - AWS CodeBuild

2. **Build on a teammate's machine**
   - Share the project folder
   - They run: `flutter build apk --release`
   - Share the APK file back to you

3. **Use a VM/Cloud Desktop**
   - Azure Virtual Desktop
   - AWS WorkSpaces
   - Configure with 8GB+ RAM

## Successfully Built APK Distribution

Once you have a working APK from Android Studio:

**For testing:**
```bash
# Install to connected device/emulator
adb install app/build/app/outputs/flutter-apk/app-debug.apk

# Or drag-drop APK into emulator window
```

**For sharing:**
```bash
# Build release APK
flutter build apk --release

# Output: app/build/app/outputs/flutter-apk/app-release.apk
# Share this file via email, cloud storage, etc.
```

## Next Steps After Successful Build

1. **Test all features on Android:**
   - Login/Signup (verify backend connectivity via 10.0.2.2:3000)
   - All 7 navigation tabs work
   - Notification bell shows badge
   - Forum photo uploads (5-photo limit)
   - Calendar, Statistics, Person details

2. **Physical device testing:**
   - Update `.env` file with PC's network IP: `API_BASE_URL=http://192.168.x.x:3000/api`
   - Enable USB debugging on phone
   - Connect via USB
   - Run from Android Studio or `flutter run`

3. **Fix any Android-specific issues:**
   - Layout problems on different screen sizes
   - Camera/photo picker permissions
   - Performance optimization

4. **Production release preparation:**
   - Change package name from `com.example.myfamilytree` to your domain
   - Add custom app icon
   - Set up app signing for Play Store
   - Build App Bundle: `flutter build appbundle --release`

## References

- [Android Studio Download](https://developer.android.com/studio)
- [Flutter Android Setup Guide](https://docs.flutter.dev/get-started/install/windows#android-setup)
- [Gradle Daemon Documentation](https://docs.gradle.org/current/userguide/gradle_daemon.html)
- Project docs: `ANDROID_SETUP.md`, `LAUNCH_GUIDE.md`
