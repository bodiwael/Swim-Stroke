# Stroke Detection Tuning Guide

## Problem Solved

The initial stroke detection was severely inaccurate, detecting only 1-3 strokes when there were actually 21. This has been fixed with an improved algorithm and real-time adjustment controls.

## What Was Fixed

### 1. **Critical Bug: Time vs Samples**
- **Problem**: `minPeakDistance = 500` was treated as SAMPLES, not milliseconds
- At 50Hz sampling, 500 samples = 10 seconds between strokes!
- **Fix**: Now uses milliseconds (800ms default) and converts to samples correctly

### 2. **Calibration Too Aggressive**
- **Problem**: Fixed 10-second calibration removed most data from short tests
- Example: 30-second test - 20 seconds removed = only 10 seconds analyzed
- **Fix**: Adaptive calibration:
  - Sessions < 30s: 3 seconds
  - Sessions 30-60s: 5 seconds
  - Sessions > 60s: 8 seconds

### 3. **Threshold Too High**
- **Problem**: `peakThreshold = 0.6` missed most strokes
- **Fix**: Lowered to 0.25 with better statistical calculation

### 4. **Algorithm Improvements**
- Added median filter to remove noise spikes
- Combined gyroscope + accelerometer data
- Better peak detection (checks 4 neighbors instead of 2)
- Statistical threshold using standard deviation

## How to Use the New Sensitivity Controls

### Step 1: After Processing Results

Look at the detected stroke count in the results screen.

### Step 2: Tap the Tune Icon (⚙️)

In the top-right of the results screen, tap the slider/tune icon.

### Step 3: Adjust Parameters

**Sensitivity Slider (0.05 - 0.6)**
- **Lower** = More sensitive = Detects more strokes
- **Higher** = Less sensitive = Detects fewer strokes
- **Default**: 0.25
- **Recommended range**: 0.15 - 0.35

**Min Time Between Strokes (0.3 - 2.0 seconds)**
- Set based on your swimming speed
- **Fast swimmers** (competitive): 0.3 - 0.6 seconds
- **Medium pace** (fitness): 0.6 - 1.0 seconds
- **Slow/learning**: 1.0 - 1.5 seconds
- **Default**: 0.8 seconds

### Step 4: Apply and Check

1. Tap "Apply"
2. Data will be reprocessed immediately
3. Check the new stroke count
4. Repeat until accurate

## Tuning Examples

### Example 1: Detecting Too FEW Strokes

**Problem**: You did 21 strokes, app shows 8

**Solution**:
1. **Lower** the sensitivity slider (try 0.15)
2. **Reduce** min time between strokes (try 0.6s)
3. Apply and check

### Example 2: Detecting Too MANY Strokes

**Problem**: You did 21 strokes, app shows 45

**Solution**:
1. **Raise** the sensitivity slider (try 0.35-0.40)
2. **Increase** min time between strokes (try 1.0-1.2s)
3. Apply and check

### Example 3: Getting Doubles (Each Stroke Counted Twice)

**Problem**: Count is roughly 2x actual strokes

**Solution**:
1. **Increase** min time between strokes significantly (try 1.2-1.5s)
2. Keep sensitivity moderate (0.25-0.30)
3. Apply and check

## Understanding the Signal Graph

The blue line shows the rotation/motion signal detected by the IMU.
Red dashed vertical lines show detected strokes.

**What to look for:**
- ✅ Red lines should align with peaks in the blue signal
- ✅ One red line per stroke cycle
- ❌ Red lines between peaks = too sensitive
- ❌ Missing red lines on obvious peaks = not sensitive enough

## Recommended Settings by Swim Style

### Freestyle (Front Crawl)
- Sensitivity: 0.20 - 0.30
- Min time: 0.6 - 1.0s

### Breaststroke
- Sensitivity: 0.25 - 0.35
- Min time: 1.0 - 1.5s

### Backstroke
- Sensitivity: 0.20 - 0.28
- Min time: 0.7 - 1.0s

### Butterfly
- Sensitivity: 0.30 - 0.40
- Min time: 0.8 - 1.2s

## Device Placement Tips

For best accuracy:

1. **Position**: Lower back, centered on spine
2. **Orientation**: Flat against body (not tilted)
3. **Tightness**: Belt should be snug but comfortable
4. **Waterproof box**: Should not shift during swimming

## Troubleshooting

### Signal Looks Very Noisy
- Device might be loose - tighten belt
- Box might have water inside - check seals
- Try increasing the median filter size (code change)

### No Peaks Visible in Graph
- Device orientation might be wrong
- MPU6050 might not be working
- Check ESP32 serial monitor for sensor errors

### Inconsistent Results Between Sessions
- Ensure device placement is identical each time
- Mark the belt position with tape/marker
- Use same sensitivity settings

### Detection Works for Some Strokes, Misses Others
- Your stroke technique might be inconsistent
- Try focusing on even, rhythmic strokes
- Consider using a higher sensitivity (0.15-0.20)

## Advanced Tips

### Save Your Settings
Currently, settings reset between sessions. Recommended approach:
1. Do a test session
2. Find your optimal sensitivity + min time
3. Write them down
4. Use the same settings for future sessions

### Multiple Swimming Styles
Different strokes need different settings. Consider:
1. Record which settings work for each style
2. Adjust before viewing results
3. Future update will allow per-style presets

### Calibration Period
The app removes the first and last few seconds automatically:
- This accounts for starting/stopping
- For very short tests, it uses only 10% at each end
- For actual swimming sessions, it uses full calibration

### Signal Processing Flow
If you want to understand what's happening:
1. Raw gyro + accel data collected at 50Hz
2. Calibration periods removed (3-8 seconds each end)
3. Combined motion signal calculated
4. Median filter (removes spikes)
5. Low-pass filter (smooths signal)
6. Normalization (scales to 0-1)
7. Peak detection with your settings
8. Metrics calculated from detected peaks

## Future Improvements

Planned features:
- [ ] Preset sensitivity profiles (beginner/intermediate/advanced)
- [ ] Auto-calibration based on detected stroke characteristics
- [ ] Per-stroke-type settings
- [ ] Machine learning for automatic tuning
- [ ] Real-time stroke detection during swimming
- [ ] Haptic feedback on device

## Need Help?

If you're still getting inaccurate results after tuning:
1. Check the debug logs in the app console
2. Verify device placement and orientation
3. Try different swimming styles to see which works best
4. Consider if your stroke technique is consistent enough

The debug logs show:
- Session duration and calibration time used
- Signal statistics (mean, standard deviation)
- Calculated threshold value
- Each detected peak with its value
- Rejected peaks (too close to previous)

Enable Flutter debug mode to see these logs during processing.
