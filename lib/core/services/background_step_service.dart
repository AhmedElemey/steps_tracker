import 'dart:async';
import 'package:flutter/foundation.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/step_tracking/models/accelerometer_data.dart';

class BackgroundStepService {
  static const String _stepCountKey = 'background_step_count';
  static const String _lastUpdateKey = 'background_last_update';
  static const String _isTrackingKey = 'background_is_tracking';

  static Future<void> initialize() async {
    // Background service temporarily disabled
    debugPrint('Background service initialization skipped');
  }

  static Future<void> startBackgroundTracking() async {
    // Background service temporarily disabled
    debugPrint('Background step tracking skipped');
  }

  static Future<void> stopBackgroundTracking() async {
    // Background service temporarily disabled
    debugPrint('Background step tracking stop skipped');
  }

  static Future<int> getBackgroundStepCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_stepCountKey) ?? 0;
  }

  static Future<DateTime?> getLastUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastUpdateKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  static Future<bool> isBackgroundTracking() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isTrackingKey) ?? false;
  }

  static Future<void> resetBackgroundSteps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stepCountKey, 0);
    await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    
  }
}

@pragma('vm:entry-point')
void onStart(dynamic service) async {
  debugPrint('Background service onStart skipped');
  return;
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(dynamic service) async {
  return true;
}

bool _isValidMovement(double magnitude) {
  return magnitude >= 8.0 && magnitude <= 20.0;
}

bool _isPeak(AccelerometerData data, List<double> magnitudeBuffer) {
  if (magnitudeBuffer.length < 3) return false;
  
  final current = data.magnitude;
  final previous = magnitudeBuffer[magnitudeBuffer.length - 2];
  final next = magnitudeBuffer.length >= 3 ? magnitudeBuffer[magnitudeBuffer.length - 3] : current;
  
  return current > previous && current > next && current > 10.0;
}

bool _isValley(AccelerometerData data, List<double> magnitudeBuffer) {
  if (magnitudeBuffer.length < 3) return false;
  
  final current = data.magnitude;
  final previous = magnitudeBuffer[magnitudeBuffer.length - 2];
  final next = magnitudeBuffer.length >= 3 ? magnitudeBuffer[magnitudeBuffer.length - 3] : current;
  
  return current < previous && current < next && current < 9.5;
}

bool _isValidStep(
  DateTime? lastPeakTime,
  DateTime? lastValleyTime,
  double lastPeakValue,
  double lastValleyValue,
  DateTime? lastStepTime,
) {
  if (lastPeakTime == null || lastValleyTime == null) return false;
  
  // Check time interval between peak and valley
  final peakValleyInterval = lastValleyTime.difference(lastPeakTime).inMilliseconds;
  if (peakValleyInterval < 50 || peakValleyInterval > 600) return false;
  
  // Check time since last step
  if (lastStepTime != null) {
    final stepInterval = lastValleyTime.difference(lastStepTime).inMilliseconds;
    if (stepInterval < 100 || stepInterval > 3000) return false;
  }
  
  // Check magnitude difference
  final magnitudeDifference = lastPeakValue - lastValleyValue;
  if (magnitudeDifference < 0.3) return false;
  
  return true;
}

Future<void> _saveStepCount(int stepCount) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(BackgroundStepService._stepCountKey, stepCount);
  await prefs.setInt(BackgroundStepService._lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
}