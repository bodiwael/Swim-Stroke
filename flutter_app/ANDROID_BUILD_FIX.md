# Android Build Fix Guide

The `flutter_bluetooth_serial` package has a namespace issue with newer Android Gradle plugin versions. Here's how to fix it:

## Quick Fix (Recommended)

### For Windows:

1. Open Command Prompt or PowerShell in the `flutter_app` folder
2. Run the fix script:
   ```cmd
   fix_bluetooth_package.bat
   ```

### For macOS/Linux:

1. Open Terminal in the `flutter_app` folder
2. Make script executable and run:
   ```bash
   chmod +x fix_bluetooth_package.sh
   ./fix_bluetooth_package.sh
   ```

## Manual Fix

If the script doesn't work, follow these steps:

### Step 1: Locate the Package

**Windows:**
```
C:\Users\[YourUsername]\AppData\Local\Pub\Cache\hosted\pub.dev\flutter_bluetooth_serial-0.4.0\android\build.gradle
```

**macOS/Linux:**
```
~/.pub-cache/hosted/pub.dev/flutter_bluetooth_serial-0.4.0/android/build.gradle
```

### Step 2: Edit build.gradle

Open the `build.gradle` file in a text editor and find this section:
```gradle
android {
    compileSdkVersion 33
```

Add the namespace line right after `android {`:
```gradle
android {
    namespace 'io.github.edufolly.flutterbluetoothserial'
    compileSdkVersion 33
```

### Step 3: Save and Build

Save the file and try building again:
```bash
flutter clean
flutter pub get
flutter build apk --release
```

## Alternative: Use Flutter Blue Plus (Bluetooth LE)

If you continue having issues, consider switching to BLE (requires minor ESP32 code changes):

### Update pubspec.yaml:
```yaml
dependencies:
  flutter_blue_plus: ^1.31.0
```

**Note:** This requires changing ESP32 to use BLE instead of Bluetooth Classic.

## Verification

After applying the fix, run:
```bash
cd flutter_app
flutter clean
flutter pub get
flutter build apk --release
```

You should see a successful build!

## Common Issues

### Issue: "Cannot find package"
**Solution:** Run `flutter pub get` first to download the package

### Issue: "Permission denied" (macOS/Linux)
**Solution:** Run `chmod +x fix_bluetooth_package.sh` before executing

### Issue: Build still fails
**Solution:**
1. Delete `flutter_app/build` folder
2. Run `flutter clean`
3. Apply the fix again
4. Run `flutter pub get`
5. Try building again

## Build Output Location

After successful build:
```
flutter_app/build/app/outputs/flutter-apk/app-release.apk
```

Copy this APK to your phone and install!
