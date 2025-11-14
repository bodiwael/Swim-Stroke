# ESP32 Firmware - Swimming Stroke Tracker

## Required Libraries

Install these libraries before compiling:

### Using Arduino IDE

1. Go to **Sketch → Include Library → Manage Libraries**
2. Search and install:
   - **MPU6050** by Electronic Cats (v1.3.0+)

### Built-in Libraries (Already Available)

These are included with ESP32 board support:
- Wire (I2C communication)
- SPI (SD card communication)
- SD (SD card file operations)
- BluetoothSerial (Bluetooth Classic)

## Pin Configuration

```cpp
// I2C for MPU6050
#define MPU_SDA 21
#define MPU_SCL 22

// SPI for SD Card
#define SD_CS_PIN 4
// MOSI: GPIO 23 (default)
// MISO: GPIO 19 (default)
// SCK:  GPIO 18 (default)
```

## Board Settings (Arduino IDE)

- **Board:** ESP32 Dev Module
- **Upload Speed:** 921600
- **Flash Frequency:** 80MHz
- **Flash Mode:** QIO
- **Flash Size:** 4MB (32Mb)
- **Partition Scheme:** Default 4MB with spiffs
- **Core Debug Level:** None (or Info for debugging)
- **PSRAM:** Disabled

## Compilation

### Arduino IDE

1. Open `swim_stroke_tracker.ino`
2. Select correct board and port
3. Click **Upload** button
4. Monitor serial output at **115200 baud**

### PlatformIO

```bash
# Build
pio run

# Upload
pio run --target upload

# Monitor
pio device monitor -b 115200
```

## Testing

After upload, open Serial Monitor (115200 baud) and verify:

```
Initializing MPU6050...
MPU6050 connected successfully
Initializing SD card...
SD card initialized successfully
Bluetooth initialized - Device: SwimStrokeTracker
System ready!
```

## Bluetooth Commands

The device accepts these commands via Bluetooth Serial:

- `SS` - Start recording
- `ST` - Stop recording and send file
- `STATUS` - Get device status
- `DELETE` - Delete last recorded file

## Troubleshooting

### MPU6050 Not Detected
- Check I2C connections (SDA, SCL)
- Verify 3.3V power
- Add 4.7kΩ pull-up resistors

### SD Card Failed
- Ensure FAT32 format
- Check SPI connections
- Try different SD card
- Verify CS pin (GPIO 4)

### Bluetooth Not Visible
- Restart ESP32
- Check serial output for errors
- Ensure Bluetooth is enabled on phone

## Memory Usage

Typical compilation results:
- Flash: ~800KB / 1310KB (61%)
- RAM: ~40KB / 327KB (12%)

Plenty of room for future enhancements!
