# Flutter Project Initialization Guide

Since the `app/` directory currently only contains the Dart code, you need to initialize it as a proper Flutter project.

## Option 1: Create New Flutter Project (Recommended)

### Step 1: Create Flutter Project

```bash
# Navigate to the project root
cd "C:\Users\mahchi01\OneDrive - Cadence Design Systems Inc\Documents\Sourcecode\Personal\FamilyTree"

# Create a new Flutter project
flutter create --org com.myfamilytree --project-name myfamilytree app_temp

# Move the android and ios folders to the app directory
mv app_temp/android app/
mv app_temp/ios app/
mv app_temp/windows app/
mv app_temp/linux app/
mv app_temp/macos app/
mv app_temp/web app/

# Remove the temporary directory
rm -rf app_temp
```

### Step 2: Update Android Configuration

#### 2.1 Update `android/app/build.gradle`

```gradle
android {
    namespace = "com.myfamilytree"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.myfamilytree"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.debug
        }
    }
}
```

#### 2.2 Update `android/app/src/main/AndroidManifest.xml`

Add deep link intent filter for magic links:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <application
        android:label="MyFamilyTree"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"/>
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            
            <!-- Deep link for magic link callback -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="com.myfamilytree"
                      android:host="login-callback"/>
            </intent-filter>
            
            <!-- App Links for Supabase magic links -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="https"
                      android:host="your-project.supabase.co"
                      android:pathPrefix="/auth/v1/verify"/>
            </intent-filter>
        </activity>
        
        <meta-data
            android:name="flutterEmbedding"
            android:value="2"/>
    </application>
</manifest>
```

#### 2.3 Get SHA-1 Fingerprint for Google Sign-In

```bash
# For debug keystore (Windows)
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# Copy the SHA-1 fingerprint and add it to Google Cloud Console
# (See AUTH_SETUP.md for details)
```

### Step 3: Update iOS Configuration

#### 3.1 Update `ios/Runner/Info.plist`

Add URL schemes for Google Sign-In and deep linking:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Existing keys... -->
    
    <!-- URL Types for Google Sign-In and Deep Linking -->
    <key>CFBundleURLTypes</key>
    <array>
        <!-- Google Sign-In (replace with your iOS Client ID) -->
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>com.googleusercontent.apps.YOUR-IOS-CLIENT-ID</string>
            </array>
        </dict>
        
        <!-- Deep link for magic link callback -->
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>com.myfamilytree</string>
            </array>
        </dict>
    </array>
    
    <!-- Query Schemes for Google Sign-In -->
    <key>LSApplicationQueriesSchemes</key>
    <array>
        <string>googlechrome</string>
        <string>googlechromes</string>
    </array>
</dict>
</plist>
```

#### 3.2 Update Bundle Identifier

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project
3. Go to **Signing & Capabilities**
4. Change **Bundle Identifier** to `com.myfamilytree`
5. Select your development team

### Step 4: Install Dependencies

```bash
cd app
flutter pub get
```

### Step 5: Verify Setup

```bash
# Check for issues
flutter doctor

# Run on connected device/emulator
flutter run
```

## Option 2: Manual Platform Setup (If needed)

If you only need specific platforms:

### Android Only
```bash
cd app
flutter create --platforms=android .
```

### iOS Only
```bash
cd app
flutter create --platforms=ios .
```

### All Platforms
```bash
cd app
flutter create --platforms=android,ios,web,windows,linux,macos .
```

## Common Issues

### Issue: "No pubspec.yaml file found"

**Solution:** Make sure you're in the `app/` directory:
```bash
cd app
flutter pub get
```

### Issue: "CocoaPods not installed" (iOS)

**Solution:** Install CocoaPods:
```bash
sudo gem install cocoapods
cd ios
pod install
```

### Issue: "SDK location not found" (Android)

**Solution:** Set ANDROID_HOME environment variable or create `android/local.properties`:
```properties
sdk.dir=C:\\Users\\YOUR_USERNAME\\AppData\\Local\\Android\\Sdk
```

### Issue: Google Sign-In not working

**Solution:** 
1. Verify SHA-1 fingerprint is added to Google Cloud Console
2. Check that OAuth Client IDs are configured correctly
3. Ensure Web Client ID is in `.env` file

## Next Steps

After initialization:
1. Follow [AUTH_SETUP.md](AUTH_SETUP.md) for authentication configuration
2. Create backend `.env` file
3. Create app `.env` file
4. Test the authentication flow
5. Proceed with Step 6: Tree Canvas UI

## Platform-Specific Notes

### Android
- Minimum SDK: 24 (Android 7.0)
- Target SDK: 34 (Android 14)
- Permissions: Internet (for API calls)

### iOS
- Minimum iOS: 12.0
- Requires Xcode 14.0+
- Requires CocoaPods for dependencies

### Web
- Not the primary target but can be used for testing
- Google Sign-In on web requires additional configuration

## Development Workflow

1. **Android Emulator:**
   ```bash
   flutter run
   ```

2. **iOS Simulator:**
   ```bash
   flutter run -d ios
   ```

3. **Physical Device:**
   ```bash
   # List devices
   flutter devices
   
   # Run on specific device
   flutter run -d <device-id>
   ```

4. **Hot Reload:**
   - Press `r` in terminal for hot reload
   - Press `R` for hot restart
   - Press `q` to quit

5. **Debug Mode:**
   ```bash
   flutter run --debug
   ```

6. **Release Mode:**
   ```bash
   flutter run --release
   ```
