import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/accelerometer_data.dart';

class SignalPreprocessingService {
  static final SignalPreprocessingService _instance = SignalPreprocessingService._internal();
  factory SignalPreprocessingService() => _instance;
  SignalPreprocessingService._internal();

  
  final List<double> _lowPassCoeffs = [0.0201, 0.0402, 0.0201, -1.5610, 0.6414];
  final List<double> _highPassCoeffs = [0.9604, -1.9208, 0.9604, -1.9208, 0.9604];
  final List<double> _bandPassCoeffs = [0.0201, 0.0, -0.0201, -1.5610, 0.6414];
  
  final List<double> _lowPassState = [0.0, 0.0, 0.0, 0.0, 0.0];
  final List<double> _highPassState = [0.0, 0.0, 0.0, 0.0, 0.0];
  final List<double> _bandPassState = [0.0, 0.0, 0.0, 0.0, 0.0];
  
  final List<double> _xBuffer = [];
  final List<double> _yBuffer = [];
  final List<double> _zBuffer = [];
  final List<double> _magnitudeBuffer = [];
  final int _bufferSize = 200; // 2 seconds at 100Hz
  
  double _baselineX = 0.0;
  double _baselineY = 0.0;
  double _baselineZ = 0.0;
  double _baselineMagnitude = 9.81; // Standard gravity
  final List<double> _baselineHistory = [];
  final int _baselineHistorySize = 100;
  
  double _signalNoiseRatio = 0.0;
  double _signalVariance = 0.0;
  double _signalMean = 0.0;

  ProcessedAccelerometerData processSignal(AccelerometerData rawData) {
    _addToBuffers(rawData);
    
    final filteredX = _applyFilterChain(_xBuffer, _lowPassCoeffs, _lowPassState);
    final filteredY = _applyFilterChain(_yBuffer, _lowPassCoeffs, _lowPassState);
    final filteredZ = _applyFilterChain(_zBuffer, _lowPassCoeffs, _lowPassState);
    
    final baselineRemovedX = _removeBaseline(filteredX, _baselineX);
    final baselineRemovedY = _removeBaseline(filteredY, _baselineY);
    final baselineRemovedZ = _removeBaseline(filteredZ, _baselineZ);
    
    final processedMagnitude = _calculateMagnitude(
      baselineRemovedX.last,
      baselineRemovedY.last,
      baselineRemovedZ.last,
    );
    
    _updateBaselineTracking(rawData);
    
    _updateSignalQualityMetrics(processedMagnitude);
    
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

  void _addToBuffers(AccelerometerData data) {
    _xBuffer.add(data.x);
    _yBuffer.add(data.y);
    _zBuffer.add(data.z);
    _magnitudeBuffer.add(data.magnitude);
    
    if (_xBuffer.length > _bufferSize) {
      _xBuffer.removeAt(0);
      _yBuffer.removeAt(0);
      _zBuffer.removeAt(0);
      _magnitudeBuffer.removeAt(0);
    }
  }

  List<double> _applyFilterChain(List<double> signal, List<double> coeffs, List<double> state) {
    final filtered = <double>[];
    
    for (int i = 0; i < signal.length; i++) {
      double output = coeffs[0] * signal[i];
      
      for (int j = 1; j < coeffs.length - 2; j++) {
        if (i >= j) {
          output += coeffs[j] * signal[i - j];
        }
      }
      
      for (int j = 0; j < state.length; j++) {
        if (i >= j + 1) {
          output -= coeffs[j + 3] * state[j];
        }
      }
      
      for (int j = state.length - 1; j > 0; j--) {
        state[j] = state[j - 1];
      }
      state[0] = output;
      
      filtered.add(output);
    }
    
    return filtered;
  }

  List<double> _removeBaseline(List<double> signal, double baseline) {
    return signal.map((value) => value - baseline).toList();
  }

  double _calculateMagnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }

  void _updateBaselineTracking(AccelerometerData data) {
    const double alpha = 0.01; // Smoothing factor
    
    _baselineX = _baselineX * (1 - alpha) + data.x * alpha;
    _baselineY = _baselineY * (1 - alpha) + data.y * alpha;
    _baselineZ = _baselineZ * (1 - alpha) + data.z * alpha;
    _baselineMagnitude = _baselineMagnitude * (1 - alpha) + data.magnitude * alpha;
    
    _baselineHistory.add(_baselineMagnitude);
    if (_baselineHistory.length > _baselineHistorySize) {
      _baselineHistory.removeAt(0);
    }
  }

  void _updateSignalQualityMetrics(double magnitude) {
    if (_magnitudeBuffer.length < 10) return;
    
    final recentSignal = _magnitudeBuffer.length > 20 
        ? _magnitudeBuffer.sublist(_magnitudeBuffer.length - 20)
        : _magnitudeBuffer;
    
    _signalMean = recentSignal.reduce((a, b) => a + b) / recentSignal.length;
    _signalVariance = recentSignal.map((x) => pow(x - _signalMean, 2)).reduce((a, b) => a + b) / recentSignal.length;
    
    final signalPower = _signalMean * _signalMean;
    final noisePower = _signalVariance;
    _signalNoiseRatio = signalPower > 0 ? signalPower / (noisePower + 1e-6) : 0.0;
  }

  double _applySmoothing(double magnitude) {
    if (_magnitudeBuffer.length < 3) return magnitude;
    
    final recentValues = _magnitudeBuffer.length > 5 
        ? _magnitudeBuffer.sublist(_magnitudeBuffer.length - 5)
        : _magnitudeBuffer;
    
    return recentValues.reduce((a, b) => a + b) / recentValues.length;
  }

  double _calculateSignalQuality() {
    double quality = 0.0;
    
    final snrFactor = min(1.0, _signalNoiseRatio / 10.0);
    quality += snrFactor * 0.4;
    
    final stabilityFactor = _baselineHistory.length > 10 
        ? _calculateBaselineStability() 
        : 0.5;
    quality += stabilityFactor * 0.3;
    
    final varianceFactor = _signalVariance > 0.1 && _signalVariance < 2.0 ? 1.0 : 0.5;
    quality += varianceFactor * 0.3;
    
    return quality.clamp(0.0, 1.0);
  }

  double _calculateBaselineStability() {
    if (_baselineHistory.length < 10) return 0.5;
    
    final mean = _baselineHistory.reduce((a, b) => a + b) / _baselineHistory.length;
    final variance = _baselineHistory.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / _baselineHistory.length;
    final stdDev = sqrt(variance);
    
    return max(0.0, 1.0 - stdDev / mean);
  }

  double _estimateNoiseLevel() {
    if (_magnitudeBuffer.length < 10) return 0.0;
    
    final recentSignal = _magnitudeBuffer.sublist(max(0, _magnitudeBuffer.length - 10));
    final mean = recentSignal.reduce((a, b) => a + b) / recentSignal.length;
    final variance = recentSignal.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / recentSignal.length;
    
    return sqrt(variance);
  }

  List<double> applyBandPassFilter(List<double> signal) {
    return _applyFilterChain(signal, _bandPassCoeffs, _bandPassState);
  }

  List<double> applyHighPassFilter(List<double> signal) {
    return _applyFilterChain(signal, _highPassCoeffs, _highPassState);
  }

  BaselineData getCurrentBaseline() {
    return BaselineData(
      x: _baselineX,
      y: _baselineY,
      z: _baselineZ,
      magnitude: _baselineMagnitude,
      stability: _calculateBaselineStability(),
    );
  }

  SignalQualityMetrics getSignalQualityMetrics() {
    return SignalQualityMetrics(
      signalToNoiseRatio: _signalNoiseRatio,
      variance: _signalVariance,
      mean: _signalMean,
      overallQuality: _calculateSignalQuality(),
      noiseLevel: _estimateNoiseLevel(),
    );
  }

  void reset() {
    _xBuffer.clear();
    _yBuffer.clear();
    _zBuffer.clear();
    _magnitudeBuffer.clear();
    _baselineHistory.clear();
    
    for (int i = 0; i < _lowPassState.length; i++) {
      _lowPassState[i] = 0.0;
      _highPassState[i] = 0.0;
      _bandPassState[i] = 0.0;
    }
    
    _baselineX = 0.0;
    _baselineY = 0.0;
    _baselineZ = 0.0;
    _baselineMagnitude = 9.81;
    
    _signalNoiseRatio = 0.0;
    _signalVariance = 0.0;
    _signalMean = 0.0;
    
    debugPrint('Signal preprocessing service reset');
  }

  void calibrateBaseline(List<AccelerometerData> calibrationData) {
    if (calibrationData.isEmpty) return;
    
    final meanX = calibrationData.map((d) => d.x).reduce((a, b) => a + b) / calibrationData.length;
    final meanY = calibrationData.map((d) => d.y).reduce((a, b) => a + b) / calibrationData.length;
    final meanZ = calibrationData.map((d) => d.z).reduce((a, b) => a + b) / calibrationData.length;
    final meanMagnitude = calibrationData.map((d) => d.magnitude).reduce((a, b) => a + b) / calibrationData.length;
    
    _baselineX = meanX;
    _baselineY = meanY;
    _baselineZ = meanZ;
    _baselineMagnitude = meanMagnitude;
    
    debugPrint('Baseline calibrated: X=$meanX, Y=$meanY, Z=$meanZ, Magnitude=$meanMagnitude');
  }
}

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
