# Swimming Stroke Tracker - Wiring Diagram

## Hardware Components

1. **ESP32 Development Board**
2. **MPU6050 IMU Sensor** (Accelerometer + Gyroscope)
3. **MicroSD Card Module**
4. **TP4056 Charging Module**
5. **18650 Li-ion Battery (3.7V, 3000mAh recommended)**
6. **Wireless Qi Charger (5V 1A)** - TX (transmitter/charging pad) and RX (receiver coil)
7. **Power Switch (SPDT)**
8. **Neodymium Magnets (6mm × 2-3mm, N35 grade)** - 8 pieces (4 for device, 4 for charging dock)
9. **Waterproof Box**
10. **Waist Belt**

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

Wireless Qi RX Coil (5V) -----> TP4056 (IN+)
Wireless Qi RX Coil (GND) ----> TP4056 (IN-)
```

**Important:** The Qi receiver (RX) coil is mounted inside the waterproof device. The Qi transmitter (TX) coil is in the charging dock/pad.

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

## Magnetic Alignment System for Wireless Charging

### Overview

To ensure proper alignment between the charging dock (TX) and the waterproof device (RX), we use a magnetic alignment system with 4 magnets on each side. **The magnets are strategically placed OUTSIDE the wireless charging coil area to avoid interference.**

### Magnet Placement Diagram

#### Device Side (RX - Receiver)
```
┌─────────────────────────────────────────┐
│    DEVICE (Top View - Back Panel)      │
│    Waterproof Box with RX Coil          │
│                                         │
│  [M1]                          [M2]    │  ← Magnets at corners
│   N↑                            S↓     │     (15-20mm from coil center)
│                                         │
│         ┌─────────────────┐            │
│         │                 │            │
│         │   Qi RX Coil    │            │  ← Wireless receiver coil
│         │   (centered)    │            │     (connects to TP4056 IN+/IN-)
│         │                 │            │
│         └─────────────────┘            │
│                                         │
│  [M3]                          [M4]    │  ← Magnets at corners
│   S↓                            N↑     │
│                                         │
└─────────────────────────────────────────┘
     Other components inside:
     - ESP32, MPU6050, SD Card
     - TP4056, 18650 Battery, Switch
```

#### Charging Dock Side (TX - Transmitter)
```
┌─────────────────────────────────────────┐
│   CHARGING DOCK (Top View - Top Panel) │
│   Qi Transmitter Pad                    │
│                                         │
│  [M1]                          [M2]    │  ← Magnets at corners
│   S↓                            N↑     │     (OPPOSITE polarity to RX)
│                                         │     This creates attraction!
│         ┌─────────────────┐            │
│         │                 │            │
│         │   Qi TX Coil    │            │  ← Wireless transmitter coil
│         │   (centered)    │            │     (connects to 5V power supply)
│         │                 │            │
│         └─────────────────┘            │
│                                         │
│  [M3]                          [M4]    │  ← Magnets at corners
│   N↑                            S↓     │
│                                         │
└─────────────────────────────────────────┘
     5V 1A Power Input
```

**Polarity Pattern:**
- **Device (RX)**: N - S - S - N (clockwise from top-left)
- **Charging Dock (TX)**: S - N - N - S (opposite polarity creates attraction)
- When aligned, opposite poles attract: N↔S alignment on all 4 corners

### Side View - Magnet & Coil Positioning
```
DEVICE (RX)                        CHARGING DOCK (TX)
┌──────────────────┐              ┌──────────────────┐
│   Waterproof     │              │   Dock Base      │
│      Box         │              │                  │
│  ╔═══════════╗   │              │  ╔═══════════╗   │
│  ║           ║   │              │  ║           ║   │
│  ║  Qi RX    ║◄──┼──Air Gap────┼─►║  Qi TX    ║   │ ← 2-5mm gap ideal
│  ║  Coil     ║   │   (2-5mm)   │  ║  Coil     ║   │
│  ╚═══════════╝   │              │  ╚═══════════╝   │
│                  │              │                  │
│ [M]  15-20mm [M] │              │ [M]  15-20mm [M] │ ← Magnets outside
│  ↕          ↕    │ <<MAGNETIC>> │  ↕          ↕    │    coil area
│ Magnet    Magnet │ ATTRACTION!  │ Magnet    Magnet │
└──────────────────┘              └──────────────────┘
```

### Magnet Specifications

| Parameter | Specification | Notes |
|-----------|---------------|-------|
| **Type** | Neodymium (NdFeB) | Strong, compact rare-earth magnets |
| **Grade** | N35 or N42 | N35 is sufficient; N52 is overkill |
| **Shape** | Disc / Cylinder | Easier to embed than rectangular |
| **Diameter** | 6mm (±0.5mm) | Optimal for small devices |
| **Thickness** | 2-3mm | Balance between strength and profile |
| **Quantity** | 8 pieces total | 4 for device + 4 for charging dock |
| **Coating** | Ni-Cu-Ni (Nickel) | Corrosion resistant for waterproofing |
| **Pull Force** | ~1-2 kg (per magnet) | Sufficient for alignment |

### Placement Guidelines

#### Critical Distances
```
Device/Dock Dimensions (Example: 80mm × 60mm box)

        60mm
   ┌──────────┐
   │ M      M │   ← 10mm from edge
   │          │
   │   [Coil] │   ← Coil center: 40mm × 30mm from corner
80 │    25mm  │      Magnets: 15-20mm from coil center
mm │          │
   │ M      M │
   └──────────┘
```

**Placement Rules:**
1. **Minimum 15mm from coil center** (measured edge-to-edge)
2. **5-10mm from device edge** (for structural integrity)
3. **Symmetric placement** (equal distances from center)
4. **All 4 magnets at same depth** (flush with surface)

#### Installation Depth
- **Device side**: Embed magnets flush with **BACK PANEL** (charging surface)
- **Dock side**: Embed magnets flush with **TOP PANEL** (where device sits)
- Use 6.5mm diameter drill bit for 6mm magnets (tight friction fit)
- Depth: 2.5-3.5mm holes (magnet should be flush or 0.5mm recessed)

### Why This Design Works

| Aspect | Explanation |
|--------|-------------|
| **No Electrical Interference** | Permanent magnets create static (DC) field; wireless charging uses high-frequency AC field (110-205 kHz for Qi). They don't interact significantly. |
| **TP4056 is Immune** | TP4056 is a fully electronic IC with no magnetic sensors or components affected by magnetic fields. |
| **Field Strength at Coil** | At 15-20mm distance, magnetic field from 6mm N35 magnets is <1% at coil center (inverse cube law). |
| **Ferrite Shielding** | Qi coils have ferrite backing that directs electromagnetic flux and shields from nearby static magnetic fields. |
| **Alignment Force** | 4 magnets × 1-2kg pull = 4-8kg total holding force - strong enough for secure alignment without excessive force. |

### What to AVOID ⚠️

| ❌ Don't Do This | ✅ Do This Instead |
|------------------|-------------------|
| Place magnets directly under/on coil | Keep 15-20mm minimum distance from coil center |
| Use magnets larger than 10mm diameter | Use 6mm diameter magnets |
| Use magnets thicker than 4mm | Use 2-3mm thick magnets |
| Place magnets between TX and RX coils | Place magnets at corners/edges only |
| Use ferromagnetic screws near coils (steel, iron) | Use brass, aluminum, or stainless 316 screws |
| Use super-strong N52 grade magnets | Use N35 or N42 grade (sufficient strength) |
| Random/asymmetric magnet placement | Symmetric 4-corner placement pattern |

### Wireless Charging Efficiency Expectations

- **Without magnets baseline**: 5V @ 500-800mA to TP4056 (2.5-4W)
- **With properly placed magnets**: 5V @ 450-800mA to TP4056 (2.25-4W)
- **Expected efficiency loss**: <5-10% (acceptable)
- **Charging time**: 3-5 hours for 3000mAh battery (both cases)

**If efficiency loss >15%**: Magnets are too close to coil or too strong → reposition or use smaller magnets.

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

### 3. Magnet Installation

#### A. Device Side (RX - Waterproof Box)

**Tools Needed:**
- Drill with 6.5mm bit
- Ruler or calipers
- Marker or pencil
- Superglue or epoxy (waterproof)
- Tape (to mark polarity)

**Steps:**

1. **Mark Magnet Positions:**
   - Measure your waterproof box dimensions
   - Mark 4 positions at corners of the **BACK PANEL** (charging surface)
   - Distance from edge: 5-10mm
   - Distance from center (where Qi RX coil will be): minimum 15mm
   - Example for 80×60mm box: mark at (10,10), (70,10), (10,50), (70,50)

2. **Drill Magnet Holes:**
   - Use 6.5mm drill bit for 6mm magnets (tight friction fit)
   - Drill depth: 2.5-3mm (measure and mark drill bit with tape)
   - Drill perpendicular to surface (straight down)
   - Clean holes of debris

3. **Determine Polarity Pattern:**
   - Mark magnets with tape: N-S-S-N pattern (clockwise from top-left)
   - Use another magnet to test polarity (attraction/repulsion)
   - Label magnets M1, M2, M3, M4

4. **Install Magnets:**
   - Apply small amount of waterproof epoxy to hole
   - Insert magnet with correct polarity (check marking)
   - Magnet should be flush or 0.5mm recessed
   - Verify polarity before epoxy sets (use test magnet)
   - Let cure for 24 hours

5. **Seal Magnets:**
   - Once epoxy is cured, apply thin layer of silicone sealant over magnets
   - Smooth with finger or tool (flush with surface)
   - This ensures waterproofing

6. **Test Polarity:**
   - Use test magnet to verify all 4 magnets have correct polarity
   - Pattern should be: N-S-S-N (clockwise)

#### B. Charging Dock Side (TX - Base Plate)

**Steps:**

1. **Prepare Charging Dock Base:**
   - Use plastic or wood base (non-conductive, non-ferromagnetic)
   - Dimensions: at least 100×80mm (larger than device)
   - Thickness: 5-10mm

2. **Mount Qi TX Coil:**
   - Center the Qi transmitter coil on base plate
   - Secure with double-sided tape or screws (non-ferromagnetic!)
   - Connect 5V 1A power supply to TX coil

3. **Mark Magnet Positions:**
   - Place device (with RX magnets installed) on charging dock
   - The device magnets will show you EXACTLY where to place dock magnets
   - Mark these 4 positions with pencil
   - Verify distance from TX coil center is ≥15mm

4. **Drill and Install Magnets:**
   - Same process as device side
   - **CRITICAL**: Use OPPOSITE polarity pattern: S-N-N-S (clockwise)
   - This creates attraction with device magnets
   - To verify: device should snap into alignment when placed on dock

5. **Test Alignment:**
   - Place device on dock - should snap into alignment
   - Verify Qi coils are aligned (RX directly over TX)
   - Magnets should provide ~4-8kg holding force

6. **Seal Magnets (Optional for Dock):**
   - Apply epoxy or hot glue over magnets
   - Not strictly necessary for dock (not waterproof)
   - But prevents magnets from falling out over time

#### C. Polarity Verification Table

| Position | Device (RX) Polarity | Dock (TX) Polarity | Result |
|----------|---------------------|-------------------|--------|
| M1 (Top-Left) | North (N) ↑ | South (S) ↓ | Attract ✓ |
| M2 (Top-Right) | South (S) ↓ | North (N) ↑ | Attract ✓ |
| M3 (Bottom-Left) | South (S) ↓ | North (N) ↑ | Attract ✓ |
| M4 (Bottom-Right) | North (N) ↑ | South (S) ↓ | Attract ✓ |

**How to Test Polarity:**
- Use a compass or labeled test magnet
- Hold magnet near installed magnet - should attract or repel based on pattern
- If wrong polarity: remove magnet, flip, reinstall

#### D. Troubleshooting Magnet Installation

| Problem | Cause | Solution |
|---------|-------|----------|
| Device doesn't align | Wrong polarity | Check polarity with test magnet; reinstall if needed |
| Device repels from dock | All magnets reversed | Flip all magnets on one side (device OR dock) |
| Weak holding force | Magnets too small/weak | Use slightly larger (8mm) or stronger (N42) magnets |
| Device wobbles | Magnets not at same depth | Ensure all 4 magnets are flush with surface |
| Charging efficiency low | Magnets too close to coil | Reposition magnets farther from center (20-25mm) |
| Magnet fell out | Insufficient adhesive | Use more epoxy; consider mechanical retention |

### 4. Waterproofing

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

### 5. Testing Before Swimming

#### 1. Magnet Alignment Test

**Purpose:** Verify magnetic alignment system works correctly

**Steps:**
1. **Alignment Test:**
   - Hold device 10cm above charging dock
   - Lower device slowly toward dock
   - Device should "snap" into alignment when ~2-3cm away
   - Verify all 4 corners align simultaneously

2. **Holding Force Test:**
   - Place device on charging dock (magnetically aligned)
   - Try to slide device horizontally
   - Should require moderate force to overcome magnetic hold
   - Device should not easily fall off if dock is tilted 45°

3. **Polarity Test:**
   - Device should attract to dock (not repel!)
   - If device repels, check polarity pattern (see troubleshooting)
   - All 4 corners should have equal attraction force

**Expected Results:**
- ✓ Strong magnetic snap when aligning
- ✓ Device centers automatically on dock
- ✓ ~4-8kg total holding force
- ✓ No repulsion at any corner

#### 2. Wireless Charging Test

**Purpose:** Verify wireless charging works and measure efficiency

**Equipment Needed:**
- Multimeter (to measure charging current)
- Timer
- Charging dock with 5V 1A power supply

**Steps:**

1. **Initial Charging Test:**
   - Discharge battery to ~50% (use device for 1-2 hours)
   - Place device on charging dock (magnetic alignment)
   - Check TP4056 LED indicators:
     - Red LED = Charging (GOOD!)
     - Blue/Green LED = Fully charged
     - No LED = Problem (check connections)

2. **Measure Charging Current:**
   - Use multimeter in series with TP4056 input (IN+ line)
   - Expected current: 450-800mA @ 5V
   - If current <300mA: check alignment or investigate interference
   - If current >1A: possible short circuit (STOP immediately)

3. **Alignment Tolerance Test:**
   - Start charging (device aligned, red LED on)
   - Gently shift device 5mm left/right/forward/backward
   - Charging should continue (red LED stays on)
   - Maximum misalignment tolerance: ~8-10mm before charging stops

4. **Efficiency Comparison (Optional):**
   - **Baseline (no magnets)**: Measure charging current
   - **With magnets**: Measure charging current
   - Efficiency loss should be <10%
   - Example: 700mA baseline → 630-700mA with magnets = acceptable

5. **Full Charge Time Test:**
   - Fully discharge battery (device shuts off)
   - Place on charging dock
   - Time until TP4056 LED changes to blue/green
   - Expected time: 3-5 hours for 3000mAh battery
   - If >6 hours: efficiency may be low (check magnet placement)

**Expected Results:**
- ✓ TP4056 red LED turns on when charging
- ✓ Charging current: 450-800mA @ 5V
- ✓ Alignment tolerance: ±8-10mm
- ✓ Charging efficiency loss: <10%
- ✓ Full charge time: 3-5 hours

#### 3. Power Circuit Test

1. **Power Test:**
   - Turn on device using power switch
   - Check LED indicators on ESP32 and TP4056
   - Verify ESP32 powers on (LED blinks)
   - Measure ESP32 VIN: should be ~4.0-4.2V (from battery)

2. **Battery Voltage Test:**
   - Use multimeter to measure battery voltage at TP4056 BAT+/BAT-
   - Fully charged: ~4.15-4.20V
   - Normal operation: 3.7-4.1V
   - Low battery: <3.5V (recharge immediately)
   - Critical: <3.2V (may damage battery)

#### 4. Bluetooth Test

1. **Connection Test:**
   - Device should appear as "SwimStrokeTracker"
   - Connect from your phone
   - Verify connection is stable

#### 5. Sensor Test

1. **IMU Test:**
   - Start recording
   - Move the device around
   - Stop recording and check if data was saved
   - Verify accelerometer and gyroscope readings are reasonable

#### 6. Waterproof Test

**CRITICAL: Test waterproofing BEFORE putting electronics inside!**

1. **Initial Waterproof Test (Empty Box):**
   - Place tissue paper inside empty waterproof box
   - Seal the box completely
   - Submerge in water for 5 minutes
   - Open box and check if tissue is dry
   - **If wet**: Fix seals before proceeding!

2. **Magnet Seal Test:**
   - Check that magnets are fully sealed with epoxy/silicone
   - No gaps around magnets (water entry point!)
   - Apply additional sealant if needed

3. **Electronics Waterproof Test:**
   - After confirming box is dry (step 1)
   - Install all electronics and seal box
   - Submerge in shallow water (10cm) for 10 minutes
   - Do NOT turn on device while submerged (this test only)
   - Remove from water, open box, check for moisture
   - **If dry**: Proceed to final test
   - **If wet**: Identify leak point, reseal, repeat

4. **Final Waterproof Test (Powered):**
   - Seal box with electronics inside, device turned ON
   - Submerge in water (10cm depth) for 5 minutes
   - Device should continue operating (Bluetooth connected)
   - Remove from water, dry exterior, open box
   - Check for any moisture ingress

**Expected Results:**
- ✓ No water ingress after 5+ minutes submersion
- ✓ Magnets fully sealed and waterproof
- ✓ Device continues operating while submerged
- ✓ All seals intact after multiple tests

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

### Battery Not Charging via Wireless Charging
- **Check magnetic alignment**: Device should snap into place on dock
- **Verify coil alignment**: RX and TX coils should be centered (within ±10mm)
- **Test with multimeter**: Measure voltage at TP4056 IN+/IN- (should be ~5V when aligned)
- **Check air gap**: Distance between RX and TX coils should be 2-5mm (not >10mm)
- **Verify TP4056 connections**: IN+ to Qi RX (+), IN- to Qi RX (-)
- **Check battery polarity**: BAT+ to battery (+), BAT- to battery (-)
- **LED indicators on TP4056**:
  - Red: Charging (normal)
  - Blue/Green: Fully charged
  - No LED: No power from wireless charger (check alignment/connections)
- **Test charging pad**: Use multimeter to verify TX coil outputs ~5V
- **Magnet interference check**: If charging current is very low (<300mA), magnets may be too close to coils - reposition farther from center

### Magnetic Alignment Issues
- **Device repels from dock**: Wrong polarity pattern - flip all magnets on one side (device OR dock, not both)
- **Weak magnetic hold**: Use stronger magnets (N42 instead of N35) or slightly larger (8mm diameter)
- **Device doesn't snap into alignment**: Magnets may be too far apart or too weak - verify 4-8kg total holding force
- **Device wobbles on dock**: Magnets not flush with surface - ensure all 4 magnets at same depth
- **One corner doesn't align**: One magnet may have wrong polarity - test each magnet individually with test magnet
- **Magnets fell out**: Insufficient adhesive or wrong hole size - use more epoxy and ensure tight friction fit (6.5mm hole for 6mm magnet)

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

### Electronics Tools
- Soldering iron and solder (60/40 tin-lead or lead-free)
- Wire strippers
- Heat shrink tubing (various sizes)
- Multimeter (for testing voltage, current, continuity)
- Small screwdriver set (Phillips and flathead)
- Wire cutters
- Helping hands / PCB holder

### Magnet Installation Tools
- Drill with 6.5mm drill bit (for 6mm magnets)
- Ruler or digital calipers (for precise measurements)
- Marker or pencil (for marking positions)
- Masking tape (for marking polarity and drill depth)
- Compass or test magnet (for polarity verification)
- Cotton swabs (for cleaning holes)

### Adhesives and Sealants
- **Waterproof epoxy** (2-part epoxy, marine-grade) - for magnets
- **Marine silicone sealant** - for waterproofing seals
- Hot glue gun (optional, for non-waterproof areas)
- Super glue (cyanoacrylate) - for quick fixes

### Mounting and Assembly
- Zip ties or velcro straps
- Double-sided tape (strong adhesive)
- Foam padding (prevents component movement)
- Non-ferromagnetic screws (brass, aluminum, or stainless 316)

### Magnets and Wireless Charging Components
- **8× Neodymium magnets** (6mm diameter × 2-3mm thick, N35 or N42 grade, Ni-Cu-Ni coated)
- **Qi wireless charging RX coil** (5V output, with built-in rectifier)
- **Qi wireless charging TX pad** (5V 1A input)
- 5V 1A power supply for charging dock

### Testing Equipment
- Multimeter (voltage, current, continuity)
- Timer or stopwatch
- Tissue paper (for waterproof testing)
- Container of water (for submersion testing)

### Where to Buy Magnets
**Recommended Suppliers:**
- **Amazon**: Search "neodymium magnets 6mm x 2mm N35" (~$8-12 for 50-100 pieces)
- **eBay**: Bulk neodymium magnets (cheaper in large quantities)
- **AliExpress**: Very cheap but longer shipping (2-4 weeks)
- **K&J Magnetics** (USA): High quality, precise specifications
- **Supermagnete** (Europe): Fast shipping in EU

**Example Search Terms:**
- "Neodymium disc magnet 6mm x 2mm N35 Ni"
- "NdFeB cylindrical magnet 6x2mm nickel coated"
- "Rare earth magnet 6mm diameter 2mm thick"

**What to Verify When Purchasing:**
- Diameter: 6mm (±0.2mm tolerance acceptable)
- Thickness: 2-3mm
- Grade: N35, N38, or N42 (avoid N52 - too strong)
- Coating: Ni-Cu-Ni (nickel, prevents rust)
- Shape: Disc/cylinder (not rectangular)
- Quantity: Buy at least 10-12 pieces (have spares for mistakes)
