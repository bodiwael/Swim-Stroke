import 'package:swim_stroke_tracker/services/data_processor.dart';

class SessionData {
  final String id;
  final DateTime dateTime;
  final SwimSessionMetrics metrics;
  final List<SensorDataPoint> rawData;

  SessionData({
    required this.id,
    required this.dateTime,
    required this.metrics,
    required this.rawData,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'totalStrokes': metrics.totalStrokes,
      'averageStrokeTime': metrics.averageStrokeTime,
      'sessionDuration': metrics.sessionDuration,
      'poolLength': metrics.poolLength,
      'laps': metrics.laps,
      'strokeLength': metrics.strokeLength,
      'averageSpeed': metrics.averageSpeed,
      'strokeRate': metrics.strokeRate,
    };
  }

  factory SessionData.fromJson(Map<String, dynamic> json) {
    // Simplified version - would need full reconstruction
    throw UnimplementedError('SessionData.fromJson not fully implemented');
  }
}
