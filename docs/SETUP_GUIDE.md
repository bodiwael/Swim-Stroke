# Swimming Stroke Tracker - Setup Guide

This guide will walk you through setting up both the hardware device and the mobile app.

---

## Table of Contents

1. [Hardware Setup](#hardware-setup)
2. [ESP32 Firmware Setup](#esp32-firmware-setup)
3. [Flutter App Setup](#flutter-app-setup)
4. [First Time Usage](#first-time-usage)
5. [Calibration](#calibration)

---

## Hardware Setup

### Required Components

- ESP32 Development Board
- MPU6050 IMU Sensor
- MicroSD Card Module + MicroSD Card (8GB+, Class 10)
- TP4056 Charging Module
- 18650 Battery (3.7V, min 2000mAh)
- Wireless 5V Charger (Qi standard)
- SPDT Switch
- Waterproof Box (IP67 or better)
- Waist Belt
- Jumper wires
- Soldering equipment

### Assembly Steps

1. **Follow the Wiring Diagram:**
   - See [WIRING_DIAGRAM.md](./WIRING_DIAGRAM.md) for detailed connections

2. **Prepare SD Card:**
   ```bash
   # Format SD card as FAT32
   # On Windows: Right-click drive → Format → FAT32
   # On Mac: Disk Utility → Erase → MS-DOS (FAT)
   # On Linux: sudo mkfs.vfat -F 32 /dev/sdX1
   ```

3. **Test Connections:**
   - Before soldering, use breadboard to test all connections
   - Verify power supply (should be 3.3V for sensors)
   - Check continuity with multimeter

4. **Final Assembly:**
   - Solder all connections
   - Use heat shrink tubing for insulation
   - Secure components in waterproof box
   - Apply silicone sealant to all openings

5. **Waterproof Testing:**
   - Seal box completely
   - Submerge empty box in water for 30 minutes
   - Check for leaks
   - If dry, test with electronics (in air first!)

---

## ESP32 Firmware Setup

### Option 1: Using Arduino IDE

1. **Install Arduino IDE:**
   - Download from: https://www.arduino.cc/en/software
   - Install version 2.0 or later

2. **Add ESP32 Board Support:**
   - Open Arduino IDE
   - Go to File → Preferences
   - Add to "Additional Board Manager URLs":
     ```
     https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
     ```
   - Go to Tools → Board → Boards Manager
   - Search for "esp32"
   - Install "esp32 by Espressif Systems"

3. **Install Required Libraries:**
   - Go to Sketch → Include Library → Manage Libraries
   - Install the following:
     - "MPU6050" by Electronic Cats (v1.3.0 or later)
     - SD (built-in, should be already available)
     - SPI (built-in)
     - BluetoothSerial (built-in with ESP32)

4. **Open and Configure Sketch:**
   - Open `esp32_firmware/swim_stroke_tracker.ino`
   - Select Board: Tools → Board → ESP32 Arduino → ESP32 Dev Module
   - Select Port: Tools → Port → (your ESP32 port)

5. **Upload Firmware:**
   - Click Upload button
   - Wait for compilation and upload
   - Monitor Serial output (Tools → Serial Monitor at 115200 baud)

### Option 2: Using PlatformIO

1. **Install PlatformIO:**
   - Install VS Code: https://code.visualstudio.com/
   - Install PlatformIO extension from VS Code marketplace

2. **Open Project:**
   - Open `esp32_firmware` folder in VS Code
   - PlatformIO will detect the project automatically

3. **Build and Upload:**
   ```bash
   # Build
   pio run

   # Upload
   pio run --target upload

   # Monitor serial output
   pio device monitor
   ```

### Verification

After uploading, you should see in Serial Monitor:
```
Initializing MPU6050...
MPU6050 connected successfully
Initializing SD card...
SD card initialized successfully
Bluetooth initialized - Device: SwimStrokeTracker
System ready!
```

---

## Flutter App Setup

### Prerequisites

- Flutter SDK 3.0+
- Android Studio (for Android) or Xcode (for iOS)
- Android device or emulator

### Installation Steps

1. **Install Flutter:**
   - Follow official guide: https://flutter.dev/docs/get-started/install

2. **Verify Flutter Installation:**
   ```bash
   flutter doctor
   ```

3. **Navigate to App Directory:**
   ```bash
   cd flutter_app
   ```

4. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

5. **Build and Run:**

   **For Android:**
   ```bash
   # Connect Android device via USB or start emulator
   flutter run
   ```

   **Build APK:**
   ```bash
   flutter build apk --release
   # APK location: build/app/outputs/flutter-apk/app-release.apk
   ```

6. **Grant Permissions:**
   - When app first launches, grant Bluetooth and Location permissions
   - These are required for Bluetooth device scanning

---

## First Time Usage

### 1. Pair ESP32 Device

**On Android:**
1. Go to Settings → Bluetooth
2. Enable Bluetooth
3. Look for "SwimStrokeTracker"
4. Tap to pair (PIN: 1234 if required)

### 2. Connect in App

1. Open Swim Stroke Tracker app
2. You should see "SwimStrokeTracker" in device list
3. Tap to connect
4. Connection status should show "Connected"

### 3. First Recording Test

1. Tap "Start New Session"
2. Tap "START RECORDING"
3. Device will start recording
4. Shake and rotate the device for 30 seconds
5. Tap "STOP RECORDING"
6. App will download and process data
7. Check results screen

---

## Calibration

### MPU6050 Calibration

The MPU6050 should be calibrated for best results:

1. **Place Device Flat:**
   - Put device on flat, level surface
   - Keep it completely still

2. **Power On and Wait:**
   - Power on device
   - Wait 10 seconds for sensor to stabilize

3. **Orientation:**
   - The device should be oriented the same way it will be worn
   - For waist belt: flat against lower back

### App Calibration

The app automatically removes the first and last 10 seconds of data:

- **First 10 seconds:** Allows you to enter the water
- **Last 10 seconds:** Allows you to exit the water

**Usage Flow:**
1. Start recording BEFORE entering pool
2. Wait 10 seconds (calibration period)
3. Start swimming
4. Finish swimming
5. Wait 10 seconds
6. Stop recording

### Peak Detection Tuning

If stroke detection is inaccurate:

1. Edit `flutter_app/lib/services/data_processor.dart`
2. Adjust these parameters:

```dart
// Line ~30-32
static const double peakThreshold = 0.6;  // Default: 0.6
// Increase (0.7-0.8) for fewer, more prominent strokes
// Decrease (0.4-0.5) for more sensitive detection

static const int minPeakDistance = 500;   // Default: 500ms
// Increase (700-1000) for slower swimming
// Decrease (300-400) for faster swimming
```

3. Rebuild app:
```bash
flutter build apk --release
```

---

## Troubleshooting

### Device Won't Connect

1. **Check Bluetooth is enabled** on phone
2. **Unpair and re-pair** device in system settings
3. **Restart ESP32** by toggling power switch
4. **Check Serial Monitor** for error messages
5. **Re-upload firmware** if needed

### No Data Recorded

1. **Check SD card** is inserted and formatted (FAT32)
2. **Verify connections** between ESP32 and SD module
3. **Try different SD card** (some cards are incompatible)
4. **Check Serial Monitor** for SD card errors

### Inaccurate Stroke Count

1. **Check device placement** - should be at lower back
2. **Ensure tight belt** - device shouldn't move during swimming
3. **Calibrate properly** - 10 seconds before/after swimming
4. **Adjust peak detection** parameters (see above)
5. **Try different swimming stroke** - works best with freestyle

### Battery Issues

1. **Check charging** - TP4056 LED should light up
2. **Verify battery voltage** - should be 3.7-4.2V
3. **Test battery capacity** - might need replacement
4. **Check power switch** - ensure it's in ON position

### App Crashes

1. **Check Flutter version:** `flutter --version`
2. **Update dependencies:** `flutter pub upgrade`
3. **Clear cache:** `flutter clean`
4. **Rebuild:** `flutter build apk --release`
5. **Check logcat** for error messages

---

## Tips for Best Results

### Swimming Technique
- Works best with **freestyle/front crawl**
- Maintain **consistent stroke rhythm**
- Ensure device is **secure and doesn't shift**

### Device Placement
- **Lower back** position is optimal
- Keep device **centered on spine**
- Belt should be **tight but comfortable**

### Recording
- Record **entire session** including rest periods
- The app will filter out calibration periods automatically
- Include **multiple laps** for better statistics

### Data Accuracy
- Enter **correct pool length** (25m or 50m)
- Count **laps accurately**
- This ensures accurate stroke length calculation

### Maintenance
- **Dry device** thoroughly after each use
- **Recharge** after every session
- **Check seals** regularly for waterproofing
- **Clean** sensors and connections monthly

---

## Next Steps

Once everything is working:

1. **Test in shower** (waterproof check)
2. **Test in pool** with short session
3. **Analyze results** and calibrate if needed
4. **Start regular tracking** of your swimming sessions
5. **Compare sessions** over time to track improvement

For advanced features and customization, see the source code comments and documentation.

Happy Swimming! 🏊‍♂️
