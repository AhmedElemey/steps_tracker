import 'dart:async';
import 'package:flutter/foundation.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
import 'background_step_service.dart';

class BackgroundServiceManager {
  static final BackgroundServiceManager _instance = BackgroundServiceManager._internal();
  factory BackgroundServiceManager() => _instance;
  BackgroundServiceManager._internal();

  bool _isInitialized = false;
  StreamSubscription<Map<String, dynamic>?>? _serviceSubscription;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await BackgroundStepService.initialize();
      _isInitialized = true;
      debugPrint('Background service manager initialized');
    } catch (e) {
      debugPrint('Error initializing background service: $e');
    }
  }

  Future<void> startBackgroundTracking() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await BackgroundStepService.startBackgroundTracking();
      debugPrint('Background tracking started');
    } catch (e) {
      debugPrint('Error starting background tracking: $e');
    }
  }

  Future<void> stopBackgroundTracking() async {
    try {
      await BackgroundStepService.stopBackgroundTracking();
      debugPrint('Background tracking stopped');
    } catch (e) {
      debugPrint('Error stopping background tracking: $e');
    }
  }

  Future<int> getBackgroundStepCount() async {
    try {
      return await BackgroundStepService.getBackgroundStepCount();
    } catch (e) {
      debugPrint('Error getting background step count: $e');
      return 0;
    }
  }

  Future<DateTime?> getLastUpdate() async {
    try {
      return await BackgroundStepService.getLastUpdate();
    } catch (e) {
      debugPrint('Error getting last update: $e');
      return null;
    }
  }

  Future<bool> isBackgroundTracking() async {
    try {
      return await BackgroundStepService.isBackgroundTracking();
    } catch (e) {
      debugPrint('Error checking background tracking status: $e');
      return false;
    }
  }

  Future<void> resetBackgroundSteps() async {
    try {
      await BackgroundStepService.resetBackgroundSteps();
      debugPrint('Background steps reset');
    } catch (e) {
      debugPrint('Error resetting background steps: $e');
    }
  }

  Future<bool> isServiceRunning() async {
    // Background service temporarily disabled
    return false;
  }

  void dispose() {
    _serviceSubscription?.cancel();
  }
}
