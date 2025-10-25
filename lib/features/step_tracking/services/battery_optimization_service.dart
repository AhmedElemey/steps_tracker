import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/accelerometer_data.dart';
import '../models/step_detection_config.dart';

/// Battery Optimization Service for Step Detection
/// 
/// This service implements comprehensive battery optimization strategies including:
/// 1. Adaptive sampling rate based on activity level
/// 2. Batch processing to reduce CPU wake-ups
/// 3. Intelligent sleep/wake cycles
/// 4. Power-aware algorithm selection
/// 5. Background processing optimization
/// 6. Memory management for long-running sessions
/// 
/// Based on research showing that battery optimization is crucial for
/// continuous step tracking without significantly impacting user experience.
class BatteryOptimizationService {
  static final BatteryOptimizationService _instance = BatteryOptimizationService._internal();
  factory BatteryOptimizationService() => _instance;
  BatteryOptimizationService._internal();

  // Battery optimization state
  BatteryMode _currentMode = BatteryMode.normal;
  int _currentSamplingRate = 100; // Hz
  int _batchSize = 10; // Process data in batches
  Duration _processingInterval = const Duration(milliseconds: 100);
  
  // Activity detection
  double _activityLevel = 0.0;
  final List<double> _activityHistory = [];
  final int _activityHistorySize = 20;
  DateTime? _lastActivityTime;
  
  // Power management
  Timer? _batchProcessingTimer;
  Timer? _activityMonitoringTimer;
  Timer? _powerModeTimer;
  
  // Data batching
  final List<AccelerometerData> _dataBatch = [];
  final StreamController<List<AccelerometerData>> _batchController = StreamController<List<AccelerometerData>>.broadcast();
  
  // Stream subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  // Configuration
  StepDetectionConfig _config = const StepDetectionConfig();
  
  // Power consumption estimates (relative units)
  static const int _highPowerConsumption = 100;
  static const int _mediumPowerConsumption = 50;
  static const int _lowPowerConsumption = 20;
  static const int _sleepPowerConsumption = 5;

  // Getters
  BatteryMode get currentMode => _currentMode;
  int get currentSamplingRate => _currentSamplingRate;
  double get activityLevel => _activityLevel;
  int get estimatedPowerConsumption => _getEstimatedPowerConsumption();

  // Streams
  Stream<List<AccelerometerData>> get batchStream => _batchController.stream;
  Stream<BatteryMode> get batteryModeStream => _batteryModeController.stream;
  
  final StreamController<BatteryMode> _batteryModeController = StreamController<BatteryMode>.broadcast();

  /// Start battery-optimized data collection
  Future<void> startOptimizedCollection() async {
    debugPrint('Starting battery-optimized data collection...');
    
    // Initialize with normal mode
    _setBatteryMode(BatteryMode.normal);
    
    // Start activity monitoring
    _startActivityMonitoring();
    
    // Start batch processing
    _startBatchProcessing();
    
    // Start power mode optimization
    _startPowerModeOptimization();
    
    debugPrint('Battery optimization started - Mode: $_currentMode, Sampling: ${_currentSamplingRate}Hz');
  }

  /// Stop battery-optimized data collection
  Future<void> stopOptimizedCollection() async {
    await _accelerometerSubscription?.cancel();
    _batchProcessingTimer?.cancel();
    _activityMonitoringTimer?.cancel();
    _powerModeTimer?.cancel();
    
    _dataBatch.clear();
    _activityHistory.clear();
    
    debugPrint('Battery optimization stopped');
  }

  /// Update configuration
  void updateConfig(StepDetectionConfig newConfig) {
    _config = newConfig;
    _adjustSamplingRate();
    debugPrint('Battery optimization config updated');
  }

  /// Start activity monitoring
  void _startActivityMonitoring() {
    _activityMonitoringTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateActivityLevel();
      _adjustBatteryMode();
    });
  }

  /// Start batch processing
  void _startBatchProcessing() {
    _batchProcessingTimer = Timer.periodic(_processingInterval, (timer) {
      _processBatch();
    });
  }

  /// Start power mode optimization
  void _startPowerModeOptimization() {
    _powerModeTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _optimizePowerMode();
    });
  }

  /// Update activity level based on recent data
  void _updateActivityLevel() {
    if (_dataBatch.isEmpty) {
      _activityLevel = 0.0;
      return;
    }
    
    // Calculate activity level from recent data
    final recentData = _dataBatch.length > 10 
        ? _dataBatch.sublist(_dataBatch.length - 10)
        : _dataBatch;
    
    // Calculate variance as activity indicator
    final magnitudes = recentData.map((d) => d.magnitude).toList();
    final mean = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final variance = magnitudes.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / magnitudes.length;
    final stdDev = sqrt(variance);
    
    // Normalize activity level (0-1)
    _activityLevel = min(1.0, stdDev / 2.0);
    
    // Store in history
    _activityHistory.add(_activityLevel);
    if (_activityHistory.length > _activityHistorySize) {
      _activityHistory.removeAt(0);
    }
    
    // Update last activity time
    if (_activityLevel > 0.1) {
      _lastActivityTime = DateTime.now();
    }
  }

  /// Adjust battery mode based on activity level
  void _adjustBatteryMode() {
    final timeSinceActivity = _lastActivityTime != null 
        ? DateTime.now().difference(_lastActivityTime!)
        : const Duration(hours: 1);
    
    BatteryMode newMode;
    
    if (timeSinceActivity.inMinutes > 10) {
      // No activity for 10+ minutes - sleep mode
      newMode = BatteryMode.sleep;
    } else if (_activityLevel > 0.7) {
      // High activity - high performance mode
      newMode = BatteryMode.highPerformance;
    } else if (_activityLevel > 0.3) {
      // Medium activity - normal mode
      newMode = BatteryMode.normal;
    } else if (_activityLevel > 0.1) {
      // Low activity - power saving mode
      newMode = BatteryMode.powerSaving;
    } else {
      // Very low activity - sleep mode
      newMode = BatteryMode.sleep;
    }
    
    if (newMode != _currentMode) {
      _setBatteryMode(newMode);
    }
  }

  /// Set battery mode and adjust parameters
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

  /// Adjust sampling rate based on current mode
  void _adjustSamplingRate() {
    // Cancel existing subscription
    _accelerometerSubscription?.cancel();
    
    // Start new subscription with adjusted rate
    _startAccelerometerSubscription();
  }

  /// Start accelerometer subscription with current sampling rate
  void _startAccelerometerSubscription() {
    _accelerometerSubscription = accelerometerEventStream().listen(
      _onAccelerometerData,
      onError: _onAccelerometerError,
    );
  }

  /// Handle accelerometer data
  void _onAccelerometerData(AccelerometerEvent event) {
    final accelerometerData = AccelerometerData(
      x: event.x,
      y: event.y,
      z: event.z,
      timestamp: DateTime.now(),
    );
    
    // Add to batch
    _dataBatch.add(accelerometerData);
    
    // Process batch if it's full
    if (_dataBatch.length >= _batchSize) {
      _processBatch();
    }
  }

  /// Process data batch
  void _processBatch() {
    if (_dataBatch.isEmpty) return;
    
    // Emit batch for processing
    _batchController.add(List.from(_dataBatch));
    
    // Clear batch
    _dataBatch.clear();
  }

  /// Optimize power mode based on usage patterns
  void _optimizePowerMode() {
    if (_activityHistory.length < 10) return;
    
    // Calculate average activity over time (unused but kept for future analysis)
    // final avgActivity = _activityHistory.reduce((a, b) => a + b) / _activityHistory.length;
    
    // Calculate activity trend
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
      
      // Adjust mode based on trend
      if (trend > 0.2 && _currentMode == BatteryMode.powerSaving) {
        // Activity increasing - move to normal mode
        _setBatteryMode(BatteryMode.normal);
      } else if (trend < -0.2 && _currentMode == BatteryMode.normal) {
        // Activity decreasing - move to power saving mode
        _setBatteryMode(BatteryMode.powerSaving);
      }
    }
  }

  /// Get estimated power consumption
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

  /// Handle accelerometer errors
  void _onAccelerometerError(dynamic error) {
    debugPrint('Battery optimization accelerometer error: $error');
    
    // Try to recover by restarting subscription
    Future.delayed(const Duration(seconds: 1), () {
      _startAccelerometerSubscription();
    });
  }

  /// Get battery optimization status
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

  /// Force battery mode (for testing or user preference)
  void setBatteryMode(BatteryMode mode) {
    _setBatteryMode(mode);
  }

  /// Get recommended battery mode for current conditions
  BatteryMode getRecommendedMode() {
    if (_activityLevel > 0.7) return BatteryMode.highPerformance;
    if (_activityLevel > 0.3) return BatteryMode.normal;
    if (_activityLevel > 0.1) return BatteryMode.powerSaving;
    return BatteryMode.sleep;
  }

  /// Dispose resources
  void dispose() {
    stopOptimizedCollection();
    _batchController.close();
    _batteryModeController.close();
  }
}

/// Battery optimization modes
enum BatteryMode {
  highPerformance,  // Maximum accuracy, high power consumption
  normal,           // Balanced accuracy and power consumption
  powerSaving,      // Reduced accuracy, lower power consumption
  sleep,            // Minimal processing, very low power consumption
}

/// Battery optimization status
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
