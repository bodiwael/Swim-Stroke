# 🏊‍♂️ Swimming Stroke Tracker

A complete IoT system for tracking and analyzing swimming strokes using a waist-mounted IMU sensor and mobile app.

## 📋 Overview

This project provides a **waterproof, wireless swimming stroke tracker** that measures:

- ✅ **Stroke Count** - Total number of strokes per session
- ✅ **Stroke Cycle Time** - Time between consecutive strokes
- ✅ **Stroke Length** - Distance covered per stroke (requires pool length input)
- ✅ **Stroke Rate** - Strokes per minute
- ✅ **Session Duration** - Total swimming time
- ✅ **Average Speed** - Swimming velocity (when pool info provided)
- ✅ **Lap Tracking** - Manual lap count input for accurate distance

## 🎯 Key Features

### Hardware
- **Waist-mounted device** with waterproof enclosure
- **MPU6050 IMU sensor** for motion detection
- **SD card storage** for offline data recording
- **Wireless charging** for convenience
- **Bluetooth connectivity** for data transfer
- **Long battery life** (3-4 hours continuous recording)

### Software
- **Automatic stroke detection** using signal processing
- **Peak detection algorithm** with adaptive thresholding
- **Signal preprocessing** with noise filtering
- **Calibration periods** (removes first/last 10 seconds)
- **Interactive charts** and visualizations
- **Session comparison** capabilities
- **Export data** for further analysis

## 🛠️ Hardware Components

| Component | Purpose | Notes |
|-----------|---------|-------|
| ESP32 | Microcontroller with Bluetooth | Main processing unit |
| MPU6050 | 6-axis IMU (Accel + Gyro) | Motion sensing |
| SD Card Module | Data storage | Supports up to 32GB |
| TP4056 | Battery charging circuit | With protection |
| 18650 Battery | Power source | 3.7V, 2000-3000mAh |
| Wireless Charger | Qi standard charging | 5V 1A |
| Waterproof Box | IP67+ enclosure | Must fit all components |
| Waist Belt | Mounting system | Adjustable, secure fit |

**Total Cost:** ~$30-40 USD

## ⚡ Power System & Wireless Charging

### Magnetic Alignment System

The device features a **magnetic alignment system** for effortless wireless charging:

- **Qi Wireless Charging** - 5V 1A, cable-free charging
- **Magnetic Auto-Alignment** - Device snaps into perfect position on charging dock
- **8 Neodymium Magnets** - 4 on device + 4 on charging dock (6mm × 2-3mm, N35 grade)
- **No Interference** - Magnets placed 15-20mm from Qi coils to maintain charging efficiency
- **Waterproof Sealed** - All magnets sealed with epoxy and silicone

### Power Circuit

```
18650 Battery (3.7V) → Power Switch → TP4056 → ESP32 (VIN)
                                        ↑
                                   Qi RX Coil (5V wireless charging)
```

### Battery Performance

- **Capacity:** 3000mAh 18650 Li-ion battery
- **Runtime:** 3-4 hours continuous recording @ 50Hz
- **Charging Time:** 3-5 hours (wireless charging)
- **Protection:** TP4056 with over-charge, over-discharge, and short-circuit protection

### Documentation

- **[📐 Wiring Diagram](docs/WIRING_DIAGRAM.md)** - Complete power circuit, magnet installation, and assembly instructions
- **[🎨 Visual Schematic](docs/power_system_schematic.html)** - Interactive HTML diagrams (open in browser)
- **[🔧 Setup Guide](docs/SETUP_GUIDE.md)** - Step-by-step hardware assembly and testing

**Key Features:**
- ✅ Magnetic snap-on charging (4-8kg holding force)
- ✅ No cables needed for charging
- ✅ Waterproof magnet installation with detailed instructions
- ✅ <10% charging efficiency loss with properly placed magnets
- ✅ Easy to build charging dock with standard Qi transmitter

## 📱 Mobile App

Built with **Flutter** for cross-platform support (Android/iOS):

- **Device connection** via Bluetooth
- **Real-time status** monitoring
- **Session recording** control
- **Data visualization** with interactive charts
- **Metrics calculation** and display
- **Session history** (planned feature)

## 🔧 How It Works

### Recording Flow

```
1. Connect app to ESP32 via Bluetooth
   ↓
2. Send "SS" command → Start recording
   ↓
3. Bluetooth disconnects (waterproof during swimming)
   ↓
4. ESP32 records MPU6050 data to SD card @ 50Hz
   ↓
5. After swimming, reconnect Bluetooth
   ↓
6. Send "ST" command → Stop recording & transfer file
   ↓
7. App processes data and displays results
```

### Signal Processing Pipeline

```
Raw IMU Data (6-axis: ax, ay, az, gx, gy, gz)
   ↓
Remove Calibration Periods (first/last 10 seconds)
   ↓
Calculate Rotation Magnitude (√(gx² + gy² + gz²))
   ↓
Apply Low-Pass Filter (moving average, removes noise)
   ↓
Normalize Signal (0-1 range)
   ↓
Peak Detection (adaptive threshold, minimum distance)
   ↓
Calculate Metrics (stroke count, times, rates)
```

### Stroke Detection Algorithm

1. **Rotation Signal:** Uses gyroscope magnitude as primary indicator
2. **Adaptive Threshold:** Based on signal mean and variance
3. **Peak Detection:** Identifies local maxima above threshold
4. **Minimum Distance:** Prevents double-counting (500ms default)
5. **Validation:** Filters false positives

## 📁 Project Structure

```
Swim-Stroke/
├── esp32_firmware/           # ESP32 Arduino code
│   ├── swim_stroke_tracker.ino
│   └── platformio.ini
├── flutter_app/              # Mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── recording_screen.dart
│   │   │   └── results_screen.dart
│   │   └── services/
│   │       ├── bluetooth_service.dart
│   │       └── data_processor.dart
│   └── pubspec.yaml
├── docs/
│   ├── WIRING_DIAGRAM.md          # Hardware connections & magnet installation
│   ├── power_system_schematic.html # Interactive visual diagrams
│   └── SETUP_GUIDE.md             # Detailed setup instructions
└── README.md                       # This file
```

## 🚀 Quick Start

### 1. Hardware Assembly

See [docs/WIRING_DIAGRAM.md](docs/WIRING_DIAGRAM.md) for detailed wiring instructions and [docs/power_system_schematic.html](docs/power_system_schematic.html) for visual diagrams.

**Quick Summary:**
- Connect MPU6050 to ESP32 I2C (SDA=21, SCL=22)
- Connect SD Module to ESP32 SPI (CS=4, MOSI=23, MISO=19, SCK=18)
- Wire battery → Switch → TP4056 → ESP32
- Connect Qi RX coil to TP4056 (IN+/IN−) for wireless charging
- Install 4 magnets on device back panel (15-20mm from Qi coil)
- Build charging dock with Qi TX coil and 4 magnets (opposite polarity)
- Assemble in waterproof box with proper sealing

### 2. Flash ESP32 Firmware

**Using Arduino IDE:**
```bash
1. Install ESP32 board support
2. Install MPU6050 library
3. Open esp32_firmware/swim_stroke_tracker.ino
4. Select board: ESP32 Dev Module
5. Upload
```

**Using PlatformIO:**
```bash
cd esp32_firmware
pio run --target upload
```

### 3. Build Mobile App

```bash
cd flutter_app
flutter pub get
flutter run
```

Or build release APK:
```bash
flutter build apk --release
```

### 4. First Use

1. Pair "SwimStrokeTracker" in Bluetooth settings
2. Open app and connect to device
3. Start new session
4. Start recording (wait 10 sec before swimming)
5. Swim your laps
6. Wait 10 sec, then stop recording
7. View results!

## 📊 Metrics Explained

### Basic Metrics (No Pool Info Required)

- **Total Strokes:** Count of detected stroke cycles
- **Session Duration:** Total time (minus calibration periods)
- **Average Stroke Time:** Mean time between strokes
- **Stroke Rate:** Strokes per minute (cadence)

### Advanced Metrics (Requires Pool Length Input)

- **Stroke Length:** Distance per stroke = (Pool Length × Laps) / Total Strokes
- **Total Distance:** Pool Length × Number of Laps
- **Average Speed:** Distance / Time
- **Pace:** Time per 100m or 100yd

### Why Waist-Mounted?

- **Consistent Movement:** Core rotation is consistent across all swimming strokes
- **Less Interference:** Doesn't affect arm/hand movement
- **Better Signal:** Clear rotational patterns for stroke detection
- **Waterproofing:** Easier to seal and protect
- **Comfort:** Less restrictive than wrist-mounted devices

## 🔬 Technical Details

### Sampling Rate
- **50 Hz (20ms interval)** - Good balance of accuracy and battery life
- Sufficient for stroke detection (typical stroke: 1-2 seconds)

### Storage
- ~720 KB per hour of recording (CSV format)
- 8GB SD card = ~11,000 hours of data

### Battery Life
- 18650 (3000mAh) = ~3-4 hours continuous recording
- Sufficient for typical training sessions

### Waterproofing
- IP67+ rated enclosure required
- Test thoroughly before pool use
- Silicone sealant on all openings

## 🎓 Signal Processing Details

### Calibration Periods (10 seconds each)

**Why Remove First 10 Seconds?**
- Allows swimmer to enter water
- Sensor stabilization time
- Removes entry movements

**Why Remove Last 10 Seconds?**
- Allows swimmer to exit water
- Removes wall touch and exit movements
- Cleaner data for analysis

### Peak Detection Parameters

Located in `flutter_app/lib/services/data_processor.dart`:

```dart
// Adjust these for your swimming style:
static const double peakThreshold = 0.6;  // 0.4-0.8
static const int minPeakDistance = 500;   // 300-1000ms
```

**Tuning Guide:**
- **Fast swimmers:** Decrease minPeakDistance (300-400ms)
- **Slow swimmers:** Increase minPeakDistance (700-1000ms)
- **More sensitivity:** Decrease peakThreshold (0.4-0.5)
- **Less noise:** Increase peakThreshold (0.7-0.8)

## 📈 Future Improvements

### Planned Features
- [ ] Session history and comparison
- [ ] Export to CSV/JSON
- [ ] Cloud sync
- [ ] Training plans and goals
- [ ] Stroke type classification (ML model)
- [ ] Turn detection (automatic lap counting)
- [ ] Real-time feedback (haptic)

### Hardware Enhancements
- [ ] Add wrist IMU for hand velocity
- [ ] Pressure sensor for depth/turn detection
- [ ] Smaller, custom PCB design
- [ ] Better waterproof enclosure

## 🐛 Troubleshooting

See [docs/SETUP_GUIDE.md](docs/SETUP_GUIDE.md#troubleshooting) for detailed troubleshooting steps.

**Common Issues:**
- **Device won't connect:** Restart ESP32, re-pair Bluetooth
- **No strokes detected:** Check device placement, adjust threshold
- **Inaccurate count:** Calibrate, ensure tight belt fit
- **SD card error:** Reformat as FAT32, try different card

## 📄 License

This project is open source and available under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

### Areas for Contribution
- Signal processing algorithms
- UI/UX improvements
- Hardware design optimization
- Documentation
- Testing and validation

## 📞 Support

For questions, issues, or suggestions:
- Open an issue on GitHub
- Check documentation in `/docs` folder
- Review code comments for implementation details

## 🙏 Acknowledgments

- MPU6050 library by Electronic Cats
- Flutter Bluetooth Serial plugin
- FL Chart for data visualization
- ESP32 community and documentation

---

**Built with ❤️ for swimmers who love data!**

Happy Swimming! 🏊‍♀️🏊‍♂️
