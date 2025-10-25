import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/firebase_service.dart';
import '../models/step_data.dart';
import '../models/step_detection_config.dart';
import '../models/walking_state.dart';
import '../../steps/services/steps_service.dart';
import 'advanced_step_detection_service.dart';
import 'step_calibration_service.dart';

class StepTrackingService {
  static final StepTrackingService _instance = StepTrackingService._internal();
  factory StepTrackingService() => _instance;
  StepTrackingService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirebaseService _firebaseService = FirebaseService();
  final StepsService _stepsService = StepsService();
  final AdvancedStepDetectionService _advancedDetection = AdvancedStepDetectionService();
  final StepCalibrationService _calibrationService = StepCalibrationService();
  // final BackgroundServiceManager _backgroundManager = BackgroundServiceManager();
  
  StreamSubscription<StepCount>? _stepCountStream;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusStream;
  StreamSubscription<int>? _advancedStepsSubscription;
  StreamSubscription<WalkingStateData>? _walkingStateSubscription;
  
  int _currentSteps = 0;
  DateTime? _lastUpdateTime;
  bool _useAdvancedDetection = true;
  WalkingStateData? _currentWalkingState;
  
  // Getters
  int get currentSteps => _currentSteps;
  DateTime? get lastUpdateTime => _lastUpdateTime;
  bool get useAdvancedDetection => _useAdvancedDetection;
  WalkingStateData? get currentWalkingState => _currentWalkingState;
  Future<bool> get isCalibrated async => await _calibrationService.loadConfiguration() != null;

  /// Recalibrate the step detection
  Future<void> recalibrate() async {
    debugPrint('Recalibrating step detection...');
    await _advancedDetection.recalibrate();
  }

  /// Reset step counters
  void resetStepCounters() {
    _advancedDetection.resetCounters();
    _currentSteps = 0;
    _lastUpdateTime = null;
  }

  // Stream controllers for UI updates
  final StreamController<int> _stepsController = StreamController<int>.broadcast();
  final StreamController<PedestrianStatus> _statusController = StreamController<PedestrianStatus>.broadcast();
  final StreamController<WalkingStateData> _walkingStateController = StreamController<WalkingStateData>.broadcast();

  Stream<int> get stepsStream => _stepsController.stream;
  Stream<PedestrianStatus> get statusStream => _statusController.stream;
  Stream<WalkingStateData> get walkingStateStream => _walkingStateController.stream;

  Future<bool> requestPermissions() async {
    // Request activity recognition permission
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  Future<bool> isPermissionGranted() async {
    final status = await Permission.activityRecognition.status;
    return status.isGranted;
  }

  Future<void> startTracking() async {
    try {
      // Initialize background service
      // await _backgroundManager.initialize();
      
      // Check permissions first
      if (!await isPermissionGranted()) {
        final granted = await requestPermissions();
        if (!granted) {
          // For demo purposes, start with mock data if permission not granted
          debugPrint('Permission not granted, using mock data for demo');
          _startMockTracking();
          return;
        }
      }

      // Load saved configuration
      final savedConfig = await _calibrationService.loadConfiguration();
      if (savedConfig != null) {
        _advancedDetection.updateConfig(savedConfig);
      }

      if (_useAdvancedDetection) {
        // Use advanced step detection - don't fall back to traditional pedometer
        await _startAdvancedTracking();
        debugPrint('Advanced step detection started - only counting actual walking steps');
      } else {
        // Use traditional pedometer
        await _startTraditionalTracking();
        debugPrint('Traditional pedometer started');
      }

      // Start background tracking (temporarily disabled)
      // await _backgroundManager.startBackgroundTracking();

      // Load today's step data
      await _loadTodayStepData();
    } catch (e) {
      debugPrint('Error starting step tracking: $e');
      // Only start mock tracking if advanced detection is not enabled
      if (!_useAdvancedDetection) {
        _startMockTracking();
      } else {
        debugPrint('Advanced detection failed, but not falling back to avoid false step counting');
      }
    }
  }

  Future<void> _startAdvancedTracking() async {
    debugPrint('Starting advanced tracking...');
    
    // Start advanced detection
    await _advancedDetection.startDetection();

    // Listen to advanced step detection streams
    _advancedStepsSubscription = _advancedDetection.stepsStream.listen(
      _onAdvancedStepsUpdate,
      onError: _onError,
    );

    _walkingStateSubscription = _advancedDetection.walkingStateStream.listen(
      _onWalkingStateUpdate,
      onError: _onError,
    );
    
    debugPrint('Advanced tracking streams set up successfully');
  }

  Future<void> _startTraditionalTracking() async {
    // Listen to step count stream
    _stepCountStream = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
    );

    // Listen to pedestrian status stream
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream.listen(
      _onPedestrianStatus,
      onError: _onPedestrianStatusError,
    );
  }

  void _startMockTracking() {
    // For demo purposes, start with some initial steps but don't auto-increment
    _currentSteps = 0; // Start with 0 steps
    _stepsController.add(_currentSteps);
    
    // Don't simulate automatic step increments - only count actual steps
    debugPrint('Mock tracking started - steps will only be counted when actually walking');
  }

  void _onAdvancedStepsUpdate(int steps) {
    debugPrint('Advanced steps update: $steps');
    _currentSteps = steps;
    _lastUpdateTime = DateTime.now();
    
    // Emit to stream
    _stepsController.add(_currentSteps);
    
    // Save to local database
    _saveStepData();
    
    // Save to Firestore if user is signed in
    if (_firebaseService.isSignedIn) {
      _stepsService.addStepsEntry(_currentSteps);
    }
  }

  void _onWalkingStateUpdate(WalkingStateData stateData) {
    _currentWalkingState = stateData;
    _walkingStateController.add(stateData);
  }

  void _onStepCount(StepCount event) {
    _currentSteps = event.steps;
    _lastUpdateTime = event.timeStamp;
    
    // Emit to stream
    _stepsController.add(_currentSteps);
    
    // Save to local database
    _saveStepData();
    
    // Save to Firestore if user is signed in
    if (_firebaseService.isSignedIn) {
      _stepsService.addStepsEntry(_currentSteps);
    }
  }

  void _onStepCountError(error) {
    debugPrint('Step count error: $error');
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    _statusController.add(event);
  }

  void _onPedestrianStatusError(error) {
    debugPrint('Pedestrian status error: $error');
  }

  Future<void> _loadTodayStepData() async {
    final today = DateTime.now();
    final stepData = await _databaseHelper.getStepDataByDate(today);
    
    if (stepData != null) {
      _currentSteps = stepData.steps;
      _lastUpdateTime = stepData.updatedAt;
      _stepsController.add(_currentSteps);
    }
  }

  Future<void> _saveStepData() async {
    final today = DateTime.now();
    final existingData = await _databaseHelper.getStepDataByDate(today);
    
    // Calculate distance (assuming average step length of 0.7 meters)
    const double averageStepLength = 0.7;
    final distance = _currentSteps * averageStepLength;
    
    // Calculate calories (rough estimate: 0.04 calories per step)
    const double caloriesPerStep = 0.04;
    final calories = (_currentSteps * caloriesPerStep).round();

    final stepData = StepData(
      id: existingData?.id ?? -1, // Use -1 for new records, will be removed during insert
      date: today,
      steps: _currentSteps,
      distance: distance,
      calories: calories,
      createdAt: existingData?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (existingData != null) {
      await _databaseHelper.updateStepData(stepData);
    } else {
      await _databaseHelper.insertStepData(stepData);
    }
  }

  Future<void> stopTracking() async {
    await _stepCountStream?.cancel();
    await _pedestrianStatusStream?.cancel();
    await _advancedStepsSubscription?.cancel();
    await _walkingStateSubscription?.cancel();
    
    _stepCountStream = null;
    _pedestrianStatusStream = null;
    _advancedStepsSubscription = null;
    _walkingStateSubscription = null;
    
    await _advancedDetection.stopDetection();
    
    // Stop background tracking
    // await _backgroundManager.stopBackgroundTracking();
  }

  Future<List<StepData>> getStepHistory({int days = 7}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    return await _databaseHelper.getStepDataInRange(startDate, endDate);
  }

  Future<StepData?> getTodayStepData() async {
    return await _databaseHelper.getStepDataByDate(DateTime.now());
  }

  Future<List<StepData>> getAllStepData() async {
    return await _databaseHelper.getAllStepData();
  }

  // Advanced detection methods
  Future<void> startCalibration() async {
    await _calibrationService.startCalibration();
  }

  void cancelCalibration() {
    _calibrationService.cancelCalibration();
  }

  Stream<CalibrationProgress> get calibrationProgressStream => _calibrationService.progressStream;
  Stream<CalibrationResult> get calibrationResultStream => _calibrationService.resultStream;

  void toggleDetectionMode() {
    _useAdvancedDetection = !_useAdvancedDetection;
    // Restart tracking with new mode
    stopTracking().then((_) => startTracking());
  }

  void forceAdvancedDetection() {
    _useAdvancedDetection = true;
    stopTracking().then((_) => startTracking());
  }

  void setSensitivity(double sensitivity) {
    _advancedDetection.setSensitivity(sensitivity);
  }

  void resetSteps() {
    _advancedDetection.resetSteps();
    _currentSteps = 0;
    _stepsController.add(_currentSteps);
  }

  Future<StepDetectionConfig?> getDetectionConfig() async {
    return await _calibrationService.loadConfiguration();
  }

  Future<UserStepProfile?> getUserProfile() async {
    return await _calibrationService.loadUserProfile();
  }

  // Background tracking methods
  Future<void> syncBackgroundSteps() async {
    try {
      // final backgroundSteps = await _backgroundManager.getBackgroundStepCount();
      final backgroundSteps = 0;
      if (backgroundSteps > _currentSteps) {
        _currentSteps = backgroundSteps;
        _stepsController.add(_currentSteps);
        _saveStepData();
        debugPrint('Synced background steps: $backgroundSteps');
      }
    } catch (e) {
      debugPrint('Error syncing background steps: $e');
    }
  }

  Future<bool> isBackgroundTracking() async {
    // return await _backgroundManager.isBackgroundTracking();
    return false;
  }

  Future<int> getBackgroundStepCount() async {
    // return await _backgroundManager.getBackgroundStepCount();
    return 0;
  }

  Future<DateTime?> getBackgroundLastUpdate() async {
    // return await _backgroundManager.getLastUpdate();
    return null;
  }

  Future<void> resetBackgroundSteps() async {
    // await _backgroundManager.resetBackgroundSteps();
    _currentSteps = 0;
    _stepsController.add(_currentSteps);
  }

  void _onError(dynamic error) {
    debugPrint('Step tracking error: $error');
  }

  void dispose() {
    _stepsController.close();
    _statusController.close();
    _walkingStateController.close();
    stopTracking();
    _advancedDetection.dispose();
    _calibrationService.dispose();
  }
}
