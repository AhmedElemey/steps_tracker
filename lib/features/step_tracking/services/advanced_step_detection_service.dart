import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/accelerometer_data.dart';
import '../models/step_detection_config.dart';
import '../models/walking_state.dart';

class AdvancedStepDetectionService {
  static final AdvancedStepDetectionService _instance = AdvancedStepDetectionService._internal();
  factory AdvancedStepDetectionService() => _instance;
  AdvancedStepDetectionService._internal();

  // Configuration
  StepDetectionConfig _config = const StepDetectionConfig();
  
  // Stream controllers
  final StreamController<int> _stepsController = StreamController<int>.broadcast();
  final StreamController<WalkingStateData> _walkingStateController = StreamController<WalkingStateData>.broadcast();
  final StreamController<AccelerometerData> _accelerometerController = StreamController<AccelerometerData>.broadcast();

  // Stream subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // State variables
  int _detectedSteps = 0;
  int _totalSteps = 0;
  WalkingState _currentWalkingState = WalkingState.idle;
  int _consecutiveSteps = 0;
  DateTime? _lastStepTime;

  // Data buffers for analysis
  final List<AccelerometerData> _accelerationBuffer = [];
  final List<double> _magnitudeBuffer = [];
  final int _bufferSize = 50; // Keep last 50 readings

  // Peak detection variables
  bool _isLookingForPeak = true;
  double _lastPeakValue = 0.0;
  double _lastValleyValue = 0.0;
  DateTime? _lastPeakTime;
  DateTime? _lastValleyTime;

  // Calibration variables
  final List<double> _calibrationData = [];
  bool _isCalibrating = false;

  // Getters
  int get detectedSteps => _detectedSteps;
  int get totalSteps => _totalSteps;
  WalkingState get currentWalkingState => _currentWalkingState;
  StepDetectionConfig get config => _config;
  bool get isCalibrating => _isCalibrating;

  // Streams
  Stream<int> get stepsStream => _stepsController.stream;
  Stream<WalkingStateData> get walkingStateStream => _walkingStateController.stream;
  Stream<AccelerometerData> get accelerometerStream => _accelerometerController.stream;

  /// Start the advanced step detection
  Future<void> startDetection() async {
    if (_accelerometerSubscription != null) return;

    debugPrint('Starting advanced step detection...');

    // Reset all counters to ensure clean start
    _detectedSteps = 0;
    _totalSteps = 0;
    _consecutiveSteps = 0;
    _lastStepTime = null;
    _currentWalkingState = WalkingState.idle;

    try {
      _accelerometerSubscription = accelerometerEventStream().listen(
        _onAccelerometerData,
        onError: _onError,
      );
      debugPrint('Accelerometer stream started successfully');
    } catch (e) {
      debugPrint('Error starting accelerometer stream: $e');
      _updateWalkingState(WalkingState.idle, 'Error starting accelerometer: $e');
      return;
    }

    // Start calibration if not already calibrated
    if (!_config.isCalibrated) {
      debugPrint('Starting calibration...');
      await _startCalibration();
    } else {
      debugPrint('Using existing calibration');
    }

    _updateWalkingState(WalkingState.idle, 'Step detection started - only counting actual walking steps');
  }

  /// Stop the step detection
  Future<void> stopDetection() async {
    await _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _updateWalkingState(WalkingState.idle, 'Step detection stopped');
  }

  /// Update configuration
  void updateConfig(StepDetectionConfig newConfig) {
    _config = newConfig;
    debugPrint('Step detection config updated: $newConfig');
  }

  /// Reset step counters
  void resetCounters() {
    _detectedSteps = 0;
    _totalSteps = 0;
    _consecutiveSteps = 0;
    _lastStepTime = null;
    _currentWalkingState = WalkingState.idle;
    
    // Clear buffers
    _accelerationBuffer.clear();
    _magnitudeBuffer.clear();
    
    // Reset peak/valley detection
    _isLookingForPeak = true;
    _lastPeakValue = 0.0;
    _lastValleyValue = 0.0;
    _lastPeakTime = null;
    _lastValleyTime = null;
    
    debugPrint('Step counters reset');
  }

  /// Manually trigger calibration
  Future<void> recalibrate() async {
    debugPrint('Manual recalibration requested');
    _config = _config.copyWith(isCalibrated: false);
    await _startCalibration();
  }

  /// Start calibration process
  Future<void> _startCalibration() async {
    _isCalibrating = true;
    _calibrationData.clear();
    _updateWalkingState(WalkingState.calibrating, 'Calibrating... Please walk normally for 15 seconds');

    debugPrint('Starting calibration - collecting data for 15 seconds...');

    // Auto-complete calibration after 15 seconds (longer for better accuracy)
    Timer(const Duration(seconds: 15), () {
      if (_isCalibrating) {
        _completeCalibration();
      }
    });
  }

  /// Complete calibration and calculate user baseline
  void _completeCalibration() {
    if (_calibrationData.isEmpty) {
      debugPrint('Calibration failed - no data collected');
      _isCalibrating = false;
      _updateWalkingState(WalkingState.idle, 'Calibration failed - no data collected');
      return;
    }

    debugPrint('Calibration data collected: ${_calibrationData.length} samples');

    // Calculate baseline magnitude (median of calibration data)
    _calibrationData.sort();
    final medianIndex = _calibrationData.length ~/ 2;
    final baselineMagnitude = _calibrationData[medianIndex];

    // Calculate additional statistics for better calibration
    final mean = _calibrationData.reduce((a, b) => a + b) / _calibrationData.length;
    final variance = _calibrationData.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / _calibrationData.length;
    final standardDeviation = sqrt(variance);

    debugPrint('Calculated baseline magnitude: $baselineMagnitude');
    debugPrint('Mean: $mean, StdDev: $standardDeviation');

    // Update config with calibrated values and improved thresholds
    _config = _config.copyWith(
      isCalibrated: true,
      userBaselineMagnitude: baselineMagnitude,
      // Adjust thresholds based on user's movement characteristics
      minMagnitudeThreshold: (baselineMagnitude - standardDeviation * 1.5).clamp(7.0, 9.0),
      maxMagnitudeThreshold: (baselineMagnitude + standardDeviation * 2.5).clamp(12.0, 20.0),
    );

    _isCalibrating = false;
    _updateWalkingState(WalkingState.idle, 'Calibration complete! Ready to detect steps.');
  }

  /// Process accelerometer data
  void _onAccelerometerData(AccelerometerEvent event) {
    final accelerometerData = AccelerometerData(
      x: event.x,
      y: event.y,
      z: event.z,
      timestamp: DateTime.now(),
    );

    // Emit raw accelerometer data
    _accelerometerController.add(accelerometerData);

    // Add to buffer
    _addToBuffer(accelerometerData);

    // Skip processing during calibration
    if (_isCalibrating) {
      _calibrationData.add(accelerometerData.magnitude);
      return;
    }

    // Process for step detection
    _processStepDetection(accelerometerData);
  }

  /// Add accelerometer data to buffer
  void _addToBuffer(AccelerometerData data) {
    _accelerationBuffer.add(data);
    _magnitudeBuffer.add(data.magnitude);

    // Keep buffer size manageable
    if (_accelerationBuffer.length > _bufferSize) {
      _accelerationBuffer.removeAt(0);
      _magnitudeBuffer.removeAt(0);
    }
  }

  /// Main step detection algorithm
  void _processStepDetection(AccelerometerData data) {
    // Validate movement magnitude
    if (!_isValidMovement(data.magnitude)) {
      return;
    }

    // Debug: Log magnitude very occasionally (every 500 readings)
    if (_magnitudeBuffer.length % 500 == 0) {
      debugPrint('Processing accelerometer data: magnitude=${data.magnitude.toStringAsFixed(2)}, baseline=${_config.userBaselineMagnitude.toStringAsFixed(2)}, buffer_size=${_magnitudeBuffer.length}');
    }

    // Detect peaks and valleys
    if (_isLookingForPeak) {
      if (_isPeak(data)) {
        debugPrint('Peak detected: ${data.magnitude.toStringAsFixed(2)}');
        _handlePeak(data);
      }
    } else {
      if (_isValley(data)) {
        debugPrint('Valley detected: ${data.magnitude.toStringAsFixed(2)}');
        _handleValley(data);
      }
    }
  }

  /// Check if movement magnitude is valid
  bool _isValidMovement(double magnitude) {
    // Use user's baseline instead of fixed gravity value
    final baseline = _config.userBaselineMagnitude;
    final minThreshold = _config.adjustedMinMagnitude;
    final maxThreshold = _config.adjustedMaxMagnitude;
    
    // More lenient validation - allow some variation around baseline
    final lowerBound = (baseline - 2.0).clamp(minThreshold, baseline);
    final upperBound = (baseline + 5.0).clamp(baseline, maxThreshold);
    
    // Only process data within valid range
    return magnitude >= lowerBound && magnitude <= upperBound;
  }

  /// Check if current reading is a peak
  bool _isPeak(AccelerometerData data) {
    if (_magnitudeBuffer.length < 5) return false;

    final current = data.magnitude;
    final bufferSize = _magnitudeBuffer.length;
    
    // Check if current value is higher than surrounding values
    // Since buffer is FIFO, the most recent values are at the end
    final previous = _magnitudeBuffer[bufferSize - 2];
    final next = _magnitudeBuffer[bufferSize - 3];
    
    // Use dynamic threshold based on user's baseline
    final baseline = _config.userBaselineMagnitude;
    final peakThreshold = baseline + _config.adjustedPeakThreshold;
    
    // More robust peak detection with proper buffer indexing
    return current > previous && 
           current > next && 
           current > peakThreshold &&
           (current - baseline) > 0.5; // Ensure significant deviation from baseline
  }

  /// Check if current reading is a valley
  bool _isValley(AccelerometerData data) {
    if (_magnitudeBuffer.length < 5) return false;

    final current = data.magnitude;
    final bufferSize = _magnitudeBuffer.length;
    
    // Check if current value is lower than surrounding values
    // Since buffer is FIFO, the most recent values are at the end
    final previous = _magnitudeBuffer[bufferSize - 2];
    final next = _magnitudeBuffer[bufferSize - 3];
    
    // Use dynamic threshold based on user's baseline
    final baseline = _config.userBaselineMagnitude;
    final valleyThreshold = baseline - _config.adjustedValleyThreshold;
    
    // More robust valley detection with proper buffer indexing
    return current < previous && 
           current < next && 
           current < valleyThreshold &&
           (baseline - current) > 0.3; // Ensure significant deviation from baseline
  }

  /// Handle peak detection
  void _handlePeak(AccelerometerData data) {
    _lastPeakValue = data.magnitude;
    _lastPeakTime = data.timestamp;
    _isLookingForPeak = false;
  }

  /// Handle valley detection
  void _handleValley(AccelerometerData data) {
    _lastValleyValue = data.magnitude;
    _lastValleyTime = data.timestamp;
    _isLookingForPeak = true;

    // Check if this valley represents a valid step
    if (_isValidStep()) {
      _recordStep(data.timestamp);
    }
  }

  /// Validate if the peak-valley pair represents a valid step
  bool _isValidStep() {
    if (_lastPeakTime == null || _lastValleyTime == null) return false;

    // Check time interval between peak and valley (should be short for a single step)
    final peakValleyInterval = _lastValleyTime!.difference(_lastPeakTime!).inMilliseconds;
    if (peakValleyInterval < 50 || peakValleyInterval > 500) { // 50-500ms for peak-valley interval
      return false;
    }

    // Check time since last step (should be reasonable for walking pace)
    if (_lastStepTime != null) {
      final stepInterval = _lastValleyTime!.difference(_lastStepTime!).inMilliseconds;
      if (stepInterval < _config.minStepIntervalMs || stepInterval > _config.maxStepIntervalMs) {
        return false;
      }
    }

    // Check magnitude difference with dynamic threshold
    final magnitudeDifference = _lastPeakValue - _lastValleyValue;
    final baseline = _config.userBaselineMagnitude;
    final minDifference = baseline * 0.05; // 5% of baseline as minimum difference
    
    if (magnitudeDifference < minDifference) {
      return false;
    }

    // Ensure we have enough data for analysis
    if (_magnitudeBuffer.length < 10) return false;

    // Additional validation: check for consistent walking pattern
    if (!_hasConsistentWalkingPattern()) {
      return false;
    }

    debugPrint('Valid step detected: peak=$_lastPeakValue, valley=$_lastValleyValue, diff=$magnitudeDifference, interval=${peakValleyInterval}ms');
    return true;
  }

  /// Check if recent data shows consistent walking pattern
  bool _hasConsistentWalkingPattern() {
    if (_magnitudeBuffer.length < 15) return false;
    
    // Get last 15 readings for better analysis (most recent data)
    final recentData = _magnitudeBuffer.length > 15 
        ? _magnitudeBuffer.sublist(_magnitudeBuffer.length - 15)
        : _magnitudeBuffer.toList();
    final baseline = _config.userBaselineMagnitude;
    
    // Calculate statistics
    final mean = recentData.reduce((a, b) => a + b) / recentData.length;
    final variance = recentData.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / recentData.length;
    final standardDeviation = sqrt(variance);
    
    // Check for walking characteristics:
    // 1. Moderate variation (not too static, not too chaotic)
    // 2. Mean should be close to user's baseline
    // 3. Should have some peaks and valleys
    
    final meanDeviationFromBaseline = (mean - baseline).abs();
    final hasReasonableVariation = standardDeviation > 0.2 && standardDeviation < 1.5;
    final hasReasonableMean = meanDeviationFromBaseline < 1.0;
    
    // Count peaks and valleys in recent data
    int peakCount = 0;
    int valleyCount = 0;
    
    for (int i = 1; i < recentData.length - 1; i++) {
      final current = recentData[i];
      final previous = recentData[i - 1];
      final next = recentData[i + 1];
      
      if (current > previous && current > next && (current - baseline) > 0.3) {
        peakCount++;
      }
      if (current < previous && current < next && (baseline - current) > 0.2) {
        valleyCount++;
      }
    }
    
    final hasPeaksAndValleys = peakCount >= 2 && valleyCount >= 2;
    
    return hasReasonableVariation && hasReasonableMean && hasPeaksAndValleys;
  }

  /// Record a valid step
  void _recordStep(DateTime timestamp) {
    _detectedSteps++;
    _totalSteps++;
    _consecutiveSteps++;
    _lastStepTime = timestamp;

    debugPrint('Step recorded! Total steps: $_totalSteps, Consecutive: $_consecutiveSteps');

    // Emit step count
    _stepsController.add(_totalSteps);

    // Update walking state
    _updateWalkingStateBasedOnSteps();
  }

  /// Update walking state based on consecutive steps
  void _updateWalkingStateBasedOnSteps() {
    if (_consecutiveSteps >= _config.minConsecutiveSteps) {
      if (_currentWalkingState != WalkingState.walking) {
        _updateWalkingState(WalkingState.walking, 'Walking detected - steps are being counted');
      }
    } else if (_consecutiveSteps > 0) {
      if (_currentWalkingState != WalkingState.inconsistent) {
        _updateWalkingState(WalkingState.inconsistent, 'Movement detected - waiting for consistent walking pattern');
      }
    }
    
    // Reset consecutive steps if no step detected for too long
    _checkForWalkingTimeout();
  }

  /// Check if walking has stopped and reset consecutive steps
  void _checkForWalkingTimeout() {
    if (_lastStepTime != null) {
      final timeSinceLastStep = DateTime.now().difference(_lastStepTime!);
      if (timeSinceLastStep.inSeconds > 3) { // 3 seconds without steps
        if (_consecutiveSteps > 0) {
          _consecutiveSteps = 0;
          _updateWalkingState(WalkingState.idle, 'No walking detected - step counting paused');
        }
      }
    }
  }

  /// Update walking state
  void _updateWalkingState(WalkingState newState, String message) {
    if (_currentWalkingState != newState) {
      _currentWalkingState = newState;
      
      // Calculate confidence based on consecutive steps
      double confidence = 0.0;
      if (newState == WalkingState.walking) {
        confidence = min(1.0, _consecutiveSteps / 10.0);
      } else if (newState == WalkingState.inconsistent) {
        confidence = min(0.5, _consecutiveSteps / 5.0);
      }

      final stateData = WalkingStateData(
        state: newState,
        timestamp: DateTime.now(),
        consecutiveSteps: _consecutiveSteps,
        confidence: confidence,
        message: message,
      );

      _walkingStateController.add(stateData);
    }
  }


  /// Reset step count
  void resetSteps() {
    _detectedSteps = 0;
    _totalSteps = 0;
    _consecutiveSteps = 0;
    _lastStepTime = null;
    
    // Reset peak/valley detection state
    _isLookingForPeak = true;
    _lastPeakValue = 0.0;
    _lastValleyValue = 0.0;
    _lastPeakTime = null;
    _lastValleyTime = null;
    
    // Clear buffers
    _accelerationBuffer.clear();
    _magnitudeBuffer.clear();
    
    _stepsController.add(_totalSteps);
    _updateWalkingState(WalkingState.idle, 'Step count reset');
    debugPrint('Step detection reset - all counters and buffers cleared');
  }

  /// Set sensitivity (0.0 to 1.0)
  void setSensitivity(double sensitivity) {
    final clampedSensitivity = sensitivity.clamp(0.0, 1.0);
    _config = _config.copyWith(sensitivity: clampedSensitivity);
  }

  /// Error handler
  void _onError(dynamic error) {
    debugPrint('Advanced step detection error: $error');
    _updateWalkingState(WalkingState.idle, 'Error in step detection: $error');
  }

  /// Dispose resources
  void dispose() {
    _accelerometerSubscription?.cancel();
    _stepsController.close();
    _walkingStateController.close();
    _accelerometerController.close();
  }
}
