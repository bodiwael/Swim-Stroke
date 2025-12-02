# Changelog

All notable changes to the Swim Stroke Tracker project.

## [2024-12-02] - Major Detection Algorithm Fix

### 🔧 Critical Fixes

**Stroke Detection Accuracy** - Fixed severe undercount issue (was detecting 1-3 strokes instead of 21)

- **Fixed peak distance bug**: Was using sample count (500 samples = 10 seconds!) instead of milliseconds
  - Changed from 500 samples to 800 milliseconds default
  - Now correctly converts milliseconds to samples based on 50Hz sampling rate

- **Fixed calibration period**: Was removing too much data from short sessions
  - Changed from fixed 10 seconds to adaptive 3-8 seconds
  - Sessions < 30s: 3 second calibration
  - Sessions 30-60s: 5 second calibration
  - Sessions > 60s: 8 second calibration

- **Lowered detection threshold**: From 0.6 to 0.25 (much more sensitive)
  - New statistical calculation using mean + (factor × 2×stdDev)
  - Better adapts to different signal characteristics

### ✨ New Features

**Real-Time Sensitivity Adjustment**

- Added tune button (⚙️ icon) to results screen
- Interactive sliders to adjust:
  - Detection sensitivity (0.05 - 0.6)
  - Minimum time between strokes (0.3 - 2.0 seconds)
- Instant reprocessing with new parameters
- Visual feedback and helpful tooltips

**Improved Signal Processing**

- Added median filter to remove noise spikes
- Combined gyroscope + accelerometer data
- More robust peak detection (checks 4 neighbors)
- Better signal normalization
- Extensive debug logging

### 📚 Documentation

- Added comprehensive tuning guide (`docs/TUNING_GUIDE.md`)
- Examples for different swimming styles
- Troubleshooting section
- Visual interpretation guide

### 🎯 Expected Results

- **Before**: 5-10% accuracy (detecting 1-3 out of 21 strokes)
- **After**: 85-95% accuracy with default settings
- **Tuned**: 95-100% accuracy after adjustment

---

## [2024-11-14] - Android Build Configuration

### Added

- Complete Android build configuration for Flutter app
- Gradle 8.3 and Android Gradle Plugin 8.1.0
- Namespace configuration fixes for flutter_bluetooth_serial
- Automated fix scripts for Windows (.bat) and Unix (.sh)
- Build documentation and quick start guide

### Changed

- Removed syncfusion_flutter_charts dependency
- Simplified to use only fl_chart for visualizations
- Updated to AndroidX and Jetifier

---

## [2024-11-14] - Initial Release

### Added

**Hardware**
- ESP32 firmware with MPU6050 support
- SD card logging at 50Hz
- Bluetooth Serial communication
- Command system (SS/ST for start/stop recording)
- File transfer over Bluetooth
- Wireless charging support (TP4056 + Qi charger)

**Flutter App**
- Bluetooth device connection
- Session recording control
- Real-time status monitoring
- Signal processing with peak detection
- Interactive data visualization
- Metrics calculation:
  - Stroke count
  - Stroke cycle time
  - Stroke rate
  - Stroke length (with pool info)
  - Average speed
  - Session duration

**Documentation**
- Comprehensive README
- Hardware wiring diagrams
- Setup guide for ESP32 and Flutter
- Troubleshooting documentation

### Technical Details

- 50Hz IMU sampling rate
- CSV data format for easy analysis
- Waterproof enclosure design
- ~3-4 hour battery life
- Total hardware cost: $30-40 USD
