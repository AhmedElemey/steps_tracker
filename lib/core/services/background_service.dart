import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_service.dart';
import '../../features/steps/services/steps_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final StepsService _stepsService = StepsService();
  
  StreamSubscription<StepCount>? _stepCountStream;
  Timer? _backgroundTimer;
  int _lastSteps = 0;
  DateTime? _lastUpdate;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  Future<bool> startBackgroundTracking() async {
    try {
      if (_isRunning) return true;

      // Check permissions
      final hasPermission = await Permission.activityRecognition.isGranted;
      if (hasPermission != PermissionStatus.granted) {
        final granted = await Permission.activityRecognition.request();
        if (granted != PermissionStatus.granted) {
          debugPrint('Background tracking permission not granted');
          return false;
        }
      }

      // Start step count stream
      _stepCountStream = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onError,
      );

      // Start background timer to save data periodically
      _backgroundTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        _saveCurrentSteps();
      });

      _isRunning = true;
      debugPrint('Background tracking started');
      return true;
    } catch (e) {
      debugPrint('Error starting background tracking: $e');
      return false;
    }
  }

  Future<void> stopBackgroundTracking() async {
    try {
      await _stepCountStream?.cancel();
      _stepCountStream = null;
      
      _backgroundTimer?.cancel();
      _backgroundTimer = null;
      
      _isRunning = false;
      debugPrint('Background tracking stopped');
    } catch (e) {
      debugPrint('Error stopping background tracking: $e');
    }
  }

  void _onStepCount(StepCount event) {
    _lastSteps = event.steps;
    _lastUpdate = event.timeStamp;
    
    // Save to Firestore if user is signed in
    if (_firebaseService.isSignedIn) {
      _stepsService.addStepsEntry(_lastSteps);
    }
  }

  void _onError(dynamic error) {
    debugPrint('Background step count error: $error');
  }

  void _saveCurrentSteps() {
    if (_firebaseService.isSignedIn && _lastSteps > 0) {
      _stepsService.addStepsEntry(_lastSteps);
    }
  }

  Future<void> initialize() async {
    // Initialize background tracking when app starts
    if (_firebaseService.isSignedIn) {
      await startBackgroundTracking();
    }
  }

  void dispose() {
    stopBackgroundTracking();
  }
}
