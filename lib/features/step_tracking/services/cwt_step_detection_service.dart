import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/accelerometer_data.dart';
import '../models/step_detection_config.dart';
import '../models/walking_state.dart';

/// Continuous Wavelet Transform (CWT) based step detection service
/// 
/// This implementation uses CWT to project accelerometer signals into the 
/// time-frequency domain to identify dominant step frequencies (1.4-2.3 Hz).
/// Based on research showing CWT's robustness across different body locations
/// and gait patterns.
class CWTStepDetectionService {
  static final CWTStepDetectionService _instance = CWTStepDetectionService._internal();
  factory CWTStepDetectionService() => _instance;
  CWTStepDetectionService._internal();

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

  // CWT-specific variables
  final List<double> _signalBuffer = [];
  final List<double> _filteredBuffer = [];
  final int _bufferSize = 200; // 2 seconds at 100Hz
  final int _windowSize = 100; // 1 second windows for frequency analysis
  
  // Frequency analysis
  final double _minStepFreq = 1.4; // Hz - minimum walking frequency
  final double _maxStepFreq = 2.3; // Hz - maximum walking frequency
  final double _samplingRate = 100.0; // Hz - target sampling rate
  
  // Low-pass filter coefficients (Butterworth filter)
  final List<double> _filterCoeffs = [0.0201, 0.0402, 0.0201, -1.5610, 0.6414];
  final List<double> _filterState = [0.0, 0.0, 0.0, 0.0, 0.0];
  
  // Step frequency tracking
  double _currentStepFreq = 0.0;
  final List<double> _freqHistory = [];
  final int _freqHistorySize = 10;

  // Getters
  int get detectedSteps => _detectedSteps;
  int get totalSteps => _totalSteps;
  WalkingState get currentWalkingState => _currentWalkingState;
  StepDetectionConfig get config => _config;
  double get currentStepFreq => _currentStepFreq;

  // Streams
  Stream<int> get stepsStream => _stepsController.stream;
  Stream<WalkingStateData> get walkingStateStream => _walkingStateController.stream;
  Stream<AccelerometerData> get accelerometerStream => _accelerometerController.stream;

  /// Start CWT-based step detection
  Future<void> startDetection() async {
    if (_accelerometerSubscription != null) return;

    debugPrint('Starting CWT-based step detection...');

    // Reset all counters
    _detectedSteps = 0;
    _totalSteps = 0;
    _consecutiveSteps = 0;
    _lastStepTime = null;
    _currentWalkingState = WalkingState.idle;
    _currentStepFreq = 0.0;

    try {
      _accelerometerSubscription = accelerometerEventStream().listen(
        _onAccelerometerData,
        onError: _onError,
      );
      debugPrint('CWT accelerometer stream started successfully');
    } catch (e) {
      debugPrint('Error starting CWT accelerometer stream: $e');
      _updateWalkingState(WalkingState.idle, 'Error starting accelerometer: $e');
      return;
    }

    _updateWalkingState(WalkingState.idle, 'CWT step detection started - analyzing frequency patterns');
  }

  /// Stop the step detection
  Future<void> stopDetection() async {
    await _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _updateWalkingState(WalkingState.idle, 'CWT step detection stopped');
  }

  /// Update configuration
  void updateConfig(StepDetectionConfig newConfig) {
    _config = newConfig;
    debugPrint('CWT step detection config updated: $newConfig');
  }

  /// Process accelerometer data using CWT approach
  void _onAccelerometerData(AccelerometerEvent event) {
    final accelerometerData = AccelerometerData(
      x: event.x,
      y: event.y,
      z: event.z,
      timestamp: DateTime.now(),
    );

    // Emit raw accelerometer data
    _accelerometerController.add(accelerometerData);

    // Add to signal buffer
    _addToSignalBuffer(accelerometerData.magnitude);

    // Process when we have enough data
    if (_signalBuffer.length >= _windowSize) {
      _processCWTStepDetection();
    }
  }

  /// Add magnitude to signal buffer
  void _addToSignalBuffer(double magnitude) {
    _signalBuffer.add(magnitude);
    
    // Keep buffer size manageable
    if (_signalBuffer.length > _bufferSize) {
      _signalBuffer.removeAt(0);
    }
  }

  /// Main CWT step detection algorithm
  void _processCWTStepDetection() {
    // Get the most recent window of data
    final windowStart = max(0, _signalBuffer.length - _windowSize);
    final signalWindow = _signalBuffer.sublist(windowStart);
    
    // Step 1: Preprocessing - Apply low-pass filter to remove gravity and high-frequency noise
    final filteredSignal = _applyLowPassFilter(signalWindow);
    
    // Step 2: Frequency Analysis - Apply CWT to identify dominant step frequency
    final dominantFreq = _analyzeStepFrequency(filteredSignal);
    
    if (dominantFreq > 0) {
      _currentStepFreq = dominantFreq;
      _updateFrequencyHistory(dominantFreq);
      
      // Step 3: Step Counting - Estimate steps in non-overlapping 1-second windows
      final estimatedSteps = _estimateStepsFromFrequency(dominantFreq);
      
      if (estimatedSteps > 0) {
        _recordSteps(estimatedSteps);
      }
    }
  }

  /// Apply low-pass filter to remove gravity and high-frequency noise
  List<double> _applyLowPassFilter(List<double> signal) {
    final filtered = <double>[];
    
    for (int i = 0; i < signal.length; i++) {
      // Apply Butterworth low-pass filter (cutoff ~5Hz)
      double output = _filterCoeffs[0] * signal[i];
      
      for (int j = 1; j < _filterCoeffs.length - 2; j++) {
        if (i >= j) {
          output += _filterCoeffs[j] * signal[i - j];
        }
      }
      
      for (int j = 0; j < _filterState.length; j++) {
        if (i >= j + 1) {
          output -= _filterCoeffs[j + 3] * _filterState[j];
        }
      }
      
      // Update filter state
      for (int j = _filterState.length - 1; j > 0; j--) {
        _filterState[j] = _filterState[j - 1];
      }
      _filterState[0] = output;
      
      filtered.add(output);
    }
    
    return filtered;
  }

  /// Analyze step frequency using simplified CWT approach
  double _analyzeStepFrequency(List<double> signal) {
    // Simplified CWT implementation using FFT-based approach
    // In a full implementation, you would use a proper CWT library
    
    final fft = _computeFFT(signal);
    final frequencies = _computeFrequencies(signal.length);
    
    // Find dominant frequency in step frequency range (1.4-2.3 Hz)
    double maxMagnitude = 0.0;
    double dominantFreq = 0.0;
    
    for (int i = 0; i < frequencies.length; i++) {
      final freq = frequencies[i];
      if (freq >= _minStepFreq && freq <= _maxStepFreq) {
        final magnitude = fft[i].abs();
        if (magnitude > maxMagnitude) {
          maxMagnitude = magnitude;
          dominantFreq = freq;
        }
      }
    }
    
    // Only return frequency if it's significantly above noise floor
    final noiseFloor = _estimateNoiseFloor(fft);
    if (maxMagnitude > noiseFloor * 2.0) {
      return dominantFreq;
    }
    
    return 0.0;
  }

  /// Simplified FFT computation (for demonstration - use proper FFT library in production)
  List<Complex> _computeFFT(List<double> signal) {
    // This is a simplified implementation
    // In production, use a proper FFT library like fft or dsp
    final n = signal.length;
    final fft = List<Complex>.generate(n, (i) => Complex(signal[i], 0.0));
    
    // Simple DFT implementation (not optimized)
    for (int k = 0; k < n; k++) {
      Complex sum = Complex(0.0, 0.0);
      for (int j = 0; j < n; j++) {
        final angle = -2 * pi * k * j / n;
        sum += Complex(cos(angle), sin(angle)).multiply(signal[j]);
      }
      fft[k] = sum;
    }
    
    return fft;
  }

  /// Compute frequency bins for FFT
  List<double> _computeFrequencies(int n) {
    final frequencies = <double>[];
    for (int i = 0; i < n; i++) {
      frequencies.add(i * _samplingRate / n);
    }
    return frequencies;
  }

  /// Estimate noise floor in frequency domain
  double _estimateNoiseFloor(List<Complex> fft) {
    // Use median of magnitudes as noise floor estimate
    final magnitudes = fft.map((c) => c.abs()).toList()..sort();
    return magnitudes[magnitudes.length ~/ 2];
  }

  /// Update frequency history for stability
  void _updateFrequencyHistory(double freq) {
    _freqHistory.add(freq);
    if (_freqHistory.length > _freqHistorySize) {
      _freqHistory.removeAt(0);
    }
  }

  /// Estimate steps from frequency
  int _estimateStepsFromFrequency(double freq) {
    if (freq <= 0) return 0;
    
    // Convert frequency to steps per second
    final stepsPerSecond = freq;
    
    // Check if frequency is stable (not too much variation)
    if (_freqHistory.length >= 3) {
      final recentFreqs = _freqHistory.sublist(max(0, _freqHistory.length - 3));
      final mean = recentFreqs.reduce((a, b) => a + b) / recentFreqs.length;
      final variance = recentFreqs.map((f) => pow(f - mean, 2)).reduce((a, b) => a + b) / recentFreqs.length;
      
      // If frequency is too unstable, don't count steps
      if (variance > 0.1) {
        return 0;
      }
    }
    
    // Estimate steps in 1-second window
    final estimatedSteps = (stepsPerSecond * 1.0).round();
    
    // Validate against reasonable step rates
    if (estimatedSteps >= 1 && estimatedSteps <= 3) {
      return estimatedSteps;
    }
    
    return 0;
  }

  /// Record detected steps
  void _recordSteps(int steps) {
    if (steps <= 0) return;
    
    _detectedSteps += steps;
    _totalSteps += steps;
    _consecutiveSteps += steps;
    _lastStepTime = DateTime.now();

    debugPrint('CWT steps recorded: $steps, Total: $_totalSteps, Freq: ${_currentStepFreq.toStringAsFixed(2)}Hz');

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
          'Walking detected - CWT frequency: ${_currentStepFreq.toStringAsFixed(2)}Hz');
      }
    } else if (_consecutiveSteps > 0) {
      if (_currentWalkingState != WalkingState.inconsistent) {
        _updateWalkingState(WalkingState.inconsistent, 
          'Movement detected - analyzing frequency patterns');
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
          _currentStepFreq = 0.0;
          _updateWalkingState(WalkingState.idle, 'No walking detected - CWT analysis paused');
        }
      }
    }
  }

  /// Update walking state
  void _updateWalkingState(WalkingState newState, String message) {
    if (_currentWalkingState != newState) {
      _currentWalkingState = newState;
      
      // Calculate confidence based on frequency stability
      double confidence = 0.0;
      if (newState == WalkingState.walking) {
        confidence = min(1.0, _consecutiveSteps / 10.0);
        if (_freqHistory.length >= 3) {
          // Add frequency stability to confidence
          final recentFreqs = _freqHistory.sublist(max(0, _freqHistory.length - 3));
          final mean = recentFreqs.reduce((a, b) => a + b) / recentFreqs.length;
          final variance = recentFreqs.map((f) => pow(f - mean, 2)).reduce((a, b) => a + b) / recentFreqs.length;
          final stability = max(0.0, 1.0 - variance);
          confidence = (confidence + stability) / 2.0;
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
    _currentStepFreq = 0.0;
    
    // Clear buffers
    _signalBuffer.clear();
    _filteredBuffer.clear();
    _freqHistory.clear();
    
    // Reset filter state
    for (int i = 0; i < _filterState.length; i++) {
      _filterState[i] = 0.0;
    }
    
    _stepsController.add(_totalSteps);
    _updateWalkingState(WalkingState.idle, 'CWT step detection reset');
    debugPrint('CWT step detection reset - all counters and buffers cleared');
  }

  /// Error handler
  void _onError(dynamic error) {
    debugPrint('CWT step detection error: $error');
    _updateWalkingState(WalkingState.idle, 'Error in CWT step detection: $error');
  }

  /// Dispose resources
  void dispose() {
    _accelerometerSubscription?.cancel();
    _stepsController.close();
    _walkingStateController.close();
    _accelerometerController.close();
  }
}

/// Simple Complex number class for FFT calculations
class Complex {
  final double real;
  final double imaginary;
  
  Complex(this.real, this.imaginary);
  
  Complex operator +(Complex other) => Complex(real + other.real, imaginary + other.imaginary);
  Complex multiply(double scalar) => Complex(real * scalar, imaginary * scalar);
  Complex multiplyComplex(Complex other) => Complex(
    real * other.real - imaginary * other.imaginary,
    real * other.imaginary + imaginary * other.real
  );
  
  double abs() => sqrt(real * real + imaginary * imaginary);
}
