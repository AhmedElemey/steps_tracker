import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/accelerometer_data.dart';
import '../models/step_detection_config.dart';

class BatteryOptimizationService {
  static final BatteryOptimizationService _instance = BatteryOptimizationService._internal();
  factory BatteryOptimizationService() => _instance;
  BatteryOptimizationService._internal();

  BatteryMode _currentMode = BatteryMode.normal;
  int _currentSamplingRate = 100; // Hz
  int _batchSize = 10; // Process data in batches
  Duration _processingInterval = const Duration(milliseconds: 100);
  
  double _activityLevel = 0.0;
  final List<double> _activityHistory = [];
  final int _activityHistorySize = 20;
  DateTime? _lastActivityTime;
  
  Timer? _batchProcessingTimer;
  Timer? _activityMonitoringTimer;
  Timer? _powerModeTimer;
  
  final List<AccelerometerData> _dataBatch = [];
  final StreamController<List<AccelerometerData>> _batchController = StreamController<List<AccelerometerData>>.broadcast();
  
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  StepDetectionConfig _config = const StepDetectionConfig();
  
  static const int _highPowerConsumption = 100;
  static const int _mediumPowerConsumption = 50;
  static const int _lowPowerConsumption = 20;
  static const int _sleepPowerConsumption = 5;

  BatteryMode get currentMode => _currentMode;
  int get currentSamplingRate => _currentSamplingRate;
  double get activityLevel => _activityLevel;
  int get estimatedPowerConsumption => _getEstimatedPowerConsumption();

  Stream<List<AccelerometerData>> get batchStream => _batchController.stream;
  Stream<BatteryMode> get batteryModeStream => _batteryModeController.stream;
  
  final StreamController<BatteryMode> _batteryModeController = StreamController<BatteryMode>.broadcast();

  Future<void> startOptimizedCollection() async {
    debugPrint('Starting battery-optimized data collection...');
    
    _setBatteryMode(BatteryMode.normal);
    
    _startActivityMonitoring();
    
    _startBatchProcessing();
    
    _startPowerModeOptimization();
    
    debugPrint('Battery optimization started - Mode: $_currentMode, Sampling: ${_currentSamplingRate}Hz');
  }

  Future<void> stopOptimizedCollection() async {
    await _accelerometerSubscription?.cancel();
    _batchProcessingTimer?.cancel();
    _activityMonitoringTimer?.cancel();
    _powerModeTimer?.cancel();
    
    _dataBatch.clear();
    _activityHistory.clear();
    
    debugPrint('Battery optimization stopped');
  }

  void updateConfig(StepDetectionConfig newConfig) {
    _config = newConfig;
    _adjustSamplingRate();
    debugPrint('Battery optimization config updated');
  }

  void _startActivityMonitoring() {
    _activityMonitoringTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateActivityLevel();
      _adjustBatteryMode();
    });
  }

  void _startBatchProcessing() {
    _batchProcessingTimer = Timer.periodic(_processingInterval, (timer) {
      _processBatch();
    });
  }

  void _startPowerModeOptimization() {
    _powerModeTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _optimizePowerMode();
    });
  }

  void _updateActivityLevel() {
    if (_dataBatch.isEmpty) {
      _activityLevel = 0.0;
      return;
    }
    
    final recentData = _dataBatch.length > 10 
        ? _dataBatch.sublist(_dataBatch.length - 10)
        : _dataBatch;
    
    final magnitudes = recentData.map((d) => d.magnitude).toList();
    final mean = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final variance = magnitudes.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / magnitudes.length;
    final stdDev = sqrt(variance);
    
    _activityLevel = min(1.0, stdDev / 2.0);
    
    _activityHistory.add(_activityLevel);
    if (_activityHistory.length > _activityHistorySize) {
      _activityHistory.removeAt(0);
    }
    
    if (_activityLevel > 0.1) {
      _lastActivityTime = DateTime.now();
    }
  }

  void _adjustBatteryMode() {
    final timeSinceActivity = _lastActivityTime != null 
        ? DateTime.now().difference(_lastActivityTime!)
        : const Duration(hours: 1);
    
    BatteryMode newMode;
    
    if (timeSinceActivity.inMinutes > 10) {
      newMode = BatteryMode.sleep;
    } else if (_activityLevel > 0.7) {
      newMode = BatteryMode.highPerformance;
    } else if (_activityLevel > 0.3) {
      newMode = BatteryMode.normal;
    } else if (_activityLevel > 0.1) {
      newMode = BatteryMode.powerSaving;
    } else {
      newMode = BatteryMode.sleep;
    }
    
    if (newMode != _currentMode) {
      _setBatteryMode(newMode);
    }
  }

  void _setBatteryMode(BatteryMode mode) {
    _currentMode = mode;
    
    switch (mode) {
      case BatteryMode.highPerformance:
        _currentSamplingRate = 100; // Hz
        _batchSize = 5;
        _processingInterval = const Duration(milliseconds: 50);
        break;
        
      case BatteryMode.normal:
        _currentSamplingRate = 50; // Hz
        _batchSize = 10;
        _processingInterval = const Duration(milliseconds: 100);
        break;
        
      case BatteryMode.powerSaving:
        _currentSamplingRate = 25; // Hz
        _batchSize = 20;
        _processingInterval = const Duration(milliseconds: 200);
        break;
        
      case BatteryMode.sleep:
        _currentSamplingRate = 10; // Hz
        _batchSize = 50;
        _processingInterval = const Duration(milliseconds: 500);
        break;
    }
    
    _adjustSamplingRate();
    _batteryModeController.add(mode);
    
    debugPrint('Battery mode changed to: $mode (Sampling: ${_currentSamplingRate}Hz, Batch: $_batchSize)');
  }

  void _adjustSamplingRate() {
    _accelerometerSubscription?.cancel();
    
    _startAccelerometerSubscription();
  }

  void _startAccelerometerSubscription() {
    _accelerometerSubscription = accelerometerEventStream().listen(
      _onAccelerometerData,
      onError: _onAccelerometerError,
    );
  }

  void _onAccelerometerData(AccelerometerEvent event) {
    final accelerometerData = AccelerometerData(
      x: event.x,
      y: event.y,
      z: event.z,
      timestamp: DateTime.now(),
    );
    
    _dataBatch.add(accelerometerData);
    
    if (_dataBatch.length >= _batchSize) {
      _processBatch();
    }
  }

  void _processBatch() {
    if (_dataBatch.isEmpty) return;
    
    _batchController.add(List.from(_dataBatch));
    
    _dataBatch.clear();
  }

  void _optimizePowerMode() {
    if (_activityHistory.length < 10) return;
    
    
    final recentActivity = _activityHistory.length > 5 
        ? _activityHistory.sublist(_activityHistory.length - 5)
        : _activityHistory;
    final olderActivity = _activityHistory.length > 10 
        ? _activityHistory.sublist(0, _activityHistory.length - 5)
        : <double>[];
    
    if (olderActivity.isNotEmpty) {
      final recentAvg = recentActivity.reduce((a, b) => a + b) / recentActivity.length;
      final olderAvg = olderActivity.reduce((a, b) => a + b) / olderActivity.length;
      final trend = recentAvg - olderAvg;
      
      if (trend > 0.2 && _currentMode == BatteryMode.powerSaving) {
        _setBatteryMode(BatteryMode.normal);
      } else if (trend < -0.2 && _currentMode == BatteryMode.normal) {
        _setBatteryMode(BatteryMode.powerSaving);
      }
    }
  }

  int _getEstimatedPowerConsumption() {
    switch (_currentMode) {
      case BatteryMode.highPerformance:
        return _highPowerConsumption;
      case BatteryMode.normal:
        return _mediumPowerConsumption;
      case BatteryMode.powerSaving:
        return _lowPowerConsumption;
      case BatteryMode.sleep:
        return _sleepPowerConsumption;
    }
  }

  void _onAccelerometerError(dynamic error) {
    debugPrint('Battery optimization accelerometer error: $error');
    
    Future.delayed(const Duration(seconds: 1), () {
      _startAccelerometerSubscription();
    });
  }

  BatteryOptimizationStatus getStatus() {
    return BatteryOptimizationStatus(
      mode: _currentMode,
      samplingRate: _currentSamplingRate,
      activityLevel: _activityLevel,
      powerConsumption: _getEstimatedPowerConsumption(),
      batchSize: _batchSize,
      processingInterval: _processingInterval,
      timeSinceLastActivity: _lastActivityTime != null 
          ? DateTime.now().difference(_lastActivityTime!)
          : const Duration(hours: 1),
    );
  }

  void setBatteryMode(BatteryMode mode) {
    _setBatteryMode(mode);
  }

  BatteryMode getRecommendedMode() {
    if (_activityLevel > 0.7) return BatteryMode.highPerformance;
    if (_activityLevel > 0.3) return BatteryMode.normal;
    if (_activityLevel > 0.1) return BatteryMode.powerSaving;
    return BatteryMode.sleep;
  }

  void dispose() {
    stopOptimizedCollection();
    _batchController.close();
    _batteryModeController.close();
  }
}

enum BatteryMode {
  highPerformance,  // Maximum accuracy, high power consumption
  normal,           // Balanced accuracy and power consumption
  powerSaving,      // Reduced accuracy, lower power consumption
  sleep,            // Minimal processing, very low power consumption
}

class BatteryOptimizationStatus {
  final BatteryMode mode;
  final int samplingRate;
  final double activityLevel;
  final int powerConsumption;
  final int batchSize;
  final Duration processingInterval;
  final Duration timeSinceLastActivity;

  const BatteryOptimizationStatus({
    required this.mode,
    required this.samplingRate,
    required this.activityLevel,
    required this.powerConsumption,
    required this.batchSize,
    required this.processingInterval,
    required this.timeSinceLastActivity,
  });

  @override
  String toString() {
    return 'BatteryOptimizationStatus(mode: $mode, sampling: ${samplingRate}Hz, activity: ${activityLevel.toStringAsFixed(2)}, power: $powerConsumption)';
  }
}
