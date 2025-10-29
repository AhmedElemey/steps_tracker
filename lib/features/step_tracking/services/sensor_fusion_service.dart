import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import '../models/step_detection_config.dart';
import '../models/walking_state.dart';
import 'cwt_step_detection_service.dart';
import 'enhanced_peak_detection_service.dart';

class SensorFusionService {
  static final SensorFusionService _instance = SensorFusionService._internal();
  factory SensorFusionService() => _instance;
  SensorFusionService._internal();

  final CWTStepDetectionService _cwtService = CWTStepDetectionService();
  final EnhancedPeakDetectionService _enhancedPeakService = EnhancedPeakDetectionService();
  
  final StreamController<int> _fusedStepsController = StreamController<int>.broadcast();
  final StreamController<WalkingStateData> _fusedWalkingStateController = StreamController<WalkingStateData>.broadcast();
  final StreamController<SensorFusionStatus> _fusionStatusController = StreamController<SensorFusionStatus>.broadcast();

  StreamSubscription<StepCount>? _hardwareStepStream;
  StreamSubscription<int>? _cwtStepsStream;
  StreamSubscription<int>? _enhancedPeakStepsStream;
  StreamSubscription<WalkingStateData>? _cwtWalkingStateStream;
  StreamSubscription<WalkingStateData>? _enhancedPeakWalkingStateStream;

  StepDetectionConfig _config = const StepDetectionConfig();
  
  int _hardwareSteps = 0;
  int _cwtSteps = 0;
  int _enhancedPeakSteps = 0;
  int _fusedSteps = 0;
  DateTime? _lastHardwareUpdate;
  DateTime? _lastCWTUpdate;
  DateTime? _lastEnhancedPeakUpdate;
  
  SensorFusionMode _currentMode = SensorFusionMode.adaptive;
  double _hardwareConfidence = 0.0;
  double _cwtConfidence = 0.0;
  double _enhancedPeakConfidence = 0.0;
  
  bool _isLowPowerMode = false;
  Timer? _batteryOptimizationTimer;
  int _processingInterval = 100; // ms - how often to process data
  
  final List<StepReading> _recentReadings = [];
  final int _maxRecentReadings = 50;

  int get fusedSteps => _fusedSteps;
  SensorFusionMode get currentMode => _currentMode;
  bool get isLowPowerMode => _isLowPowerMode;
  SensorFusionStatus get currentStatus => SensorFusionStatus(
    mode: _currentMode,
    hardwareSteps: _hardwareSteps,
    cwtSteps: _cwtSteps,
    enhancedPeakSteps: _enhancedPeakSteps,
    fusedSteps: _fusedSteps,
    hardwareConfidence: _hardwareConfidence,
    cwtConfidence: _cwtConfidence,
    enhancedPeakConfidence: _enhancedPeakConfidence,
    isLowPowerMode: _isLowPowerMode,
  );

  Stream<int> get fusedStepsStream => _fusedStepsController.stream;
  Stream<WalkingStateData> get fusedWalkingStateStream => _fusedWalkingStateController.stream;
  Stream<SensorFusionStatus> get fusionStatusStream => _fusionStatusController.stream;

  Future<void> startFusion() async {
    debugPrint('Starting sensor fusion step detection...');

    _resetFusionState();

    try {
      await _startHardwareStepCounter();
      
      await _startSoftwareAlgorithms();
      
      _startBatteryOptimization();
      
      _emitFusionStatus();
      
      debugPrint('Sensor fusion started successfully');
    } catch (e) {
      debugPrint('Error starting sensor fusion: $e');
      _handleFusionError('Failed to start sensor fusion: $e');
    }
  }

  Future<void> stopFusion() async {
    await _hardwareStepStream?.cancel();
    await _cwtStepsStream?.cancel();
    await _enhancedPeakStepsStream?.cancel();
    await _cwtWalkingStateStream?.cancel();
    await _enhancedPeakWalkingStateStream?.cancel();
    
    await _cwtService.stopDetection();
    await _enhancedPeakService.stopDetection();
    
    _batteryOptimizationTimer?.cancel();
    
    debugPrint('Sensor fusion stopped');
  }

  void updateConfig(StepDetectionConfig newConfig) {
    _config = newConfig;
    _cwtService.updateConfig(newConfig);
    _enhancedPeakService.updateConfig(newConfig);
    debugPrint('Sensor fusion config updated: $newConfig');
  }

  Future<void> _startHardwareStepCounter() async {
    try {
      _hardwareStepStream = Pedometer.stepCountStream.listen(
        _onHardwareStepCount,
        onError: _onHardwareError,
      );
      debugPrint('Hardware step counter started');
    } catch (e) {
      debugPrint('Hardware step counter not available: $e');
      _hardwareConfidence = 0.0;
    }
  }

  Future<void> _startSoftwareAlgorithms() async {
    await _cwtService.startDetection();
    _cwtStepsStream = _cwtService.stepsStream.listen(
      _onCWTSteps,
      onError: _onCWTError,
    );
    _cwtWalkingStateStream = _cwtService.walkingStateStream.listen(
      _onCWTWalkingState,
      onError: _onCWTError,
    );

    await _enhancedPeakService.startDetection();
    _enhancedPeakStepsStream = _enhancedPeakService.stepsStream.listen(
      _onEnhancedPeakSteps,
      onError: _onEnhancedPeakError,
    );
    _enhancedPeakWalkingStateStream = _enhancedPeakService.walkingStateStream.listen(
      _onEnhancedPeakWalkingState,
      onError: _onEnhancedPeakError,
    );

    debugPrint('Software algorithms started');
  }

  void _startBatteryOptimization() {
    _batteryOptimizationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _optimizeBatteryUsage();
    });
  }

  void _onHardwareStepCount(StepCount event) {
    _hardwareSteps = event.steps;
    _lastHardwareUpdate = event.timeStamp;
    
    _updateHardwareConfidence();
    
    debugPrint('Hardware steps: $_hardwareSteps');
    _performSensorFusion();
  }

  void _onCWTSteps(int steps) {
    _cwtSteps = steps;
    _lastCWTUpdate = DateTime.now();
    
    _updateCWTConfidence();
    
    debugPrint('CWT steps: $_cwtSteps');
    _performSensorFusion();
  }

  void _onEnhancedPeakSteps(int steps) {
    _enhancedPeakSteps = steps;
    _lastEnhancedPeakUpdate = DateTime.now();
    
    _updateEnhancedPeakConfidence();
    
    debugPrint('Enhanced Peak steps: $_enhancedPeakSteps');
    _performSensorFusion();
  }

  void _onCWTWalkingState(WalkingStateData state) {
    _cwtConfidence = state.confidence;
    _performSensorFusion();
  }

  void _onEnhancedPeakWalkingState(WalkingStateData state) {
    _enhancedPeakConfidence = state.confidence;
    _performSensorFusion();
  }

  void _updateHardwareConfidence() {
    if (_lastHardwareUpdate == null) {
      _hardwareConfidence = 0.0;
      return;
    }
    
    final timeSinceUpdate = DateTime.now().difference(_lastHardwareUpdate!);
    
    if (timeSinceUpdate.inSeconds < 5) {
      _hardwareConfidence = 1.0; // High confidence for recent updates
    } else if (timeSinceUpdate.inSeconds < 30) {
      _hardwareConfidence = 0.8; // Good confidence
    } else if (timeSinceUpdate.inSeconds < 60) {
      _hardwareConfidence = 0.5; // Medium confidence
    } else {
      _hardwareConfidence = 0.2; // Low confidence
    }
  }

  void _updateCWTConfidence() {
    if (_lastCWTUpdate == null) {
      _cwtConfidence = 0.0;
      return;
    }
    
    final timeSinceUpdate = DateTime.now().difference(_lastCWTUpdate!);
    
    double baseConfidence = 0.7; // Base confidence for CWT
    
    if (timeSinceUpdate.inSeconds < 2) {
      baseConfidence = 0.9; // High confidence for recent updates
    } else if (timeSinceUpdate.inSeconds > 10) {
      baseConfidence = 0.3; // Low confidence for stale data
    }
    
    _cwtConfidence = baseConfidence;
  }

  void _updateEnhancedPeakConfidence() {
    if (_lastEnhancedPeakUpdate == null) {
      _enhancedPeakConfidence = 0.0;
      return;
    }
    
    final timeSinceUpdate = DateTime.now().difference(_lastEnhancedPeakUpdate!);
    
    double baseConfidence = 0.8; // Base confidence for Enhanced Peak
    
    if (timeSinceUpdate.inSeconds < 2) {
      baseConfidence = 0.95; // High confidence for recent updates
    } else if (timeSinceUpdate.inSeconds > 10) {
      baseConfidence = 0.4; // Low confidence for stale data
    }
    
    _enhancedPeakConfidence = baseConfidence;
  }

  void _performSensorFusion() {
    _determineFusionMode();
    
    final newFusedSteps = _calculateFusedSteps();
    
    if (newFusedSteps != _fusedSteps) {
      _fusedSteps = newFusedSteps;
      
      _storeStepReading(StepReading(
        steps: _fusedSteps,
        timestamp: DateTime.now(),
        source: _getPrimarySource(),
        confidence: _getOverallConfidence(),
      ));
      
      _fusedStepsController.add(_fusedSteps);
      
      _emitFusionStatus();
      
      debugPrint('Fused steps: $_fusedSteps (mode: $_currentMode)');
    }
  }

  void _determineFusionMode() {
    if (_isLowPowerMode) {
      _currentMode = SensorFusionMode.hardwareOnly;
      return;
    }
    
    final hasHardware = _hardwareConfidence > 0.5;
    final hasCWT = _cwtConfidence > 0.5;
    final hasEnhancedPeak = _enhancedPeakConfidence > 0.5;
    
    if (hasHardware && hasCWT && hasEnhancedPeak) {
      _currentMode = SensorFusionMode.fullFusion;
    } else if (hasHardware && (hasCWT || hasEnhancedPeak)) {
      _currentMode = SensorFusionMode.hardwareSoftware;
    } else if (hasCWT && hasEnhancedPeak) {
      _currentMode = SensorFusionMode.softwareOnly;
    } else if (hasHardware) {
      _currentMode = SensorFusionMode.hardwareOnly;
    } else if (hasCWT || hasEnhancedPeak) {
      _currentMode = SensorFusionMode.softwareOnly;
    } else {
      _currentMode = SensorFusionMode.adaptive;
    }
  }

  int _calculateFusedSteps() {
    switch (_currentMode) {
      case SensorFusionMode.hardwareOnly:
        return _hardwareSteps;
        
      case SensorFusionMode.softwareOnly:
        if (_cwtConfidence > 0 && _enhancedPeakConfidence > 0) {
          final totalConfidence = _cwtConfidence + _enhancedPeakConfidence;
          final cwtWeight = _cwtConfidence / totalConfidence;
          final enhancedPeakWeight = _enhancedPeakConfidence / totalConfidence;
          return ((_cwtSteps * cwtWeight) + (_enhancedPeakSteps * enhancedPeakWeight)).round();
        } else if (_cwtConfidence > _enhancedPeakConfidence) {
          return _cwtSteps;
        } else {
          return _enhancedPeakSteps;
        }
        
      case SensorFusionMode.hardwareSoftware:
        final hardwareWeight = _hardwareConfidence;
        final softwareWeight = max(_cwtConfidence, _enhancedPeakConfidence);
        final totalWeight = hardwareWeight + softwareWeight;
        
        if (totalWeight > 0) {
          final hardwareSteps = _hardwareSteps * (hardwareWeight / totalWeight);
          final softwareSteps = max(_cwtSteps, _enhancedPeakSteps) * (softwareWeight / totalWeight);
          return (hardwareSteps + softwareSteps).round();
        }
        return _hardwareSteps;
        
      case SensorFusionMode.fullFusion:
        final totalConfidence = _hardwareConfidence + _cwtConfidence + _enhancedPeakConfidence;
        if (totalConfidence > 0) {
          final hardwareWeight = _hardwareConfidence / totalConfidence;
          final cwtWeight = _cwtConfidence / totalConfidence;
          final enhancedPeakWeight = _enhancedPeakConfidence / totalConfidence;
          
          return ((_hardwareSteps * hardwareWeight) + 
                  (_cwtSteps * cwtWeight) + 
                  (_enhancedPeakSteps * enhancedPeakWeight)).round();
        }
        return _hardwareSteps;
        
      case SensorFusionMode.adaptive:
        if (_hardwareConfidence > max(_cwtConfidence, _enhancedPeakConfidence)) {
          return _hardwareSteps;
        } else if (_cwtConfidence > _enhancedPeakConfidence) {
          return _cwtSteps;
        } else {
          return _enhancedPeakSteps;
        }
    }
  }

  void _storeStepReading(StepReading reading) {
    _recentReadings.add(reading);
    if (_recentReadings.length > _maxRecentReadings) {
      _recentReadings.removeAt(0);
    }
  }

  String _getPrimarySource() {
    switch (_currentMode) {
      case SensorFusionMode.hardwareOnly:
        return 'hardware';
      case SensorFusionMode.softwareOnly:
        return _cwtConfidence > _enhancedPeakConfidence ? 'cwt' : 'enhanced_peak';
      case SensorFusionMode.hardwareSoftware:
        return 'hardware_software';
      case SensorFusionMode.fullFusion:
        return 'full_fusion';
      case SensorFusionMode.adaptive:
        return 'adaptive';
    }
  }

  double _getOverallConfidence() {
    switch (_currentMode) {
      case SensorFusionMode.hardwareOnly:
        return _hardwareConfidence;
      case SensorFusionMode.softwareOnly:
        return max(_cwtConfidence, _enhancedPeakConfidence);
      case SensorFusionMode.hardwareSoftware:
        return (_hardwareConfidence + max(_cwtConfidence, _enhancedPeakConfidence)) / 2;
      case SensorFusionMode.fullFusion:
        return (_hardwareConfidence + _cwtConfidence + _enhancedPeakConfidence) / 3;
      case SensorFusionMode.adaptive:
        return max(_hardwareConfidence, max(_cwtConfidence, _enhancedPeakConfidence));
    }
  }

  void _optimizeBatteryUsage() {
    final timeSinceLastUpdate = _getTimeSinceLastUpdate();
    
    if (timeSinceLastUpdate.inSeconds > 60) {
      _enterLowPowerMode();
    } else if (_isLowPowerMode && timeSinceLastUpdate.inSeconds < 10) {
      _exitLowPowerMode();
    }
    
    if (_isLowPowerMode) {
      _processingInterval = 1000; // 1 second intervals in low power mode
    } else {
      _processingInterval = 100; // 100ms intervals in normal mode
    }
  }

  Duration _getTimeSinceLastUpdate() {
    final times = <DateTime?>[_lastHardwareUpdate, _lastCWTUpdate, _lastEnhancedPeakUpdate];
    final validTimes = times.where((time) => time != null).cast<DateTime>();
    
    if (validTimes.isEmpty) {
      return const Duration(hours: 1); // No updates
    }
    
    final latestTime = validTimes.reduce((a, b) => a.isAfter(b) ? a : b);
    return DateTime.now().difference(latestTime);
  }

  void _enterLowPowerMode() {
    if (!_isLowPowerMode) {
      _isLowPowerMode = true;
      debugPrint('Entering low power mode');
      _emitFusionStatus();
    }
  }

  void _exitLowPowerMode() {
    if (_isLowPowerMode) {
      _isLowPowerMode = false;
      debugPrint('Exiting low power mode');
      _emitFusionStatus();
    }
  }

  void _emitFusionStatus() {
    _fusionStatusController.add(currentStatus);
  }

  void _resetFusionState() {
    _hardwareSteps = 0;
    _cwtSteps = 0;
    _enhancedPeakSteps = 0;
    _fusedSteps = 0;
    _lastHardwareUpdate = null;
    _lastCWTUpdate = null;
    _lastEnhancedPeakUpdate = null;
    _hardwareConfidence = 0.0;
    _cwtConfidence = 0.0;
    _enhancedPeakConfidence = 0.0;
    _currentMode = SensorFusionMode.adaptive;
    _isLowPowerMode = false;
    _recentReadings.clear();
  }

  void _onHardwareError(dynamic error) {
    debugPrint('Hardware step counter error: $error');
    _hardwareConfidence = 0.0;
    _performSensorFusion();
  }

  void _onCWTError(dynamic error) {
    debugPrint('CWT step detection error: $error');
    _cwtConfidence = 0.0;
    _performSensorFusion();
  }

  void _onEnhancedPeakError(dynamic error) {
    debugPrint('Enhanced peak detection error: $error');
    _enhancedPeakConfidence = 0.0;
    _performSensorFusion();
  }

  void _handleFusionError(String message) {
    debugPrint('Sensor fusion error: $message');
    _emitFusionStatus();
  }

  void dispose() {
    stopFusion();
    _fusedStepsController.close();
    _fusedWalkingStateController.close();
    _fusionStatusController.close();
  }
}

enum SensorFusionMode {
  hardwareOnly,      // Use only hardware step counter
  softwareOnly,      // Use only software algorithms
  hardwareSoftware,  // Combine hardware with software
  fullFusion,        // Use all available sources
  adaptive,          // Automatically choose best source
}

class SensorFusionStatus {
  final SensorFusionMode mode;
  final int hardwareSteps;
  final int cwtSteps;
  final int enhancedPeakSteps;
  final int fusedSteps;
  final double hardwareConfidence;
  final double cwtConfidence;
  final double enhancedPeakConfidence;
  final bool isLowPowerMode;

  const SensorFusionStatus({
    required this.mode,
    required this.hardwareSteps,
    required this.cwtSteps,
    required this.enhancedPeakSteps,
    required this.fusedSteps,
    required this.hardwareConfidence,
    required this.cwtConfidence,
    required this.enhancedPeakConfidence,
    required this.isLowPowerMode,
  });

  @override
  String toString() {
    return 'SensorFusionStatus(mode: $mode, fusedSteps: $fusedSteps, confidence: ${(hardwareConfidence + cwtConfidence + enhancedPeakConfidence) / 3})';
  }
}

class StepReading {
  final int steps;
  final DateTime timestamp;
  final String source;
  final double confidence;

  const StepReading({
    required this.steps,
    required this.timestamp,
    required this.source,
    required this.confidence,
  });

  @override
  String toString() {
    return 'StepReading(steps: $steps, source: $source, confidence: $confidence)';
  }
}
