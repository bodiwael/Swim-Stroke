# Quick Start Guide - Flutter App Build

## Problem: Namespace Error

You're seeing this error because `flutter_bluetooth_serial` package needs a namespace fix for newer Android versions.

## Solution (Choose One):

### Option 1: Automated Fix (Easiest)

**On Windows:**
```cmd
cd flutter_app
fix_bluetooth_package.bat
flutter clean
flutter pub get
flutter build apk --release
```

**On macOS/Linux:**
```bash
cd flutter_app
chmod +x fix_bluetooth_package.sh
./fix_bluetooth_package.sh
flutter clean
flutter pub get
flutter build apk --release
```

### Option 2: Manual Fix (5 minutes)

1. **Run Flutter pub get first:**
   ```bash
   cd flutter_app
   flutter pub get
   ```

2. **Find the package folder:**

   **Windows:** Open File Explorer and navigate to:
   ```
   %LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\flutter_bluetooth_serial-0.4.0\android
   ```

   **macOS/Linux:**
   ```
   ~/.pub-cache/hosted/pub.dev/flutter_bluetooth_serial-0.4.0/android
   ```

3. **Edit `build.gradle` file in that folder:**

   Find this line (around line 23):
   ```gradle
   android {
       compileSdkVersion 33
   ```

   Change it to:
   ```gradle
   android {
       namespace 'io.github.edufolly.flutterbluetoothserial'
       compileSdkVersion 33
   ```

4. **Save and build:**
   ```bash
   flutter clean
   flutter build apk --release
   ```

## Expected Output

After successful build, you'll find your APK at:
```
flutter_app\build\app\outputs\flutter-apk\app-release.apk
```

## Install on Phone

1. Copy the APK to your Android phone
2. Enable "Install from Unknown Sources" in settings
3. Tap the APK to install
4. Grant Bluetooth and Location permissions when prompted

## Still Having Issues?

See [ANDROID_BUILD_FIX.md](ANDROID_BUILD_FIX.md) for more detailed troubleshooting.

## Build Time

First build: ~5-10 minutes
Subsequent builds: ~1-2 minutes

Be patient on the first build!
