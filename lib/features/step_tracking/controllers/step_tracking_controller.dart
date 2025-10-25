import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import '../models/step_data.dart';
import '../models/walking_state.dart';
import '../services/step_tracking_service.dart';
import '../services/step_calibration_service.dart';
import '../../goals/services/goals_service.dart';
import '../../steps/services/steps_service.dart';

class StepTrackingController extends ChangeNotifier {
  final StepTrackingService _stepTrackingService = StepTrackingService();
  final GoalsService _goalsService = GoalsService();
  final StepsService _stepsService = StepsService();

  int _currentSteps = 0;
  int _targetSteps = 10000;
  double _progress = 0.0;
  bool _isTracking = false;
  PedestrianStatus? _pedestrianStatus;
  WalkingStateData? _walkingState;
  List<StepData> _stepHistory = [];
  String _errorMessage = '';
  bool _isCalibrated = false;
  double _sensitivity = 0.5;

  // Getters
  int get currentSteps => _currentSteps;
  int get targetSteps => _targetSteps;
  double get progress => _progress;
  bool get isTracking => _isTracking;
  PedestrianStatus? get pedestrianStatus => _pedestrianStatus;
  WalkingStateData? get walkingState => _walkingState;
  List<StepData> get stepHistory => _stepHistory;
  String get errorMessage => _errorMessage;
  bool get isCalibrated => _isCalibrated;
  double get sensitivity => _sensitivity;

  // Stream subscriptions
  StreamSubscription<int>? _stepsSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;
  StreamSubscription<WalkingStateData>? _walkingStateSubscription;

  StepTrackingController() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Load target steps from goals
      await _loadTargetSteps();
      
      // Load step history
      await _loadStepHistory();
      
      // Sync background steps first
      await _stepTrackingService.syncBackgroundSteps();
      
      // Start listening to step updates
      _stepsSubscription = _stepTrackingService.stepsStream.listen(
        _onStepsUpdate,
        onError: _onError,
      );

      _statusSubscription = _stepTrackingService.statusStream.listen(
        _onStatusUpdate,
        onError: _onError,
      );

      _walkingStateSubscription = _stepTrackingService.walkingStateStream.listen(
        _onWalkingStateUpdate,
        onError: _onError,
      );

      // Get current steps
      _currentSteps = _stepTrackingService.currentSteps;
      _updateProgress();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize step tracking: $e';
      notifyListeners();
    }
  }

  void _onStepsUpdate(int steps) {
    _currentSteps = steps;
    _updateProgress();
    notifyListeners();
    
    // Save to Firestore every 100 steps or every 5 minutes
    _saveStepsToFirestore();
  }

  void _onStatusUpdate(PedestrianStatus status) {
    _pedestrianStatus = status;
    notifyListeners();
  }

  void _onWalkingStateUpdate(WalkingStateData stateData) {
    _walkingState = stateData;
    notifyListeners();
  }

  void _onError(dynamic error) {
    _errorMessage = 'Error: $error';
    notifyListeners();
  }

  void _updateProgress() {
    if (_targetSteps > 0) {
      _progress = (_currentSteps / _targetSteps).clamp(0.0, 1.0);
    } else {
      _progress = 0.0;
    }
  }

  Future<void> _loadTargetSteps() async {
    try {
      final goal = await _goalsService.getActiveGoal();
      if (goal != null) {
        _targetSteps = goal.targetSteps;
        _updateProgress();
      } else {
        // Create a default goal if none exists
        await _goalsService.createGoal(
          targetSteps: 10000,
          targetCalories: 500,
          targetDistance: 8000.0,
        );
        _targetSteps = 10000;
        _updateProgress();
      }
    } catch (e) {
      debugPrint('Error loading target steps: $e');
      _targetSteps = 10000; // Default fallback
      _updateProgress();
    }
  }

  Future<void> _loadStepHistory() async {
    try {
      _stepHistory = await _stepTrackingService.getStepHistory(days: 7);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading step history: $e');
    }
  }

  Future<void> startTracking() async {
    try {
      _errorMessage = '';
      await _stepTrackingService.startTracking();
      _isTracking = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Using demo mode - step tracking will work with mock data';
      _isTracking = true; // Still show as tracking in demo mode
      notifyListeners();
    }
  }

  Future<void> stopTracking() async {
    try {
      await _stepTrackingService.stopTracking();
      _isTracking = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to stop tracking: $e';
      notifyListeners();
    }
  }

  DateTime? _lastFirestoreSave;
  int _lastSavedSteps = 0;

  void _saveStepsToFirestore() {
    final now = DateTime.now();
    final shouldSave = _lastFirestoreSave == null ||
        now.difference(_lastFirestoreSave!).inMinutes >= 5 ||
        (_currentSteps - _lastSavedSteps) >= 100;

    if (shouldSave) {
      _stepsService.addStepsEntry(_currentSteps);
      _lastFirestoreSave = now;
      _lastSavedSteps = _currentSteps;
    }
  }

  Future<void> refreshData() async {
    try {
      _errorMessage = '';
      await _loadTargetSteps();
      await _loadStepHistory();
      
      // Get current steps from service
      _currentSteps = _stepTrackingService.currentSteps;
      _updateProgress();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh data: $e';
      notifyListeners();
    }
  }

  Future<void> updateTargetSteps(int newTarget) async {
    try {
      _errorMessage = '';
      _targetSteps = newTarget;
      _updateProgress();
      
      // Update goal in database
      await _goalsService.updateActiveGoalSteps(newTarget);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update target steps: $e';
      notifyListeners();
    }
  }

  String getFormattedSteps() {
    return _currentSteps.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String getFormattedTarget() {
    return _targetSteps.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String getProgressPercentage() {
    return '${(_progress * 100).toStringAsFixed(1)}%';
  }

  String getRemainingSteps() {
    final remaining = _targetSteps - _currentSteps;
    return remaining > 0 ? remaining.toString() : '0';
  }

  // Advanced step detection methods
  Future<void> startCalibration() async {
    try {
      _errorMessage = '';
      await _stepTrackingService.startCalibration();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to start calibration: $e';
      notifyListeners();
    }
  }

  void cancelCalibration() {
    _stepTrackingService.cancelCalibration();
  }

  void setSensitivity(double sensitivity) {
    _sensitivity = sensitivity.clamp(0.0, 1.0);
    _stepTrackingService.setSensitivity(_sensitivity);
    notifyListeners();
  }

  void resetSteps() {
    _stepTrackingService.resetSteps();
    _currentSteps = 0;
    _updateProgress();
    notifyListeners();
  }

  void toggleDetectionMode() {
    _stepTrackingService.toggleDetectionMode();
    notifyListeners();
  }

  bool get isWalking => _walkingState?.isWalking ?? false;
  bool get isIdle => _walkingState?.isIdle ?? true;
  bool get isCalibrating => _walkingState?.isCalibrating ?? false;

  String get walkingStatusMessage {
    if (_walkingState?.message != null) {
      return _walkingState!.message!;
    }
    
    if (isWalking) {
      return 'Walking detected - steps are being counted';
    } else if (isIdle) {
      return 'No walking detected';
    } else {
      return 'Movement detected - waiting for consistent walking pattern';
    }
  }

  double get walkingConfidence => _walkingState?.confidence ?? 0.0;

  Stream<CalibrationProgress> get calibrationProgressStream => _stepTrackingService.calibrationProgressStream;
  Stream<CalibrationResult> get calibrationResultStream => _stepTrackingService.calibrationResultStream;

  // Background tracking methods
  Future<void> syncBackgroundSteps() async {
    await _stepTrackingService.syncBackgroundSteps();
    _currentSteps = _stepTrackingService.currentSteps;
    _updateProgress();
    notifyListeners();
  }

  Future<bool> isBackgroundTracking() async {
    return await _stepTrackingService.isBackgroundTracking();
  }

  Future<int> getBackgroundStepCount() async {
    return await _stepTrackingService.getBackgroundStepCount();
  }

  Future<DateTime?> getBackgroundLastUpdate() async {
    return await _stepTrackingService.getBackgroundLastUpdate();
  }

  Future<void> resetBackgroundSteps() async {
    await _stepTrackingService.resetBackgroundSteps();
    _currentSteps = 0;
    _updateProgress();
    notifyListeners();
  }

  @override
  void dispose() {
    _stepsSubscription?.cancel();
    _statusSubscription?.cancel();
    _walkingStateSubscription?.cancel();
    _stepTrackingService.dispose();
    super.dispose();
  }
}
