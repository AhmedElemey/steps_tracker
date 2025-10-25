import 'dart:math';

class AccelerometerData {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;
  final double magnitude;

  AccelerometerData({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  }) : magnitude = _calculateMagnitude(x, y, z);

  static double _calculateMagnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }

  AccelerometerData copyWith({
    double? x,
    double? y,
    double? z,
    DateTime? timestamp,
  }) {
    return AccelerometerData(
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'AccelerometerData(x: $x, y: $y, z: $z, magnitude: $magnitude, timestamp: $timestamp)';
  }
}
