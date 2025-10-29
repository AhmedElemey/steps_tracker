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

  StepDetectionConfig _config = const StepDetectionConfig();
  
  final StreamController<int> _stepsController = StreamController<int>.broadcast();
  final StreamController<WalkingStateData> _walkingStateController = StreamController<WalkingStateData>.broadcast();
  final StreamController<AccelerometerData> _accelerometerController = StreamController<AccelerometerData>.broadcast();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  int _detectedSteps = 0;
  int _totalSteps = 0;
  WalkingState _currentWalkingState = WalkingState.idle;
  int _consecutiveSteps = 0;
  DateTime? _lastStepTime;

  final List<AccelerometerData> _accelerationBuffer = [];
  final List<double> _magnitudeBuffer = [];
  final int _bufferSize = 50; // Keep last 50 readings

  bool _isLookingForPeak = true;
  double _lastPeakValue = 0.0;
  double _lastValleyValue = 0.0;
  DateTime? _lastPeakTime;
  DateTime? _lastValleyTime;

  final List<double> _calibrationData = [];
  bool _isCalibrating = false;

  int get detectedSteps => _detectedSteps;
  int get totalSteps => _totalSteps;
  WalkingState get currentWalkingState => _currentWalkingState;
  StepDetectionConfig get config => _config;
  bool get isCalibrating => _isCalibrating;

  Stream<int> get stepsStream => _stepsController.stream;
  Stream<WalkingStateData> get walkingStateStream => _walkingStateController.stream;
  Stream<AccelerometerData> get accelerometerStream => _accelerometerController.stream;

  Future<void> startDetection() async {
    if (_accelerometerSubscription != null) return;

    debugPrint('Starting advanced step detection...');

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

    if (!_config.isCalibrated) {
      debugPrint('Starting calibration...');
      await _startCalibration();
    } else {
      debugPrint('Using existing calibration');
    }

    _updateWalkingState(WalkingState.idle, 'Step detection started - only counting actual walking steps');
  }

  Future<void> stopDetection() async {
    await _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _updateWalkingState(WalkingState.idle, 'Step detection stopped');
  }

  void updateConfig(StepDetectionConfig newConfig) {
    _config = newConfig;
    debugPrint('Step detection config updated: $newConfig');
  }

  void resetCounters() {
    _detectedSteps = 0;
    _totalSteps = 0;
    _consecutiveSteps = 0;
    _lastStepTime = null;
    _currentWalkingState = WalkingState.idle;
    
    _accelerationBuffer.clear();
    _magnitudeBuffer.clear();
    
    _isLookingForPeak = true;
    _lastPeakValue = 0.0;
    _lastValleyValue = 0.0;
    _lastPeakTime = null;
    _lastValleyTime = null;
    
    debugPrint('Step counters reset');
  }

  Future<void> recalibrate() async {
    debugPrint('Manual recalibration requested');
    _config = _config.copyWith(isCalibrated: false);
    await _startCalibration();
  }

  Future<void> _startCalibration() async {
    _isCalibrating = true;
    _calibrationData.clear();
    _updateWalkingState(WalkingState.calibrating, 'Calibrating... Please walk normally for 15 seconds');

    debugPrint('Starting calibration - collecting data for 15 seconds...');

    Timer(const Duration(seconds: 15), () {
      if (_isCalibrating) {
        _completeCalibration();
      }
    });
  }

  void _completeCalibration() {
    if (_calibrationData.isEmpty) {
      debugPrint('Calibration failed - no data collected');
      _isCalibrating = false;
      _updateWalkingState(WalkingState.idle, 'Calibration failed - no data collected');
      return;
    }

    debugPrint('Calibration data collected: ${_calibrationData.length} samples');

    _calibrationData.sort();
    final medianIndex = _calibrationData.length ~/ 2;
    final baselineMagnitude = _calibrationData[medianIndex];

    final mean = _calibrationData.reduce((a, b) => a + b) / _calibrationData.length;
    final variance = _calibrationData.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / _calibrationData.length;
    final standardDeviation = sqrt(variance);

    debugPrint('Calculated baseline magnitude: $baselineMagnitude');
    debugPrint('Mean: $mean, StdDev: $standardDeviation');

    _config = _config.copyWith(
      isCalibrated: true,
      userBaselineMagnitude: baselineMagnitude,
      minMagnitudeThreshold: (baselineMagnitude - standardDeviation * 1.5).clamp(7.0, 9.0),
      maxMagnitudeThreshold: (baselineMagnitude + standardDeviation * 2.5).clamp(12.0, 20.0),
    );

    _isCalibrating = false;
    _updateWalkingState(WalkingState.idle, 'Calibration complete! Ready to detect steps.');
  }

  void _onAccelerometerData(AccelerometerEvent event) {
    final accelerometerData = AccelerometerData(
      x: event.x,
      y: event.y,
      z: event.z,
      timestamp: DateTime.now(),
    );

    _accelerometerController.add(accelerometerData);

    _addToBuffer(accelerometerData);

    if (_isCalibrating) {
      _calibrationData.add(accelerometerData.magnitude);
      return;
    }

    _processStepDetection(accelerometerData);
  }

  void _addToBuffer(AccelerometerData data) {
    _accelerationBuffer.add(data);
    _magnitudeBuffer.add(data.magnitude);

    if (_accelerationBuffer.length > _bufferSize) {
      _accelerationBuffer.removeAt(0);
      _magnitudeBuffer.removeAt(0);
    }
  }

  void _processStepDetection(AccelerometerData data) {
    if (!_isValidMovement(data.magnitude)) {
      return;
    }

    if (_magnitudeBuffer.length % 500 == 0) {
      debugPrint('Processing accelerometer data: magnitude=${data.magnitude.toStringAsFixed(2)}, baseline=${_config.userBaselineMagnitude.toStringAsFixed(2)}, buffer_size=${_magnitudeBuffer.length}');
    }

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

  bool _isValidMovement(double magnitude) {
    final baseline = _config.userBaselineMagnitude;
    final minThreshold = _config.adjustedMinMagnitude;
    final maxThreshold = _config.adjustedMaxMagnitude;
    
    final lowerBound = (baseline - 3.0).clamp(minThreshold, baseline);
    final upperBound = (baseline + 8.0).clamp(baseline, maxThreshold);
    
    return magnitude >= lowerBound && magnitude <= upperBound;
  }

  bool _isPeak(AccelerometerData data) {
    if (_magnitudeBuffer.length < 3) return false;

    final current = data.magnitude;
    final bufferSize = _magnitudeBuffer.length;
    
    final previous = _magnitudeBuffer[bufferSize - 2];
    final next = _magnitudeBuffer[bufferSize - 3];
    
    final baseline = _config.userBaselineMagnitude;
    final peakThreshold = baseline + _config.adjustedPeakThreshold;
    
    return current > previous && 
           current > next && 
           current > peakThreshold &&
           (current - baseline) > 0.2; // Reduced threshold for better sensitivity
  }

  bool _isValley(AccelerometerData data) {
    if (_magnitudeBuffer.length < 3) return false;

    final current = data.magnitude;
    final bufferSize = _magnitudeBuffer.length;
    
    final previous = _magnitudeBuffer[bufferSize - 2];
    final next = _magnitudeBuffer[bufferSize - 3];
    
    final baseline = _config.userBaselineMagnitude;
    final valleyThreshold = baseline - _config.adjustedValleyThreshold;
    
    return current < previous && 
           current < next && 
           current < valleyThreshold &&
           (baseline - current) > 0.1; // Reduced threshold for better sensitivity
  }

  void _handlePeak(AccelerometerData data) {
    _lastPeakValue = data.magnitude;
    _lastPeakTime = data.timestamp;
    _isLookingForPeak = false;
  }

  void _handleValley(AccelerometerData data) {
    _lastValleyValue = data.magnitude;
    _lastValleyTime = data.timestamp;
    _isLookingForPeak = true;

    if (_isValidStep()) {
      _recordStep(data.timestamp);
    }
  }

  bool _isValidStep() {
    if (_lastPeakTime == null || _lastValleyTime == null) return false;

    final peakValleyInterval = _lastValleyTime!.difference(_lastPeakTime!).inMilliseconds;
    if (peakValleyInterval < 30 || peakValleyInterval > 800) { // More lenient: 30-800ms for peak-valley interval
      return false;
    }

    if (_lastStepTime != null) {
      final stepInterval = _lastValleyTime!.difference(_lastStepTime!).inMilliseconds;
      if (stepInterval < _config.minStepIntervalMs || stepInterval > _config.maxStepIntervalMs) {
        return false;
      }
    }

    final magnitudeDifference = _lastPeakValue - _lastValleyValue;
    final baseline = _config.userBaselineMagnitude;
    final minDifference = baseline * 0.02; // Reduced to 2% of baseline as minimum difference
    
    if (magnitudeDifference < minDifference) {
      return false;
    }

    if (_magnitudeBuffer.length < 5) return false;

    debugPrint('Valid step detected: peak=$_lastPeakValue, valley=$_lastValleyValue, diff=$magnitudeDifference, interval=${peakValleyInterval}ms');
    return true;
  }


  void _recordStep(DateTime timestamp) {
    _detectedSteps++;
    _totalSteps++;
    _consecutiveSteps++;
    _lastStepTime = timestamp;

    debugPrint('Step recorded! Total steps: $_totalSteps, Consecutive: $_consecutiveSteps');

    _stepsController.add(_totalSteps);

    _updateWalkingStateBasedOnSteps();
  }

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
    
    _checkForWalkingTimeout();
  }

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

  void _updateWalkingState(WalkingState newState, String message) {
    if (_currentWalkingState != newState) {
      _currentWalkingState = newState;
      
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


  void resetSteps() {
    _detectedSteps = 0;
    _totalSteps = 0;
    _consecutiveSteps = 0;
    _lastStepTime = null;
    
    _isLookingForPeak = true;
    _lastPeakValue = 0.0;
    _lastValleyValue = 0.0;
    _lastPeakTime = null;
    _lastValleyTime = null;
    
    _accelerationBuffer.clear();
    _magnitudeBuffer.clear();
    
    _stepsController.add(_totalSteps);
    _updateWalkingState(WalkingState.idle, 'Step count reset');
    debugPrint('Step detection reset - all counters and buffers cleared');
  }

  void setSensitivity(double sensitivity) {
    final clampedSensitivity = sensitivity.clamp(0.0, 1.0);
    _config = _config.copyWith(sensitivity: clampedSensitivity);
  }

  void _onError(dynamic error) {
    debugPrint('Advanced step detection error: $error');
    _updateWalkingState(WalkingState.idle, 'Error in step detection: $error');
  }

  void dispose() {
    _accelerometerSubscription?.cancel();
    _stepsController.close();
    _walkingStateController.close();
    _accelerometerController.close();
  }
}
