import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/accelerometer_data.dart';

/// Signal Preprocessing Service for Step Detection
/// 
/// This service implements a comprehensive signal preprocessing pipeline that includes:
/// 1. Low-pass filtering to remove gravity and high-frequency noise
/// 2. High-pass filtering to remove DC components
/// 3. Band-pass filtering for step frequency range (1.4-2.3 Hz)
/// 4. Signal smoothing and noise reduction
/// 5. Baseline removal and normalization
/// 6. Multi-axis signal fusion
/// 
/// Based on research showing that proper signal preprocessing is crucial for
/// accurate step detection across different devices and usage scenarios.
class SignalPreprocessingService {
  static final SignalPreprocessingService _instance = SignalPreprocessingService._internal();
  factory SignalPreprocessingService() => _instance;
  SignalPreprocessingService._internal();

  // Filter configurations (unused but kept for documentation)
  // static const double _samplingRate = 100.0; // Hz
  // static const double _lowPassCutoff = 5.0; // Hz - remove high-frequency noise
  // static const double _highPassCutoff = 0.5; // Hz - remove DC components
  // static const double _bandPassLow = 1.0; // Hz - step frequency range
  // static const double _bandPassHigh = 3.0; // Hz - step frequency range
  
  // Filter coefficients (Butterworth filters)
  final List<double> _lowPassCoeffs = [0.0201, 0.0402, 0.0201, -1.5610, 0.6414];
  final List<double> _highPassCoeffs = [0.9604, -1.9208, 0.9604, -1.9208, 0.9604];
  final List<double> _bandPassCoeffs = [0.0201, 0.0, -0.0201, -1.5610, 0.6414];
  
  // Filter states
  final List<double> _lowPassState = [0.0, 0.0, 0.0, 0.0, 0.0];
  final List<double> _highPassState = [0.0, 0.0, 0.0, 0.0, 0.0];
  final List<double> _bandPassState = [0.0, 0.0, 0.0, 0.0, 0.0];
  
  // Signal buffers
  final List<double> _xBuffer = [];
  final List<double> _yBuffer = [];
  final List<double> _zBuffer = [];
  final List<double> _magnitudeBuffer = [];
  final int _bufferSize = 200; // 2 seconds at 100Hz
  
  // Baseline tracking
  double _baselineX = 0.0;
  double _baselineY = 0.0;
  double _baselineZ = 0.0;
  double _baselineMagnitude = 9.81; // Standard gravity
  final List<double> _baselineHistory = [];
  final int _baselineHistorySize = 100;
  
  // Signal quality metrics
  double _signalNoiseRatio = 0.0;
  double _signalVariance = 0.0;
  double _signalMean = 0.0;

  /// Process raw accelerometer data through the preprocessing pipeline
  ProcessedAccelerometerData processSignal(AccelerometerData rawData) {
    // Add to buffers
    _addToBuffers(rawData);
    
    // Apply preprocessing pipeline
    final filteredX = _applyFilterChain(_xBuffer, _lowPassCoeffs, _lowPassState);
    final filteredY = _applyFilterChain(_yBuffer, _lowPassCoeffs, _lowPassState);
    final filteredZ = _applyFilterChain(_zBuffer, _lowPassCoeffs, _lowPassState);
    
    // Remove baseline (gravity component)
    final baselineRemovedX = _removeBaseline(filteredX, _baselineX);
    final baselineRemovedY = _removeBaseline(filteredY, _baselineY);
    final baselineRemovedZ = _removeBaseline(filteredZ, _baselineZ);
    
    // Calculate processed magnitude
    final processedMagnitude = _calculateMagnitude(
      baselineRemovedX.last,
      baselineRemovedY.last,
      baselineRemovedZ.last,
    );
    
    // Update baseline tracking
    _updateBaselineTracking(rawData);
    
    // Calculate signal quality metrics
    _updateSignalQualityMetrics(processedMagnitude);
    
    // Apply additional smoothing if needed
    final smoothedMagnitude = _applySmoothing(processedMagnitude);
    
    return ProcessedAccelerometerData(
      x: baselineRemovedX.last,
      y: baselineRemovedY.last,
      z: baselineRemovedZ.last,
      magnitude: smoothedMagnitude,
      originalMagnitude: rawData.magnitude,
      timestamp: rawData.timestamp,
      signalQuality: _calculateSignalQuality(),
      noiseLevel: _estimateNoiseLevel(),
    );
  }

  /// Add data to processing buffers
  void _addToBuffers(AccelerometerData data) {
    _xBuffer.add(data.x);
    _yBuffer.add(data.y);
    _zBuffer.add(data.z);
    _magnitudeBuffer.add(data.magnitude);
    
    // Keep buffer sizes manageable
    if (_xBuffer.length > _bufferSize) {
      _xBuffer.removeAt(0);
      _yBuffer.removeAt(0);
      _zBuffer.removeAt(0);
      _magnitudeBuffer.removeAt(0);
    }
  }

  /// Apply filter chain to signal
  List<double> _applyFilterChain(List<double> signal, List<double> coeffs, List<double> state) {
    final filtered = <double>[];
    
    for (int i = 0; i < signal.length; i++) {
      // Apply filter
      double output = coeffs[0] * signal[i];
      
      // Feedforward terms
      for (int j = 1; j < coeffs.length - 2; j++) {
        if (i >= j) {
          output += coeffs[j] * signal[i - j];
        }
      }
      
      // Feedback terms
      for (int j = 0; j < state.length; j++) {
        if (i >= j + 1) {
          output -= coeffs[j + 3] * state[j];
        }
      }
      
      // Update filter state
      for (int j = state.length - 1; j > 0; j--) {
        state[j] = state[j - 1];
      }
      state[0] = output;
      
      filtered.add(output);
    }
    
    return filtered;
  }

  /// Remove baseline (DC component) from signal
  List<double> _removeBaseline(List<double> signal, double baseline) {
    return signal.map((value) => value - baseline).toList();
  }

  /// Calculate magnitude from x, y, z components
  double _calculateMagnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }

  /// Update baseline tracking for gravity compensation
  void _updateBaselineTracking(AccelerometerData data) {
    // Use moving average for baseline estimation
    const double alpha = 0.01; // Smoothing factor
    
    _baselineX = _baselineX * (1 - alpha) + data.x * alpha;
    _baselineY = _baselineY * (1 - alpha) + data.y * alpha;
    _baselineZ = _baselineZ * (1 - alpha) + data.z * alpha;
    _baselineMagnitude = _baselineMagnitude * (1 - alpha) + data.magnitude * alpha;
    
    // Store baseline history for analysis
    _baselineHistory.add(_baselineMagnitude);
    if (_baselineHistory.length > _baselineHistorySize) {
      _baselineHistory.removeAt(0);
    }
  }

  /// Update signal quality metrics
  void _updateSignalQualityMetrics(double magnitude) {
    if (_magnitudeBuffer.length < 10) return;
    
    // Calculate signal statistics
    final recentSignal = _magnitudeBuffer.length > 20 
        ? _magnitudeBuffer.sublist(_magnitudeBuffer.length - 20)
        : _magnitudeBuffer;
    
    _signalMean = recentSignal.reduce((a, b) => a + b) / recentSignal.length;
    _signalVariance = recentSignal.map((x) => pow(x - _signalMean, 2)).reduce((a, b) => a + b) / recentSignal.length;
    
    // Estimate signal-to-noise ratio
    final signalPower = _signalMean * _signalMean;
    final noisePower = _signalVariance;
    _signalNoiseRatio = signalPower > 0 ? signalPower / (noisePower + 1e-6) : 0.0;
  }

  /// Apply additional smoothing to reduce jitter
  double _applySmoothing(double magnitude) {
    if (_magnitudeBuffer.length < 3) return magnitude;
    
    // Simple moving average smoothing
    final recentValues = _magnitudeBuffer.length > 5 
        ? _magnitudeBuffer.sublist(_magnitudeBuffer.length - 5)
        : _magnitudeBuffer;
    
    return recentValues.reduce((a, b) => a + b) / recentValues.length;
  }

  /// Calculate overall signal quality
  double _calculateSignalQuality() {
    // Signal quality based on multiple factors
    double quality = 0.0;
    
    // Factor 1: Signal-to-noise ratio (0-1)
    final snrFactor = min(1.0, _signalNoiseRatio / 10.0);
    quality += snrFactor * 0.4;
    
    // Factor 2: Signal stability (0-1)
    final stabilityFactor = _baselineHistory.length > 10 
        ? _calculateBaselineStability() 
        : 0.5;
    quality += stabilityFactor * 0.3;
    
    // Factor 3: Signal variance (0-1) - moderate variance is good
    final varianceFactor = _signalVariance > 0.1 && _signalVariance < 2.0 ? 1.0 : 0.5;
    quality += varianceFactor * 0.3;
    
    return quality.clamp(0.0, 1.0);
  }

  /// Calculate baseline stability
  double _calculateBaselineStability() {
    if (_baselineHistory.length < 10) return 0.5;
    
    final mean = _baselineHistory.reduce((a, b) => a + b) / _baselineHistory.length;
    final variance = _baselineHistory.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / _baselineHistory.length;
    final stdDev = sqrt(variance);
    
    // Stability is inversely related to standard deviation
    return max(0.0, 1.0 - stdDev / mean);
  }

  /// Estimate noise level in the signal
  double _estimateNoiseLevel() {
    if (_magnitudeBuffer.length < 10) return 0.0;
    
    // Use high-frequency components as noise estimate
    final recentSignal = _magnitudeBuffer.sublist(max(0, _magnitudeBuffer.length - 10));
    final mean = recentSignal.reduce((a, b) => a + b) / recentSignal.length;
    final variance = recentSignal.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / recentSignal.length;
    
    return sqrt(variance);
  }

  /// Apply band-pass filter for step frequency range
  List<double> applyBandPassFilter(List<double> signal) {
    return _applyFilterChain(signal, _bandPassCoeffs, _bandPassState);
  }

  /// Apply high-pass filter to remove DC components
  List<double> applyHighPassFilter(List<double> signal) {
    return _applyFilterChain(signal, _highPassCoeffs, _highPassState);
  }

  /// Get current baseline values
  BaselineData getCurrentBaseline() {
    return BaselineData(
      x: _baselineX,
      y: _baselineY,
      z: _baselineZ,
      magnitude: _baselineMagnitude,
      stability: _calculateBaselineStability(),
    );
  }

  /// Get signal quality metrics
  SignalQualityMetrics getSignalQualityMetrics() {
    return SignalQualityMetrics(
      signalToNoiseRatio: _signalNoiseRatio,
      variance: _signalVariance,
      mean: _signalMean,
      overallQuality: _calculateSignalQuality(),
      noiseLevel: _estimateNoiseLevel(),
    );
  }

  /// Reset all filters and buffers
  void reset() {
    // Clear buffers
    _xBuffer.clear();
    _yBuffer.clear();
    _zBuffer.clear();
    _magnitudeBuffer.clear();
    _baselineHistory.clear();
    
    // Reset filter states
    for (int i = 0; i < _lowPassState.length; i++) {
      _lowPassState[i] = 0.0;
      _highPassState[i] = 0.0;
      _bandPassState[i] = 0.0;
    }
    
    // Reset baselines
    _baselineX = 0.0;
    _baselineY = 0.0;
    _baselineZ = 0.0;
    _baselineMagnitude = 9.81;
    
    // Reset quality metrics
    _signalNoiseRatio = 0.0;
    _signalVariance = 0.0;
    _signalMean = 0.0;
    
    debugPrint('Signal preprocessing service reset');
  }

  /// Calibrate baseline for current device orientation
  void calibrateBaseline(List<AccelerometerData> calibrationData) {
    if (calibrationData.isEmpty) return;
    
    // Calculate mean values for calibration
    final meanX = calibrationData.map((d) => d.x).reduce((a, b) => a + b) / calibrationData.length;
    final meanY = calibrationData.map((d) => d.y).reduce((a, b) => a + b) / calibrationData.length;
    final meanZ = calibrationData.map((d) => d.z).reduce((a, b) => a + b) / calibrationData.length;
    final meanMagnitude = calibrationData.map((d) => d.magnitude).reduce((a, b) => a + b) / calibrationData.length;
    
    // Set calibrated baselines
    _baselineX = meanX;
    _baselineY = meanY;
    _baselineZ = meanZ;
    _baselineMagnitude = meanMagnitude;
    
    debugPrint('Baseline calibrated: X=$meanX, Y=$meanY, Z=$meanZ, Magnitude=$meanMagnitude');
  }
}

/// Processed accelerometer data with quality metrics
class ProcessedAccelerometerData {
  final double x;
  final double y;
  final double z;
  final double magnitude;
  final double originalMagnitude;
  final DateTime timestamp;
  final double signalQuality;
  final double noiseLevel;

  const ProcessedAccelerometerData({
    required this.x,
    required this.y,
    required this.z,
    required this.magnitude,
    required this.originalMagnitude,
    required this.timestamp,
    required this.signalQuality,
    required this.noiseLevel,
  });

  @override
  String toString() {
    return 'ProcessedAccelerometerData(magnitude: ${magnitude.toStringAsFixed(3)}, quality: ${signalQuality.toStringAsFixed(2)}, noise: ${noiseLevel.toStringAsFixed(3)})';
  }
}

/// Baseline data for gravity compensation
class BaselineData {
  final double x;
  final double y;
  final double z;
  final double magnitude;
  final double stability;

  const BaselineData({
    required this.x,
    required this.y,
    required this.z,
    required this.magnitude,
    required this.stability,
  });

  @override
  String toString() {
    return 'BaselineData(magnitude: ${magnitude.toStringAsFixed(3)}, stability: ${stability.toStringAsFixed(2)})';
  }
}

/// Signal quality metrics
class SignalQualityMetrics {
  final double signalToNoiseRatio;
  final double variance;
  final double mean;
  final double overallQuality;
  final double noiseLevel;

  const SignalQualityMetrics({
    required this.signalToNoiseRatio,
    required this.variance,
    required this.mean,
    required this.overallQuality,
    required this.noiseLevel,
  });

  @override
  String toString() {
    return 'SignalQualityMetrics(quality: ${overallQuality.toStringAsFixed(2)}, snr: ${signalToNoiseRatio.toStringAsFixed(2)}, noise: ${noiseLevel.toStringAsFixed(3)})';
  }
}
