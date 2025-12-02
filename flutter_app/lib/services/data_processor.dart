import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';

class SensorDataPoint {
  final int timestamp; // milliseconds
  final double ax, ay, az; // accelerometer
  final double gx, gy, gz; // gyroscope

  SensorDataPoint({
    required this.timestamp,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
  });

  // Calculate magnitude of acceleration
  double get accelerationMagnitude => sqrt(ax * ax + ay * ay + az * az);

  // Calculate magnitude of rotation
  double get rotationMagnitude => sqrt(gx * gx + gy * gy + gz * gz);

  // Combined motion metric (gyro is primary, accel is secondary)
  double get combinedMotion => rotationMagnitude * 0.7 + accelerationMagnitude * 0.0003;
}

class StrokePeak {
  final int timestamp;
  final double value;
  final int index;

  StrokePeak({
    required this.timestamp,
    required this.value,
    required this.index,
  });
}

class SwimSessionMetrics {
  final int totalStrokes;
  final double averageStrokeTime; // seconds
  final double sessionDuration; // seconds
  final List<double> strokeTimes; // Time between consecutive strokes
  final List<StrokePeak> peaks;

  // Optional metrics (require user input)
  double? poolLength; // meters
  int? laps;
  double? strokeLength; // meters
  double? averageSpeed; // m/s

  SwimSessionMetrics({
    required this.totalStrokes,
    required this.averageStrokeTime,
    required this.sessionDuration,
    required this.strokeTimes,
    required this.peaks,
    this.poolLength,
    this.laps,
    this.strokeLength,
    this.averageSpeed,
  });

  void calculateStrokeLength(double poolLengthMeters, int lapCount) {
    poolLength = poolLengthMeters;
    laps = lapCount;

    if (totalStrokes > 0) {
      double totalDistance = poolLengthMeters * lapCount;
      strokeLength = totalDistance / totalStrokes;
      averageSpeed = totalDistance / sessionDuration;
    }
  }

  double get strokeRate => totalStrokes / (sessionDuration / 60); // strokes per minute
}

class DataProcessor extends ChangeNotifier {
  List<SensorDataPoint> _rawData = [];
  List<SensorDataPoint> _processedData = [];
  SwimSessionMetrics? _metrics;

  bool _isProcessing = false;
  String _statusMessage = '';

  // Adjustable processing parameters
  double peakThreshold = 0.25; // MUCH LOWER - more sensitive detection
  int minPeakDistanceMs = 800; // Milliseconds between strokes (was samples!)
  int calibrationSeconds = 5; // Adaptive - will adjust based on session duration

  // Getters
  List<SensorDataPoint> get rawData => _rawData;
  List<SensorDataPoint> get processedData => _processedData;
  SwimSessionMetrics? get metrics => _metrics;
  bool get isProcessing => _isProcessing;
  String get statusMessage => _statusMessage;

  // Process file data
  Future<void> processFileData(List<int> fileData) async {
    _isProcessing = true;
    _statusMessage = 'Processing data...';
    notifyListeners();

    try {
      // Convert file data to string
      String csvString = String.fromCharCodes(fileData);

      // Parse CSV
      List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);

      // Skip header row
      _rawData.clear();
      for (int i = 1; i < csvData.length; i++) {
        var row = csvData[i];
        if (row.length >= 7) {
          _rawData.add(SensorDataPoint(
            timestamp: int.parse(row[0].toString()),
            ax: double.parse(row[1].toString()),
            ay: double.parse(row[2].toString()),
            az: double.parse(row[3].toString()),
            gx: double.parse(row[4].toString()),
            gy: double.parse(row[5].toString()),
            gz: double.parse(row[6].toString()),
          ));
        }
      }

      debugPrint('Loaded ${_rawData.length} data points');

      // Process the data
      await _processData();

      _isProcessing = false;
      _statusMessage = 'Processing complete';
      notifyListeners();
    } catch (e) {
      _isProcessing = false;
      _statusMessage = 'Error processing data: $e';
      debugPrint('Error: $e');
      notifyListeners();
    }
  }

  Future<void> _processData() async {
    if (_rawData.isEmpty) return;

    // Adaptive calibration based on session duration
    int sessionDurationSeconds = (_rawData.last.timestamp - _rawData.first.timestamp) ~/ 1000;

    // For sessions < 30 seconds, use 3 second calibration
    // For sessions 30-60 seconds, use 5 second calibration
    // For sessions > 60 seconds, use 8 second calibration
    if (sessionDurationSeconds < 30) {
      calibrationSeconds = 3;
    } else if (sessionDurationSeconds < 60) {
      calibrationSeconds = 5;
    } else {
      calibrationSeconds = 8;
    }

    debugPrint('Session duration: ${sessionDurationSeconds}s, using ${calibrationSeconds}s calibration');

    // Step 1: Remove calibration periods
    _processedData = _removeCalibrationPeriods(_rawData);

    debugPrint('After calibration removal: ${_processedData.length} data points');

    if (_processedData.length < 10) {
      debugPrint('Not enough data after calibration removal');
      _metrics = null;
      return;
    }

    // Step 2: Calculate combined motion signal (gyro + accel)
    List<double> motionSignal = _processedData.map((d) => d.combinedMotion).toList();

    // Step 3: Apply median filter first to remove spikes
    List<double> medianFiltered = _applyMedianFilter(motionSignal, 3);

    // Step 4: Apply low-pass filter to smooth
    List<double> filteredSignal = _applyLowPassFilter(medianFiltered, 7);

    // Step 5: Normalize signal
    List<double> normalizedSignal = _normalizeSignal(filteredSignal);

    // Step 6: Detect peaks (strokes) with improved algorithm
    List<StrokePeak> peaks = _detectPeaksImproved(normalizedSignal);

    debugPrint('Detected ${peaks.length} strokes with threshold $peakThreshold');

    // Step 7: Calculate metrics
    _calculateMetrics(peaks);
  }

  List<SensorDataPoint> _removeCalibrationPeriods(List<SensorDataPoint> data) {
    if (data.isEmpty) return [];

    int calibrationMs = calibrationSeconds * 1000;
    int startTime = data.first.timestamp;
    int endTime = data.last.timestamp;
    int totalDuration = endTime - startTime;

    // If session is too short, use minimal calibration
    int actualCalibrationMs = calibrationMs;
    if (totalDuration < calibrationMs * 3) {
      actualCalibrationMs = totalDuration ~/ 10; // Use 10% at each end
      debugPrint('Short session - using ${actualCalibrationMs}ms calibration');
    }

    return data
        .where((point) =>
            point.timestamp >= startTime + actualCalibrationMs &&
            point.timestamp <= endTime - actualCalibrationMs)
        .toList();
  }

  List<double> _applyMedianFilter(List<double> signal, int windowSize) {
    List<double> filtered = [];

    for (int i = 0; i < signal.length; i++) {
      List<double> window = [];

      for (int j = max(0, i - windowSize ~/ 2);
          j < min(signal.length, i + windowSize ~/ 2 + 1);
          j++) {
        window.add(signal[j]);
      }

      window.sort();
      filtered.add(window[window.length ~/ 2]);
    }

    return filtered;
  }

  List<double> _applyLowPassFilter(List<double> signal, int windowSize) {
    List<double> filtered = [];

    for (int i = 0; i < signal.length; i++) {
      double sum = 0;
      int count = 0;

      for (int j = max(0, i - windowSize ~/ 2);
          j < min(signal.length, i + windowSize ~/ 2 + 1);
          j++) {
        sum += signal[j];
        count++;
      }

      filtered.add(sum / count);
    }

    return filtered;
  }

  List<double> _normalizeSignal(List<double> signal) {
    if (signal.isEmpty) return [];

    double minVal = signal.reduce(min);
    double maxVal = signal.reduce(max);
    double range = maxVal - minVal;

    if (range == 0) return signal;

    return signal.map((value) => (value - minVal) / range).toList();
  }

  List<StrokePeak> _detectPeaksImproved(List<double> signal) {
    List<StrokePeak> peaks = [];

    if (signal.length < 3) return peaks;

    // Calculate statistics for adaptive threshold
    double mean = signal.reduce((a, b) => a + b) / signal.length;

    // Calculate standard deviation
    double variance = signal.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / signal.length;
    double stdDev = sqrt(variance);

    // Adaptive threshold: mean + (threshold factor * std dev)
    // This works better than the old formula
    double threshold = mean + (peakThreshold * stdDev * 2);

    // Ensure threshold is at least at mean level
    threshold = max(threshold, mean * 1.1);

    debugPrint('Signal stats - Mean: ${mean.toStringAsFixed(3)}, StdDev: ${stdDev.toStringAsFixed(3)}');
    debugPrint('Peak detection threshold: ${threshold.toStringAsFixed(3)}');

    // Convert minPeakDistanceMs to samples (assuming ~50Hz sampling)
    int minPeakDistanceSamples = (minPeakDistanceMs / 20).round(); // 20ms per sample at 50Hz

    debugPrint('Min peak distance: ${minPeakDistanceMs}ms = $minPeakDistanceSamples samples');

    int lastPeakIndex = -minPeakDistanceSamples * 2;

    for (int i = 2; i < signal.length - 2; i++) {
      // More robust peak detection: check if it's higher than 2 neighbors on each side
      bool isLocalMax = signal[i] > signal[i - 1] &&
                        signal[i] > signal[i + 1] &&
                        signal[i] >= signal[i - 2] &&
                        signal[i] >= signal[i + 2];

      if (isLocalMax) {
        // Check if above threshold
        if (signal[i] > threshold) {
          // Check minimum distance from last peak
          if (i - lastPeakIndex >= minPeakDistanceSamples) {
            peaks.add(StrokePeak(
              timestamp: _processedData[i].timestamp,
              value: signal[i],
              index: i,
            ));
            lastPeakIndex = i;
            debugPrint('Peak found at index $i, value: ${signal[i].toStringAsFixed(3)}');
          } else {
            debugPrint('Peak at $i rejected (too close to previous: ${i - lastPeakIndex} samples)');
          }
        }
      }
    }

    return peaks;
  }

  void _calculateMetrics(List<StrokePeak> peaks) {
    if (peaks.isEmpty || _processedData.isEmpty) {
      _metrics = null;
      return;
    }

    int totalStrokes = peaks.length;

    // Calculate time between strokes
    List<double> strokeTimes = [];
    for (int i = 1; i < peaks.length; i++) {
      double timeDiff = (peaks[i].timestamp - peaks[i - 1].timestamp) / 1000.0;
      strokeTimes.add(timeDiff);
    }

    double averageStrokeTime = strokeTimes.isEmpty
        ? 0
        : strokeTimes.reduce((a, b) => a + b) / strokeTimes.length;

    // Session duration
    double sessionDuration =
        (_processedData.last.timestamp - _processedData.first.timestamp) /
            1000.0;

    _metrics = SwimSessionMetrics(
      totalStrokes: totalStrokes,
      averageStrokeTime: averageStrokeTime,
      sessionDuration: sessionDuration,
      strokeTimes: strokeTimes,
      peaks: peaks,
    );

    notifyListeners();
  }

  // Add pool info and calculate stroke length
  void addPoolInfo(double poolLength, int laps) {
    if (_metrics != null) {
      _metrics!.calculateStrokeLength(poolLength, laps);
      notifyListeners();
    }
  }

  // Manual sensitivity adjustment
  void adjustSensitivity(double newThreshold, int newMinDistance) {
    peakThreshold = newThreshold;
    minPeakDistanceMs = newMinDistance;

    // Reprocess with new parameters
    if (_rawData.isNotEmpty) {
      _processData();
    }
  }

  // Get processed signal for visualization
  List<double> getProcessedSignal() {
    return _processedData.map((d) => d.combinedMotion).toList();
  }

  List<double> getAccelerationSignal() {
    return _processedData.map((d) => d.accelerationMagnitude).toList();
  }

  List<int> getTimestamps() {
    return _processedData.map((d) => d.timestamp).toList();
  }

  void reset() {
    _rawData.clear();
    _processedData.clear();
    _metrics = null;
    _isProcessing = false;
    _statusMessage = '';
    notifyListeners();
  }
}
