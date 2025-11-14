# Swimming Stroke Tracker - Wiring Diagram

## Hardware Components

1. **ESP32 Development Board**
2. **MPU6050 IMU Sensor** (Accelerometer + Gyroscope)
3. **MicroSD Card Module**
4. **TP4056 Charging Module**
5. **18650 Li-ion Battery (3.7V, 3000mAh recommended)**
6. **Wireless 5V 1A Charger**
7. **Power Switch (SPDT)**
8. **Waterproof Box**
9. **Waist Belt**

---

## Pin Connections

### ESP32 to MPU6050 (I2C Connection)

| MPU6050 Pin | ESP32 Pin | Description          |
|-------------|-----------|----------------------|
| VCC         | 3.3V      | Power (3.3V)         |
| GND         | GND       | Ground               |
| SDA         | GPIO 21   | I2C Data             |
| SCL         | GPIO 22   | I2C Clock            |

### ESP32 to SD Card Module (SPI Connection)

| SD Module Pin | ESP32 Pin | Description        |
|---------------|-----------|-------------------|
| VCC           | 3.3V      | Power (3.3V)       |
| GND           | GND       | Ground             |
| MISO          | GPIO 19   | Master In Slave Out|
| MOSI          | GPIO 23   | Master Out Slave In|
| SCK           | GPIO 18   | SPI Clock          |
| CS            | GPIO 4    | Chip Select        |

### Power Circuit

```
18650 Battery (+) -----> [Switch] -----> TP4056 (BAT+)
18650 Battery (-) ----------------> TP4056 (BAT-)

TP4056 (OUT+) -----> ESP32 (VIN/5V)
TP4056 (OUT-) -----> ESP32 (GND)

Wireless Charger (5V) -----> TP4056 (IN+)
Wireless Charger (GND) ----> TP4056 (IN-)
```

---

## Detailed Wiring Schematic

```
                                  +------------------+
                                  |                  |
                                  |  18650 Battery   |
                                  |   (3.7V 3000mAh) |
                                  |                  |
                                  +--------+---------+
                                           |
                                        [Switch]
                                           |
                                  +--------+---------+
                                  |                  |
                                  |    TP4056        |
                                  |  Charging Module |
                                  |                  |
           Wireless 5V Charger -->| IN+        OUT+ |---+
                          GND -->| IN-        OUT- |   |
                                  +------------------+   |
                                                         |
                                  +----------------------+
                                  |
                           +------+------+
                           |             |
                           |   ESP32     |
                           |             |
                           +------+------+
                                  |
                    +-------------+-------------+
                    |                           |
            +-------+-------+           +-------+-------+
            |               |           |               |
            |   MPU6050     |           | SD Card Module|
            |               |           |               |
            | VCC --> 3.3V  |           | VCC --> 3.3V  |
            | GND --> GND   |           | GND --> GND   |
            | SDA --> IO21  |           | MISO --> IO19 |
            | SCL --> IO22  |           | MOSI --> IO23 |
            |               |           | SCK  --> IO18 |
            +---------------+           | CS   --> IO4  |
                                        +---------------+
```

---

## Assembly Instructions

### 1. Power Circuit Assembly

1. **Connect Battery to TP4056:**
   - Battery positive (+) → TP4056 BAT+
   - Battery negative (-) → TP4056 BAT-

2. **Install Power Switch:**
   - Place switch between battery and TP4056 module
   - This allows you to turn the device on/off

3. **Connect TP4056 Output to ESP32:**
   - TP4056 OUT+ → ESP32 VIN (or 5V pin)
   - TP4056 OUT- → ESP32 GND

4. **Wireless Charging:**
   - Connect wireless charger receiver coil to TP4056 IN+ and IN-
   - The TP4056 will handle battery charging automatically

### 2. Sensor Connections

1. **MPU6050 to ESP32:**
   - Connect using I2C protocol (4 wires: VCC, GND, SDA, SCL)
   - Use short wires (< 10cm) for reliable I2C communication
   - Optional: Add 4.7kΩ pull-up resistors on SDA and SCL lines

2. **SD Card Module to ESP32:**
   - Connect using SPI protocol (6 wires)
   - Use quality SD card (Class 10 recommended)
   - Format SD card as FAT32 before first use

### 3. Waterproofing

1. **Component Placement:**
   - Place all electronics in waterproof box
   - Ensure MPU6050 is securely mounted (orientation matters!)
   - Use foam padding to prevent movement during swimming

2. **Cable Management:**
   - Keep all connections inside the waterproof box
   - Use hot glue or silicone sealant on cable entry points
   - Test waterproofing before swimming!

3. **Mounting:**
   - Attach waterproof box to waist belt
   - Position at lower back for best swimming stroke detection
   - Ensure belt is tight but comfortable

### 4. Testing Before Swimming

1. **Power Test:**
   - Turn on device
   - Check LED indicators on ESP32 and TP4056

2. **Bluetooth Test:**
   - Device should appear as "SwimStrokeTracker"
   - Connect from your phone

3. **Sensor Test:**
   - Start recording
   - Move the device around
   - Stop recording and check if data was saved

4. **Waterproof Test:**
   - Seal the box completely
   - Submerge in water for 5 minutes (WITHOUT electronics first!)
   - Check for water ingress
   - If dry, repeat with electronics inside (still in air, not swimming)

---

## Troubleshooting

### MPU6050 Not Detected
- Check I2C connections (SDA, SCL)
- Verify 3.3V power supply
- Try adding pull-up resistors (4.7kΩ) on SDA and SCL

### SD Card Failure
- Ensure SD card is formatted as FAT32
- Check SPI connections
- Try a different SD card (some cards are incompatible)
- Verify CS pin is connected to GPIO 4

### Bluetooth Not Connecting
- Restart ESP32
- Unpair and re-pair device on phone
- Check if device name appears as "SwimStrokeTracker"

### Battery Not Charging
- Check wireless charger alignment
- Verify TP4056 connections
- Check battery polarity
- LED on TP4056 should indicate charging status:
  - Red: Charging
  - Blue/Green: Fully charged

### Water Damage
- **IMMEDIATELY** remove battery
- Dry all components with compressed air
- Leave in rice or silica gel for 24-48 hours
- Check for corrosion on pins
- Test each component individually before reassembly

---

## Safety Notes

⚠️ **Important Safety Information:**

1. **Battery Safety:**
   - Use protected 18650 cells with built-in protection circuits
   - Never use damaged or swollen batteries
   - Don't over-discharge (TP4056 handles this)

2. **Waterproofing:**
   - Test thoroughly before use
   - Use marine-grade silicone sealant
   - Check seals regularly

3. **Swimming Safety:**
   - Device is for lap swimming in pools only
   - Not for open water swimming
   - Ensure belt is secure but not too tight

4. **Charging:**
   - Don't charge while swimming (obviously!)
   - Use approved wireless charger only
   - Don't leave charging unattended for extended periods

---

## Recommended Tools and Materials

- Soldering iron and solder
- Wire strippers
- Heat shrink tubing
- Hot glue gun or marine silicone sealant
- Multimeter (for testing connections)
- Small screwdriver set
- Zip ties or velcro straps
