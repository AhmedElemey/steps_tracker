import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/accelerometer_data.dart';
import '../models/step_detection_config.dart';
import '../models/walking_state.dart';

/// Enhanced Peak Detection Service with advanced signal processing
/// 
/// This implementation improves upon basic peak detection by incorporating:
/// - Advanced signal preprocessing with multiple filter stages
/// - Adaptive thresholding based on signal characteristics
/// - Multi-axis analysis for better device orientation handling
/// - Statistical validation of step patterns
/// - Improved handling of semi-regular and unstructured gaits
class EnhancedPeakDetectionService {
  static final EnhancedPeakDetectionService _instance = EnhancedPeakDetectionService._internal();
  factory EnhancedPeakDetectionService() => _instance;
  EnhancedPeakDetectionService._internal();

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

  // Enhanced signal processing buffers
  final List<AccelerometerData> _rawBuffer = [];
  final List<double> _magnitudeBuffer = [];
  final List<double> _filteredBuffer = [];
  final List<double> _smoothedBuffer = [];
  final int _bufferSize = 100; // 1 second at 100Hz
  
  // Multi-axis analysis
  final List<double> _xBuffer = [];
  final List<double> _yBuffer = [];
  final List<double> _zBuffer = [];
  
  // Adaptive thresholding
  double _dynamicPeakThreshold = 0.6;
  double _dynamicValleyThreshold = 0.4;
  final List<double> _thresholdHistory = [];
  final int _thresholdHistorySize = 20;
  
  // Peak detection state
  bool _isLookingForPeak = true;
  double _lastPeakValue = 0.0;
  double _lastValleyValue = 0.0;
  DateTime? _lastPeakTime;
  DateTime? _lastValleyTime;
  
  // Statistical analysis
  final List<double> _stepIntervals = [];
  final List<double> _stepMagnitudes = [];
  final int _statsHistorySize = 50;
  
  // Filter coefficients (Butterworth low-pass, cutoff ~8Hz)
  final List<double> _lowPassCoeffs = [0.0201, 0.0402, 0.0201, -1.5610, 0.6414];
  final List<double> _lowPassState = [0.0, 0.0, 0.0, 0.0, 0.0];
  
  // Smoothing filter (moving average)
  final int _smoothingWindow = 5;

  // Getters
  int get detectedSteps => _detectedSteps;
  int get totalSteps => _totalSteps;
  WalkingState get currentWalkingState => _currentWalkingState;
  StepDetectionConfig get config => _config;
  double get dynamicPeakThreshold => _dynamicPeakThreshold;
  double get dynamicValleyThreshold => _dynamicValleyThreshold;

  // Streams
  Stream<int> get stepsStream => _stepsController.stream;
  Stream<WalkingStateData> get walkingStateStream => _walkingStateController.stream;
  Stream<AccelerometerData> get accelerometerStream => _accelerometerController.stream;

  /// Start enhanced peak detection
  Future<void> startDetection() async {
    if (_accelerometerSubscription != null) return;

    debugPrint('Starting enhanced peak detection...');

    // Reset all counters
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
      debugPrint('Enhanced peak detection stream started successfully');
    } catch (e) {
      debugPrint('Error starting enhanced peak detection stream: $e');
      _updateWalkingState(WalkingState.idle, 'Error starting accelerometer: $e');
      return;
    }

    _updateWalkingState(WalkingState.idle, 'Enhanced peak detection started - using advanced signal processing');
  }

  /// Stop the step detection
  Future<void> stopDetection() async {
    await _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _updateWalkingState(WalkingState.idle, 'Enhanced peak detection stopped');
  }

  /// Update configuration
  void updateConfig(StepDetectionConfig newConfig) {
    _config = newConfig;
    debugPrint('Enhanced peak detection config updated: $newConfig');
  }

  /// Process accelerometer data with enhanced signal processing
  void _onAccelerometerData(AccelerometerEvent event) {
    final accelerometerData = AccelerometerData(
      x: event.x,
      y: event.y,
      z: event.z,
      timestamp: DateTime.now(),
    );

    // Emit raw accelerometer data
    _accelerometerController.add(accelerometerData);

    // Add to buffers
    _addToBuffers(accelerometerData);

    // Process when we have enough data
    if (_rawBuffer.length >= 10) {
      _processEnhancedStepDetection();
    }
  }

  /// Add data to all processing buffers
  void _addToBuffers(AccelerometerData data) {
    _rawBuffer.add(data);
    _magnitudeBuffer.add(data.magnitude);
    _xBuffer.add(data.x);
    _yBuffer.add(data.y);
    _zBuffer.add(data.z);

    // Keep buffer sizes manageable
    if (_rawBuffer.length > _bufferSize) {
      _rawBuffer.removeAt(0);
      _magnitudeBuffer.removeAt(0);
      _xBuffer.removeAt(0);
      _yBuffer.removeAt(0);
      _zBuffer.removeAt(0);
    }
  }

  /// Main enhanced step detection algorithm
  void _processEnhancedStepDetection() {
    // Step 1: Multi-axis signal preprocessing
    final processedSignal = _preprocessSignal();
    
    // Step 2: Adaptive threshold calculation
    _updateAdaptiveThresholds(processedSignal);
    
    // Step 3: Enhanced peak detection
    _detectEnhancedPeaks(processedSignal);
  }

  /// Preprocess signal with multiple filter stages
  List<double> _preprocessSignal() {
    if (_magnitudeBuffer.length < 5) return _magnitudeBuffer;
    
    // Stage 1: Low-pass filter to remove high-frequency noise
    final lowPassFiltered = _applyLowPassFilter(_magnitudeBuffer);
    
    // Stage 2: Smoothing to reduce jitter
    final smoothed = _applySmoothingFilter(lowPassFiltered);
    
    // Stage 3: Baseline removal (remove gravity component)
    final baselineRemoved = _removeBaseline(smoothed);
    
    return baselineRemoved;
  }

  /// Apply low-pass filter
  List<double> _applyLowPassFilter(List<double> signal) {
    final filtered = <double>[];
    
    for (int i = 0; i < signal.length; i++) {
      // Apply Butterworth low-pass filter
      double output = _lowPassCoeffs[0] * signal[i];
      
      for (int j = 1; j < _lowPassCoeffs.length - 2; j++) {
        if (i >= j) {
          output += _lowPassCoeffs[j] * signal[i - j];
        }
      }
      
      for (int j = 0; j < _lowPassState.length; j++) {
        if (i >= j + 1) {
          output -= _lowPassCoeffs[j + 3] * _lowPassState[j];
        }
      }
      
      // Update filter state
      for (int j = _lowPassState.length - 1; j > 0; j--) {
        _lowPassState[j] = _lowPassState[j - 1];
      }
      _lowPassState[0] = output;
      
      filtered.add(output);
    }
    
    return filtered;
  }

  /// Apply smoothing filter (moving average)
  List<double> _applySmoothingFilter(List<double> signal) {
    final smoothed = <double>[];
    
    for (int i = 0; i < signal.length; i++) {
      double sum = 0.0;
      int count = 0;
      
      for (int j = max(0, i - _smoothingWindow + 1); j <= i; j++) {
        sum += signal[j];
        count++;
      }
      
      smoothed.add(sum / count);
    }
    
    return smoothed;
  }

  /// Remove baseline (gravity component)
  List<double> _removeBaseline(List<double> signal) {
    if (signal.isEmpty) return signal;
    
    // Calculate baseline as median of recent values
    final recentValues = signal.length > 20 ? signal.sublist(signal.length - 20) : signal;
    recentValues.sort();
    final baseline = recentValues[recentValues.length ~/ 2];
    
    // Remove baseline
    return signal.map((value) => value - baseline).toList();
  }

  /// Update adaptive thresholds based on signal characteristics
  void _updateAdaptiveThresholds(List<double> signal) {
    if (signal.length < 10) return;
    
    // Calculate signal statistics
    final mean = signal.reduce((a, b) => a + b) / signal.length;
    final variance = signal.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / signal.length;
    final stdDev = sqrt(variance);
    
    // Calculate adaptive thresholds based on signal characteristics
    final baseThreshold = stdDev * 0.8; // Base threshold as fraction of standard deviation
    final peakThreshold = baseThreshold * (1.0 + _config.sensitivity);
    final valleyThreshold = baseThreshold * (1.0 - _config.sensitivity * 0.5);
    
    // Update thresholds with smoothing
    _dynamicPeakThreshold = _dynamicPeakThreshold * 0.8 + peakThreshold * 0.2;
    _dynamicValleyThreshold = _dynamicValleyThreshold * 0.8 + valleyThreshold * 0.2;
    
    // Store in history for analysis
    _thresholdHistory.add(_dynamicPeakThreshold);
    if (_thresholdHistory.length > _thresholdHistorySize) {
      _thresholdHistory.removeAt(0);
    }
  }

  /// Enhanced peak detection with multi-criteria validation
  void _detectEnhancedPeaks(List<double> signal) {
    if (signal.length < 5) return;
    
    final current = signal.last;
    final previous = signal[signal.length - 2];
    final next = signal.length > 2 ? signal[signal.length - 3] : current;
    
    // Detect peaks and valleys with enhanced criteria
    if (_isLookingForPeak) {
      if (_isEnhancedPeak(current, previous, next, signal)) {
        _handleEnhancedPeak(current);
      }
    } else {
      if (_isEnhancedValley(current, previous, next, signal)) {
        _handleEnhancedValley(current);
      }
    }
  }

  /// Enhanced peak detection with multiple validation criteria
  bool _isEnhancedPeak(double current, double previous, double next, List<double> signal) {
    // Basic peak criteria
    if (current <= previous || current <= next) return false;
    
    // Magnitude threshold
    if (current < _dynamicPeakThreshold) return false;
    
    // Statistical validation - check if peak is significant relative to recent signal
    if (signal.length >= 10) {
      final recentSignal = signal.sublist(signal.length - 10);
      final mean = recentSignal.reduce((a, b) => a + b) / recentSignal.length;
      final stdDev = sqrt(recentSignal.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / recentSignal.length);
      
      // Peak should be at least 2 standard deviations above mean
      if (current < mean + 2 * stdDev) return false;
    }
    
    // Multi-axis validation - check if peak is consistent across axes
    if (_rawBuffer.length >= 5) {
      final recentX = _xBuffer.sublist(max(0, _xBuffer.length - 5));
      final recentY = _yBuffer.sublist(max(0, _yBuffer.length - 5));
      final recentZ = _zBuffer.sublist(max(0, _zBuffer.length - 5));
      
      // Check if there's significant movement in at least one axis
      final xVariation = _calculateVariation(recentX);
      final yVariation = _calculateVariation(recentY);
      final zVariation = _calculateVariation(recentZ);
      
      final maxVariation = [xVariation, yVariation, zVariation].reduce(max);
      if (maxVariation < 0.5) return false; // Not enough movement
    }
    
    return true;
  }

  /// Enhanced valley detection with multiple validation criteria
  bool _isEnhancedValley(double current, double previous, double next, List<double> signal) {
    // Basic valley criteria
    if (current >= previous || current >= next) return false;
    
    // Magnitude threshold
    if (current > -_dynamicValleyThreshold) return false;
    
    // Statistical validation
    if (signal.length >= 10) {
      final recentSignal = signal.sublist(signal.length - 10);
      final mean = recentSignal.reduce((a, b) => a + b) / recentSignal.length;
      final stdDev = sqrt(recentSignal.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / recentSignal.length);
      
      // Valley should be at least 1.5 standard deviations below mean
      if (current > mean - 1.5 * stdDev) return false;
    }
    
    return true;
  }

  /// Calculate variation in a signal
  double _calculateVariation(List<double> signal) {
    if (signal.length < 2) return 0.0;
    
    final mean = signal.reduce((a, b) => a + b) / signal.length;
    final variance = signal.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / signal.length;
    return sqrt(variance);
  }

  /// Handle enhanced peak detection
  void _handleEnhancedPeak(double value) {
    _lastPeakValue = value;
    _lastPeakTime = DateTime.now();
    _isLookingForPeak = false;
    
    debugPrint('Enhanced peak detected: ${value.toStringAsFixed(3)} (threshold: ${_dynamicPeakThreshold.toStringAsFixed(3)})');
  }

  /// Handle enhanced valley detection
  void _handleEnhancedValley(double value) {
    _lastValleyValue = value;
    _lastValleyTime = DateTime.now();
    _isLookingForPeak = true;

    // Validate step with enhanced criteria
    if (_isValidEnhancedStep()) {
      _recordEnhancedStep();
    }
  }

  /// Enhanced step validation with statistical analysis
  bool _isValidEnhancedStep() {
    if (_lastPeakTime == null || _lastValleyTime == null) return false;

    // Time interval validation
    final peakValleyInterval = _lastValleyTime!.difference(_lastPeakTime!).inMilliseconds;
    if (peakValleyInterval < 50 || peakValleyInterval > 500) return false;

    // Step interval validation
    if (_lastStepTime != null) {
      final stepInterval = _lastValleyTime!.difference(_lastStepTime!).inMilliseconds;
      if (stepInterval < _config.minStepIntervalMs || stepInterval > _config.maxStepIntervalMs) {
        return false;
      }
      
      // Statistical validation of step intervals
      _stepIntervals.add(stepInterval.toDouble());
      if (_stepIntervals.length > _statsHistorySize) {
        _stepIntervals.removeAt(0);
      }
      
      if (_stepIntervals.length >= 5) {
        final meanInterval = _stepIntervals.reduce((a, b) => a + b) / _stepIntervals.length;
        final intervalVariance = _stepIntervals.map((x) => pow(x - meanInterval, 2)).reduce((a, b) => a + b) / _stepIntervals.length;
        final intervalStdDev = sqrt(intervalVariance);
        
        // Reject if interval is too far from mean (handles semi-regular gaits)
        if ((stepInterval - meanInterval).abs() > 3 * intervalStdDev) {
          return false;
        }
      }
    }

    // Magnitude difference validation
    final magnitudeDifference = _lastPeakValue - _lastValleyValue;
    if (magnitudeDifference < _dynamicPeakThreshold * 0.3) return false;
    
    // Store magnitude for statistical analysis
    _stepMagnitudes.add(magnitudeDifference);
    if (_stepMagnitudes.length > _statsHistorySize) {
      _stepMagnitudes.removeAt(0);
    }

    // Pattern consistency validation
    if (!_hasConsistentWalkingPattern()) return false;

    debugPrint('Valid enhanced step: peak=${_lastPeakValue.toStringAsFixed(3)}, valley=${_lastValleyValue.toStringAsFixed(3)}, diff=${magnitudeDifference.toStringAsFixed(3)}');
    return true;
  }

  /// Enhanced walking pattern consistency check
  bool _hasConsistentWalkingPattern() {
    if (_magnitudeBuffer.length < 20) return false;
    
    // Analyze recent signal for walking characteristics
    final recentSignal = _magnitudeBuffer.sublist(max(0, _magnitudeBuffer.length - 20));
    
    // Calculate signal characteristics
    final mean = recentSignal.reduce((a, b) => a + b) / recentSignal.length;
    final variance = recentSignal.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / recentSignal.length;
    final stdDev = sqrt(variance);
    
    // Check for walking characteristics
    final hasReasonableVariation = stdDev > 0.1 && stdDev < 2.0;
    final hasReasonableMean = mean > 8.0 && mean < 15.0;
    
    // Count significant peaks and valleys
    int significantPeaks = 0;
    int significantValleys = 0;
    
    for (int i = 1; i < recentSignal.length - 1; i++) {
      final current = recentSignal[i];
      final previous = recentSignal[i - 1];
      final next = recentSignal[i + 1];
      
      if (current > previous && current > next && (current - mean) > stdDev) {
        significantPeaks++;
      }
      if (current < previous && current < next && (mean - current) > stdDev * 0.5) {
        significantValleys++;
      }
    }
    
    final hasPeaksAndValleys = significantPeaks >= 2 && significantValleys >= 2;
    
    return hasReasonableVariation && hasReasonableMean && hasPeaksAndValleys;
  }

  /// Record enhanced step
  void _recordEnhancedStep() {
    _detectedSteps++;
    _totalSteps++;
    _consecutiveSteps++;
    _lastStepTime = DateTime.now();

    debugPrint('Enhanced step recorded! Total: $_totalSteps, Consecutive: $_consecutiveSteps');

    // Emit step count
    _stepsController.add(_totalSteps);

    // Update walking state
    _updateWalkingStateBasedOnSteps();
  }

  /// Update walking state based on consecutive steps
  void _updateWalkingStateBasedOnSteps() {
    if (_consecutiveSteps >= _config.minConsecutiveSteps) {
      if (_currentWalkingState != WalkingState.walking) {
        _updateWalkingState(WalkingState.walking, 
          'Walking detected - enhanced peak detection active');
      }
    } else if (_consecutiveSteps > 0) {
      if (_currentWalkingState != WalkingState.inconsistent) {
        _updateWalkingState(WalkingState.inconsistent, 
          'Movement detected - analyzing enhanced patterns');
      }
    }
    
    // Reset consecutive steps if no step detected for too long
    _checkForWalkingTimeout();
  }

  /// Check if walking has stopped and reset consecutive steps
  void _checkForWalkingTimeout() {
    if (_lastStepTime != null) {
      final timeSinceLastStep = DateTime.now().difference(_lastStepTime!);
      if (timeSinceLastStep.inSeconds > 3) {
        if (_consecutiveSteps > 0) {
          _consecutiveSteps = 0;
          _updateWalkingState(WalkingState.idle, 'No walking detected - enhanced detection paused');
        }
      }
    }
  }

  /// Update walking state
  void _updateWalkingState(WalkingState newState, String message) {
    if (_currentWalkingState != newState) {
      _currentWalkingState = newState;
      
      // Calculate confidence based on consecutive steps and signal quality
      double confidence = 0.0;
      if (newState == WalkingState.walking) {
        confidence = min(1.0, _consecutiveSteps / 10.0);
        
        // Add signal quality to confidence
        if (_stepMagnitudes.length >= 3) {
          final meanMagnitude = _stepMagnitudes.reduce((a, b) => a + b) / _stepMagnitudes.length;
          final magnitudeVariance = _stepMagnitudes.map((x) => pow(x - meanMagnitude, 2)).reduce((a, b) => a + b) / _stepMagnitudes.length;
          final magnitudeStdDev = sqrt(magnitudeVariance);
          final signalQuality = max(0.0, 1.0 - magnitudeStdDev / meanMagnitude);
          confidence = (confidence + signalQuality) / 2.0;
        }
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

  /// Reset step counters
  void resetCounters() {
    _detectedSteps = 0;
    _totalSteps = 0;
    _consecutiveSteps = 0;
    _lastStepTime = null;
    _currentWalkingState = WalkingState.idle;
    
    // Clear all buffers
    _rawBuffer.clear();
    _magnitudeBuffer.clear();
    _filteredBuffer.clear();
    _smoothedBuffer.clear();
    _xBuffer.clear();
    _yBuffer.clear();
    _zBuffer.clear();
    _thresholdHistory.clear();
    _stepIntervals.clear();
    _stepMagnitudes.clear();
    
    // Reset peak/valley detection
    _isLookingForPeak = true;
    _lastPeakValue = 0.0;
    _lastValleyValue = 0.0;
    _lastPeakTime = null;
    _lastValleyTime = null;
    
    // Reset filter state
    for (int i = 0; i < _lowPassState.length; i++) {
      _lowPassState[i] = 0.0;
    }
    
    _stepsController.add(_totalSteps);
    _updateWalkingState(WalkingState.idle, 'Enhanced peak detection reset');
    debugPrint('Enhanced peak detection reset - all counters and buffers cleared');
  }

  /// Error handler
  void _onError(dynamic error) {
    debugPrint('Enhanced peak detection error: $error');
    _updateWalkingState(WalkingState.idle, 'Error in enhanced peak detection: $error');
  }

  /// Dispose resources
  void dispose() {
    _accelerometerSubscription?.cancel();
    _stepsController.close();
    _walkingStateController.close();
    _accelerometerController.close();
  }
}
