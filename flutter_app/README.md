# Flutter App - Swimming Stroke Tracker

Mobile application for controlling the swimming stroke tracker device and analyzing session data.

## Features

- **Bluetooth connectivity** to ESP32 device
- **Session recording** control (start/stop)
- **Real-time status** updates
- **Signal processing** with peak detection
- **Interactive charts** for data visualization
- **Metrics calculation** (strokes, timing, distance)

## Prerequisites

- Flutter SDK 3.0 or later
- Android device (Android 6.0+) or iOS device
- Bluetooth Classic support (most phones have this)

## Setup

### 1. Install Flutter

Follow the official guide: https://flutter.dev/docs/get-started/install

Verify installation:
```bash
flutter doctor
```

### 2. Install Dependencies

```bash
cd flutter_app
flutter pub get
```

### 3. Run on Device

**Android:**
```bash
# Connect phone via USB with debugging enabled
flutter run
```

**Build Release APK:**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Install APK:**
```bash
flutter install
```

## Permissions

The app requires these permissions (automatically requested on first launch):

- **Bluetooth** - For device communication
- **Location** - Required by Android for Bluetooth scanning

## Dependencies

Key packages used:

- `flutter_bluetooth_serial` - Bluetooth Classic communication
- `fl_chart` - Interactive charts and graphs
- `provider` - State management
- `csv` - CSV data parsing
- `path_provider` - File system access

## Project Structure

```
lib/
├── main.dart                     # App entry point
├── models/
│   └── session_data.dart        # Data models
├── screens/
│   ├── home_screen.dart         # Device connection
│   ├── recording_screen.dart    # Session recording
│   └── results_screen.dart      # Data visualization
└── services/
    ├── bluetooth_service.dart   # Bluetooth communication
    └── data_processor.dart      # Signal processing
```

## Usage Flow

1. **Launch App** → Grant permissions
2. **Connect Device** → Tap "SwimStrokeTracker"
3. **Start Session** → Tap "Start New Session"
4. **Begin Recording** → Tap "START RECORDING"
5. **Swim** → Device records data (can disconnect)
6. **Stop Recording** → Reconnect and tap "STOP"
7. **View Results** → Automatic processing and display

## Customization

### Adjust Peak Detection

Edit `lib/services/data_processor.dart`:

```dart
// Line ~30-32
static const double peakThreshold = 0.6;      // Sensitivity
static const int minPeakDistance = 500;       // Min time between strokes
static const int calibrationSeconds = 10;     // Calibration period
```

### Change UI Theme

Edit `lib/main.dart`:

```dart
theme: ThemeData(
  primarySwatch: Colors.blue,  // Change primary color
  useMaterial3: true,
),
```

## Troubleshooting

### Bluetooth Not Working

1. Enable Bluetooth in system settings
2. Grant location permission (required on Android)
3. Restart app
4. Check device is paired in system Bluetooth settings

### Connection Timeout

1. Ensure device is powered on
2. Check device is not connected to another app
3. Restart ESP32 device
4. Clear Bluetooth cache (Android settings)

### Data Processing Errors

1. Ensure session was recorded (check file size > 0)
2. Verify SD card is working on ESP32
3. Try shorter test session first
4. Check app logs for specific errors

## Development

### Run in Debug Mode

```bash
flutter run --debug
```

### View Logs

```bash
flutter logs
```

### Format Code

```bash
flutter format lib/
```

### Analyze Code

```bash
flutter analyze
```

## Building for Production

### Android

```bash
# Build release APK
flutter build apk --release

# Build app bundle (for Play Store)
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

## Future Enhancements

- [ ] Session history storage (local database)
- [ ] Export data to CSV/JSON
- [ ] Cloud sync with Firebase
- [ ] Comparison between sessions
- [ ] Training goals and progress tracking
- [ ] Share results on social media

## License

MIT License - See parent directory for full license
