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

  // Processing parameters
  static const int calibrationSeconds = 10; // Remove first and last 10 seconds
  double _peakThreshold = 0.6; // Relative threshold for peak detection
  int _minPeakDistance = 500; // Minimum 0.5 seconds between peaks

  // Getters
  List<SensorDataPoint> get rawData => _rawData;
  List<SensorDataPoint> get processedData => _processedData;
  SwimSessionMetrics? get metrics => _metrics;
  bool get isProcessing => _isProcessing;
  String get statusMessage => _statusMessage;

  // Expose processing parameters for UI adjustment
  double get peakThreshold => _peakThreshold;
  int get minPeakDistanceMs => _minPeakDistance;

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

      debugPrint('=== CSV PARSING DEBUG ===');
      debugPrint('Total CSV rows found: ${csvData.length}');
      if (csvData.isNotEmpty) {
        debugPrint('First row: ${csvData[0]}');
        if (csvData.length > 1) {
          debugPrint('Second row: ${csvData[1]}');
        }
      }

      // Skip header row and parse data rows
      _rawData.clear();
      int skippedRows = 0;
      for (int i = 0; i < csvData.length; i++) {
        var row = csvData[i];

        // Skip if row doesn't have enough columns
        if (row.length < 7) {
          skippedRows++;
          continue;
        }

        // Skip header row (check if first column is "timestamp" string)
        if (row[0].toString().toLowerCase().contains('timestamp')) {
          debugPrint('Skipping header row: $row');
          continue;
        }

        // Try to parse the row, skip if invalid
        try {
          _rawData.add(SensorDataPoint(
            timestamp: int.parse(row[0].toString()),
            ax: double.parse(row[1].toString()),
            ay: double.parse(row[2].toString()),
            az: double.parse(row[3].toString()),
            gx: double.parse(row[4].toString()),
            gy: double.parse(row[5].toString()),
            gz: double.parse(row[6].toString()),
          ));
        } catch (e) {
          // Skip invalid rows
          debugPrint('Skipping invalid row $i: $e - Row data: $row');
          skippedRows++;
          continue;
        }
      }

      debugPrint('Loaded ${_rawData.length} data points (skipped $skippedRows rows)');

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

    // Step 1: Remove calibration periods (first and last 10 seconds)
    _processedData = _removeCalibrationPeriods(_rawData);

    debugPrint(
        'After calibration removal: ${_processedData.length} data points');

    // Step 2: Calculate signal features
    List<double> rotationSignal = _processedData.map((d) => d.rotationMagnitude).toList();

    // Step 3: Apply low-pass filter to remove noise
    List<double> filteredSignal = _applyLowPassFilter(rotationSignal);

    // Step 4: Normalize signal
    List<double> normalizedSignal = _normalizeSignal(filteredSignal);

    // Step 5: Detect peaks (strokes)
    List<StrokePeak> peaks = _detectPeaks(normalizedSignal);

    debugPrint('Detected ${peaks.length} strokes');

    // Step 6: Calculate metrics
    _calculateMetrics(peaks);
  }

  List<SensorDataPoint> _removeCalibrationPeriods(List<SensorDataPoint> data) {
    if (data.isEmpty) return [];

    int calibrationMs = calibrationSeconds * 1000;
    int startTime = data.first.timestamp;
    int endTime = data.last.timestamp;
    int totalDuration = endTime - startTime;

    debugPrint('=== CALIBRATION REMOVAL ===');
    debugPrint('Total duration: ${totalDuration}ms (${totalDuration / 1000}s)');
    debugPrint('Calibration period: ${calibrationMs}ms (${calibrationSeconds}s)');
    debugPrint('Input data points: ${data.length}');

    // If session is too short, don't remove calibration
    if (totalDuration < calibrationMs * 2) {
      debugPrint('Session too short for calibration removal - returning all data');
      return data;
    }

    var filtered = data
        .where((point) =>
            point.timestamp >= startTime + calibrationMs &&
            point.timestamp <= endTime - calibrationMs)
        .toList();

    debugPrint('After calibration removal: ${filtered.length} data points');
    return filtered;
  }

  List<double> _applyLowPassFilter(List<double> signal) {
    // Simple moving average filter
    const int windowSize = 5;
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

  List<StrokePeak> _detectPeaks(List<double> signal) {
    List<StrokePeak> peaks = [];

    debugPrint('=== PEAK DETECTION ===');
    debugPrint('Signal length: ${signal.length}');

    if (signal.length < 3) {
      debugPrint('Signal too short for peak detection');
      return peaks;
    }

    // Calculate adaptive threshold
    double mean = signal.reduce((a, b) => a + b) / signal.length;
    double threshold = mean + _peakThreshold * (1.0 - mean);

    debugPrint('Signal mean: $mean');
    debugPrint('Peak detection threshold: $threshold');
    debugPrint('Min peak distance: ${_minPeakDistance}ms');

    int lastPeakIndex = -_minPeakDistance;

    for (int i = 1; i < signal.length - 1; i++) {
      // Check if this is a local maximum
      if (signal[i] > signal[i - 1] && signal[i] > signal[i + 1]) {
        // Check if above threshold
        if (signal[i] > threshold) {
          // Check minimum distance from last peak
          if (i - lastPeakIndex >= _minPeakDistance) {
            peaks.add(StrokePeak(
              timestamp: _processedData[i].timestamp,
              value: signal[i],
              index: i,
            ));
            lastPeakIndex = i;
          }
        }
      }
    }

    debugPrint('Total peaks found: ${peaks.length}');
    if (peaks.isNotEmpty) {
      debugPrint('First peak at: ${peaks.first.timestamp}ms, value: ${peaks.first.value}');
      if (peaks.length > 1) {
        debugPrint('Last peak at: ${peaks.last.timestamp}ms, value: ${peaks.last.value}');
      }
    }

    return peaks;
  }

  void _calculateMetrics(List<StrokePeak> peaks) {
    debugPrint('=== METRICS CALCULATION ===');
    debugPrint('Peaks detected: ${peaks.length}');
    debugPrint('Processed data points: ${_processedData.length}');

    if (peaks.isEmpty || _processedData.isEmpty) {
      debugPrint('ERROR: No metrics generated - peaks: ${peaks.length}, data: ${_processedData.length}');
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

  // Adjust sensitivity parameters and reprocess data
  Future<void> adjustSensitivity(double sensitivity, double minStrokeTime) async {
    _peakThreshold = sensitivity;
    _minPeakDistance = (minStrokeTime * 1000).toInt(); // Convert seconds to milliseconds

    // Reprocess if we have data
    if (_rawData.isNotEmpty) {
      _isProcessing = true;
      notifyListeners();

      await _processData();

      _isProcessing = false;
      notifyListeners();
    }
  }

  // Get processed signal for visualization
  List<double> getProcessedSignal() {
    return _processedData.map((d) => d.rotationMagnitude).toList();
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
