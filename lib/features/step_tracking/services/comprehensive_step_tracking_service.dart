import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/accelerometer_data.dart';
import '../models/step_detection_config.dart';
import '../models/walking_state.dart';
import 'cwt_step_detection_service.dart';
import 'enhanced_peak_detection_service.dart';
import 'sensor_fusion_service.dart';
import 'signal_preprocessing_service.dart';
import 'battery_optimization_service.dart';

/// Comprehensive Step Tracking Service
/// 
/// This is the main orchestrator service that integrates all step detection
/// algorithms and optimization strategies into a unified, robust system.
/// 
/// Architecture Overview:
/// ┌─────────────────────────────────────────────────────────────┐
/// │                Comprehensive Step Tracking Service           │
/// ├─────────────────────────────────────────────────────────────┤
/// │  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
/// │  │   CWT Service   │  │ Enhanced Peak   │  │ Sensor Fusion│ │
/// │  │                 │  │    Service      │  │   Service    │ │
/// │  └─────────────────┘  └─────────────────┘  └──────────────┘ │
/// │           │                     │                    │       │
/// │  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
/// │  │ Signal Preproc. │  │ Battery Optim.  │  │ Configuration│ │
/// │  │    Service      │  │    Service      │  │   Manager    │ │
/// │  └─────────────────┘  └─────────────────┘  └──────────────┘ │
/// └─────────────────────────────────────────────────────────────┘
/// 
/// Key Features:
/// 1. Multi-algorithm approach with intelligent fallback
/// 2. Comprehensive signal preprocessing pipeline
/// 3. Advanced sensor fusion combining hardware and software
/// 4. Battery optimization with adaptive processing
/// 5. Real-time configuration and calibration
/// 6. Robust error handling and recovery
/// 7. Performance monitoring and analytics
class ComprehensiveStepTrackingService {
  static final ComprehensiveStepTrackingService _instance = ComprehensiveStepTrackingService._internal();
  factory ComprehensiveStepTrackingService() => _instance;
  ComprehensiveStepTrackingService._internal();

  // Core services
  final CWTStepDetectionService _cwtService = CWTStepDetectionService();
  final EnhancedPeakDetectionService _enhancedPeakService = EnhancedPeakDetectionService();
  final SensorFusionService _sensorFusionService = SensorFusionService();
  final SignalPreprocessingService _signalPreprocessingService = SignalPreprocessingService();
  final BatteryOptimizationService _batteryOptimizationService = BatteryOptimizationService();

  // Stream controllers
  final StreamController<int> _finalStepsController = StreamController<int>.broadcast();
  final StreamController<WalkingStateData> _finalWalkingStateController = StreamController<WalkingStateData>.broadcast();
  final StreamController<StepTrackingStatus> _statusController = StreamController<StepTrackingStatus>.broadcast();

  // Stream subscriptions
  StreamSubscription<int>? _fusionStepsSubscription;
  StreamSubscription<WalkingStateData>? _fusionWalkingStateSubscription;
  StreamSubscription<SensorFusionStatus>? _fusionStatusSubscription;
  StreamSubscription<BatteryMode>? _batteryModeSubscription;

  // Configuration and state
  StepDetectionConfig _config = const StepDetectionConfig();
  bool _isInitialized = false;
  bool _isRunning = false;
  DateTime? _startTime;
  
  // Performance monitoring
  final List<PerformanceMetric> _performanceMetrics = [];
  final int _maxPerformanceMetrics = 100;
  
  // Error handling
  int _errorCount = 0;
  final List<ErrorLog> _errorLogs = [];
  final int _maxErrorLogs = 50;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isRunning => _isRunning;
  StepDetectionConfig get config => _config;
  StepTrackingStatus get currentStatus => _getCurrentStatus();

  // Streams
  Stream<int> get stepsStream => _finalStepsController.stream;
  Stream<WalkingStateData> get walkingStateStream => _finalWalkingStateController.stream;
  Stream<StepTrackingStatus> get statusStream => _statusController.stream;

  /// Initialize the comprehensive step tracking service
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('Initializing comprehensive step tracking service...');

    try {
      // Initialize all services
      await _initializeServices();
      
      // Set up service interconnections
      _setupServiceInterconnections();
      
      // Start monitoring
      _startMonitoring();
      
      _isInitialized = true;
      debugPrint('Comprehensive step tracking service initialized successfully');
      
      _emitStatus();
    } catch (e) {
      _handleError('Failed to initialize comprehensive step tracking service', e);
      rethrow;
    }
  }

  /// Start comprehensive step tracking
  Future<void> startTracking() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isRunning) return;

    debugPrint('Starting comprehensive step tracking...');

    try {
      // Start all services
      await _startAllServices();
      
      _isRunning = true;
      _startTime = DateTime.now();
      
      debugPrint('Comprehensive step tracking started successfully');
      _emitStatus();
    } catch (e) {
      _handleError('Failed to start comprehensive step tracking', e);
      rethrow;
    }
  }

  /// Stop comprehensive step tracking
  Future<void> stopTracking() async {
    if (!_isRunning) return;

    debugPrint('Stopping comprehensive step tracking...');

    try {
      // Stop all services
      await _stopAllServices();
      
      _isRunning = false;
      _startTime = null;
      
      debugPrint('Comprehensive step tracking stopped');
      _emitStatus();
    } catch (e) {
      _handleError('Failed to stop comprehensive step tracking', e);
    }
  }

  /// Update configuration
  Future<void> updateConfig(StepDetectionConfig newConfig) async {
    _config = newConfig;
    
    // Update all services with new configuration
    _cwtService.updateConfig(newConfig);
    _enhancedPeakService.updateConfig(newConfig);
    _sensorFusionService.updateConfig(newConfig);
    _batteryOptimizationService.updateConfig(newConfig);
    
    debugPrint('Configuration updated: $newConfig');
    _emitStatus();
  }

  /// Calibrate the system
  Future<void> calibrate() async {
    debugPrint('Starting system calibration...');
    
    try {
      // Collect calibration data
      final calibrationData = await _collectCalibrationData();
      
      // Calibrate signal preprocessing
      _signalPreprocessingService.calibrateBaseline(calibrationData);
      
      // Update configuration based on calibration
      final calibratedConfig = _calculateCalibratedConfig(calibrationData);
      await updateConfig(calibratedConfig);
      
      debugPrint('System calibration completed successfully');
    } catch (e) {
      _handleError('Calibration failed', e);
      rethrow;
    }
  }

  /// Initialize all services
  Future<void> _initializeServices() async {
    // Services are already initialized as singletons
    // Just ensure they're ready
    debugPrint('All services initialized');
  }

  /// Set up service interconnections
  void _setupServiceInterconnections() {
    // Set up sensor fusion subscriptions
    _fusionStepsSubscription = _sensorFusionService.fusedStepsStream.listen(
      _onFusedSteps,
      onError: _onFusionError,
    );

    _fusionWalkingStateSubscription = _sensorFusionService.fusedWalkingStateStream.listen(
      _onFusedWalkingState,
      onError: _onFusionError,
    );

    _fusionStatusSubscription = _sensorFusionService.fusionStatusStream.listen(
      _onFusionStatus,
      onError: _onFusionError,
    );

    // Set up battery optimization subscription
    _batteryModeSubscription = _batteryOptimizationService.batteryModeStream.listen(
      _onBatteryModeChange,
      onError: _onBatteryError,
    );

    debugPrint('Service interconnections established');
  }

  /// Start all services
  Future<void> _startAllServices() async {
    // Start battery optimization first
    await _batteryOptimizationService.startOptimizedCollection();
    
    // Start sensor fusion (which starts CWT and Enhanced Peak services)
    await _sensorFusionService.startFusion();
    
    debugPrint('All services started');
  }

  /// Stop all services
  Future<void> _stopAllServices() async {
    // Stop services in reverse order
    await _sensorFusionService.stopFusion();
    await _batteryOptimizationService.stopOptimizedCollection();
    
    debugPrint('All services stopped');
  }

  /// Start monitoring
  void _startMonitoring() {
    // Monitor performance every 30 seconds
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isRunning) {
        _collectPerformanceMetrics();
      }
    });
  }

  /// Handle fused steps from sensor fusion service
  void _onFusedSteps(int steps) {
    _finalStepsController.add(steps);
    _recordPerformanceMetric('steps_detected', steps.toDouble());
  }

  /// Handle fused walking state from sensor fusion service
  void _onFusedWalkingState(WalkingStateData state) {
    _finalWalkingStateController.add(state);
    _recordPerformanceMetric('walking_state_confidence', state.confidence);
  }

  /// Handle fusion status updates
  void _onFusionStatus(SensorFusionStatus status) {
    _recordPerformanceMetric('fusion_confidence', status.hardwareConfidence + status.cwtConfidence + status.enhancedPeakConfidence);
    _emitStatus();
  }

  /// Handle battery mode changes
  void _onBatteryModeChange(BatteryMode mode) {
    _recordPerformanceMetric('battery_mode', mode.index.toDouble());
    _emitStatus();
  }

  /// Handle fusion errors
  void _onFusionError(dynamic error) {
    _handleError('Sensor fusion error', error);
  }

  /// Handle battery optimization errors
  void _onBatteryError(dynamic error) {
    _handleError('Battery optimization error', error);
  }

  /// Collect calibration data
  Future<List<AccelerometerData>> _collectCalibrationData() async {
    final calibrationData = <AccelerometerData>[];
    final completer = Completer<List<AccelerometerData>>();
    
    // Collect data for 15 seconds
    final subscription = _batteryOptimizationService.batchStream.listen((batch) {
      calibrationData.addAll(batch);
    });
    
    Timer(const Duration(seconds: 15), () {
      subscription.cancel();
      completer.complete(calibrationData);
    });
    
    return completer.future;
  }

  /// Calculate calibrated configuration
  StepDetectionConfig _calculateCalibratedConfig(List<AccelerometerData> calibrationData) {
    if (calibrationData.isEmpty) return _config;
    
    // Calculate user-specific parameters
    final magnitudes = calibrationData.map((d) => d.magnitude).toList();
    final mean = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final variance = magnitudes.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / magnitudes.length;
    final stdDev = sqrt(variance);
    
    // Create calibrated configuration
    return _config.copyWith(
      isCalibrated: true,
      userBaselineMagnitude: mean,
      minMagnitudeThreshold: (mean - stdDev * 1.5).clamp(7.0, 9.0),
      maxMagnitudeThreshold: (mean + stdDev * 2.5).clamp(12.0, 20.0),
    );
  }

  /// Collect performance metrics
  void _collectPerformanceMetrics() {
    final status = _sensorFusionService.currentStatus;
    final batteryStatus = _batteryOptimizationService.getStatus();
    
    _recordPerformanceMetric('fusion_mode', status.mode.index.toDouble());
    _recordPerformanceMetric('battery_consumption', batteryStatus.powerConsumption.toDouble());
    _recordPerformanceMetric('activity_level', batteryStatus.activityLevel);
    _recordPerformanceMetric('sampling_rate', batteryStatus.samplingRate.toDouble());
  }

  /// Record performance metric
  void _recordPerformanceMetric(String name, double value) {
    final metric = PerformanceMetric(
      name: name,
      value: value,
      timestamp: DateTime.now(),
    );
    
    _performanceMetrics.add(metric);
    if (_performanceMetrics.length > _maxPerformanceMetrics) {
      _performanceMetrics.removeAt(0);
    }
  }

  /// Handle errors
  void _handleError(String message, dynamic error) {
    _errorCount++;
    
    final errorLog = ErrorLog(
      message: message,
      error: error.toString(),
      timestamp: DateTime.now(),
      stackTrace: StackTrace.current.toString(),
    );
    
    _errorLogs.add(errorLog);
    if (_errorLogs.length > _maxErrorLogs) {
      _errorLogs.removeAt(0);
    }
    
    debugPrint('Error: $message - $error');
  }

  /// Get current status
  StepTrackingStatus _getCurrentStatus() {
    final fusionStatus = _sensorFusionService.currentStatus;
    final batteryStatus = _batteryOptimizationService.getStatus();
    
    return StepTrackingStatus(
      isInitialized: _isInitialized,
      isRunning: _isRunning,
      startTime: _startTime,
      currentSteps: fusionStatus.fusedSteps,
      fusionMode: fusionStatus.mode,
      batteryMode: batteryStatus.mode,
      activityLevel: batteryStatus.activityLevel,
      powerConsumption: batteryStatus.powerConsumption,
      errorCount: _errorCount,
      uptime: _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero,
    );
  }

  /// Emit status update
  void _emitStatus() {
    _statusController.add(currentStatus);
  }

  /// Get performance metrics
  List<PerformanceMetric> getPerformanceMetrics() {
    return List.from(_performanceMetrics);
  }

  /// Get error logs
  List<ErrorLog> getErrorLogs() {
    return List.from(_errorLogs);
  }

  /// Reset all counters and state
  void reset() {
    _cwtService.resetCounters();
    _enhancedPeakService.resetCounters();
    // _sensorFusionService.resetCounters(); // Method doesn't exist
    _signalPreprocessingService.reset();
    
    _performanceMetrics.clear();
    _errorLogs.clear();
    _errorCount = 0;
    
    debugPrint('Comprehensive step tracking service reset');
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
    
    _fusionStepsSubscription?.cancel();
    _fusionWalkingStateSubscription?.cancel();
    _fusionStatusSubscription?.cancel();
    _batteryModeSubscription?.cancel();
    
    _finalStepsController.close();
    _finalWalkingStateController.close();
    _statusController.close();
    
    _cwtService.dispose();
    _enhancedPeakService.dispose();
    _sensorFusionService.dispose();
    _batteryOptimizationService.dispose();
    
    debugPrint('Comprehensive step tracking service disposed');
  }
}

/// Step tracking status
class StepTrackingStatus {
  final bool isInitialized;
  final bool isRunning;
  final DateTime? startTime;
  final int currentSteps;
  final SensorFusionMode fusionMode;
  final BatteryMode batteryMode;
  final double activityLevel;
  final int powerConsumption;
  final int errorCount;
  final Duration uptime;

  const StepTrackingStatus({
    required this.isInitialized,
    required this.isRunning,
    required this.startTime,
    required this.currentSteps,
    required this.fusionMode,
    required this.batteryMode,
    required this.activityLevel,
    required this.powerConsumption,
    required this.errorCount,
    required this.uptime,
  });

  @override
  String toString() {
    return 'StepTrackingStatus(running: $isRunning, steps: $currentSteps, fusion: $fusionMode, battery: $batteryMode, uptime: ${uptime.inMinutes}m)';
  }
}

/// Performance metric
class PerformanceMetric {
  final String name;
  final double value;
  final DateTime timestamp;

  const PerformanceMetric({
    required this.name,
    required this.value,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'PerformanceMetric(name: $name, value: $value, time: $timestamp)';
  }
}

/// Error log
class ErrorLog {
  final String message;
  final String error;
  final DateTime timestamp;
  final String stackTrace;

  const ErrorLog({
    required this.message,
    required this.error,
    required this.timestamp,
    required this.stackTrace,
  });

  @override
  String toString() {
    return 'ErrorLog(message: $message, error: $error, time: $timestamp)';
  }
}
