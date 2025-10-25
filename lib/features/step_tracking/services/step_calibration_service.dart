import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/step_detection_config.dart';
import '../models/accelerometer_data.dart';

class StepCalibrationService {
  static final StepCalibrationService _instance = StepCalibrationService._internal();
  factory StepCalibrationService() => _instance;
  StepCalibrationService._internal();

  static const String _configKey = 'step_detection_config';
  static const String _userProfileKey = 'user_step_profile';

  // Calibration data
  final List<AccelerometerData> _calibrationSamples = [];
  final List<double> _walkingMagnitudes = [];
  final List<double> _idleMagnitudes = [];
  
  // Calibration state
  bool _isCalibrating = false;
  DateTime? _calibrationStartTime;
  Timer? _calibrationTimer;

  // Stream controllers
  final StreamController<CalibrationProgress> _progressController = StreamController<CalibrationProgress>.broadcast();
  final StreamController<CalibrationResult> _resultController = StreamController<CalibrationResult>.broadcast();

  // Getters
  bool get isCalibrating => _isCalibrating;
  Stream<CalibrationProgress> get progressStream => _progressController.stream;
  Stream<CalibrationResult> get resultStream => _resultController.stream;

  /// Start calibration process
  Future<void> startCalibration() async {
    if (_isCalibrating) return;

    _isCalibrating = true;
    _calibrationSamples.clear();
    _walkingMagnitudes.clear();
    _idleMagnitudes.clear();
    _calibrationStartTime = DateTime.now();

    // Emit initial progress
    _progressController.add(CalibrationProgress(
      phase: CalibrationPhase.preparing,
      progress: 0.0,
      message: 'Preparing calibration...',
    ));

    // Start calibration phases
    _startCalibrationPhases();
  }

  /// Start the calibration phases
  void _startCalibrationPhases() {
    // Phase 1: Idle detection (5 seconds)
    _progressController.add(CalibrationProgress(
      phase: CalibrationPhase.idle,
      progress: 0.1,
      message: 'Please hold your device still for 5 seconds...',
    ));

    Timer(const Duration(seconds: 5), () {
      if (!_isCalibrating) return;

      // Phase 2: Walking detection (15 seconds)
      _progressController.add(CalibrationProgress(
        phase: CalibrationPhase.walking,
        progress: 0.3,
        message: 'Now walk normally for 15 seconds...',
      ));

      Timer(const Duration(seconds: 15), () {
        if (!_isCalibrating) return;

        // Phase 3: Analysis
        _progressController.add(CalibrationProgress(
          phase: CalibrationPhase.analyzing,
          progress: 0.8,
          message: 'Analyzing your walking pattern...',
        ));

        Timer(const Duration(seconds: 2), () {
          if (!_isCalibrating) return;
          _completeCalibration();
        });
      });
    });
  }

  /// Add accelerometer data during calibration
  void addCalibrationData(AccelerometerData data) {
    if (!_isCalibrating) return;

    _calibrationSamples.add(data);

    // Categorize data based on calibration phase
    final elapsed = DateTime.now().difference(_calibrationStartTime!);
    
    if (elapsed.inSeconds < 5) {
      // Idle phase
      _idleMagnitudes.add(data.magnitude);
    } else if (elapsed.inSeconds < 20) {
      // Walking phase
      _walkingMagnitudes.add(data.magnitude);
    }
  }

  /// Complete calibration and calculate user profile
  Future<void> _completeCalibration() async {
    try {
      if (_calibrationSamples.isEmpty) {
        _emitCalibrationResult(false, 'No calibration data collected');
        return;
      }

      // Calculate user profile
      final userProfile = _calculateUserProfile();
      
      // Create optimized config
      final optimizedConfig = _createOptimizedConfig(userProfile);
      
      // Save configuration
      await _saveConfiguration(optimizedConfig);
      await _saveUserProfile(userProfile);

      _isCalibrating = false;
      _emitCalibrationResult(true, 'Calibration completed successfully!');
      
    } catch (e) {
      _isCalibrating = false;
      _emitCalibrationResult(false, 'Calibration failed: $e');
    }
  }

  /// Calculate user-specific profile
  UserStepProfile _calculateUserProfile() {
    // Calculate baseline magnitudes
    final idleBaseline = _calculateBaseline(_idleMagnitudes);
    final walkingBaseline = _calculateBaseline(_walkingMagnitudes);
    
    // Calculate walking characteristics
    final walkingVariability = _calculateVariability(_walkingMagnitudes);
    final stepAmplitude = walkingBaseline - idleBaseline;
    
    // Determine user's walking style
    final walkingStyle = _determineWalkingStyle(stepAmplitude, walkingVariability);
    
    return UserStepProfile(
      idleBaseline: idleBaseline,
      walkingBaseline: walkingBaseline,
      stepAmplitude: stepAmplitude,
      walkingVariability: walkingVariability,
      walkingStyle: walkingStyle,
      calibrationDate: DateTime.now(),
    );
  }

  /// Calculate baseline (median) from magnitude data
  double _calculateBaseline(List<double> magnitudes) {
    if (magnitudes.isEmpty) return 9.81; // Default gravity
    
    magnitudes.sort();
    final medianIndex = magnitudes.length ~/ 2;
    return magnitudes[medianIndex];
  }

  /// Calculate variability (standard deviation) from magnitude data
  double _calculateVariability(List<double> magnitudes) {
    if (magnitudes.length < 2) return 0.0;
    
    final mean = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final variance = magnitudes.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / magnitudes.length;
    return sqrt(variance);
  }

  /// Determine user's walking style
  WalkingStyle _determineWalkingStyle(double stepAmplitude, double variability) {
    if (stepAmplitude < 0.5) {
      return WalkingStyle.light;
    } else if (stepAmplitude > 1.5) {
      return WalkingStyle.heavy;
    } else if (variability > 0.8) {
      return WalkingStyle.variable;
    } else {
      return WalkingStyle.normal;
    }
  }

  /// Create optimized configuration based on user profile
  StepDetectionConfig _createOptimizedConfig(UserStepProfile profile) {
    // Adjust thresholds based on user's walking characteristics
    double peakThreshold = 1.2;
    double valleyThreshold = 0.8;
    double minMagnitude = 9.5;
    double maxMagnitude = 15.0;

    switch (profile.walkingStyle) {
      case WalkingStyle.light:
        peakThreshold = 1.0;
        valleyThreshold = 0.6;
        minMagnitude = profile.idleBaseline - 0.2;
        maxMagnitude = profile.walkingBaseline + 1.0;
        break;
      case WalkingStyle.heavy:
        peakThreshold = 1.5;
        valleyThreshold = 1.0;
        minMagnitude = profile.idleBaseline - 0.5;
        maxMagnitude = profile.walkingBaseline + 2.0;
        break;
      case WalkingStyle.variable:
        peakThreshold = 1.3;
        valleyThreshold = 0.7;
        minMagnitude = profile.idleBaseline - 0.3;
        maxMagnitude = profile.walkingBaseline + 1.5;
        break;
      case WalkingStyle.normal:
        peakThreshold = 1.2;
        valleyThreshold = 0.8;
        minMagnitude = profile.idleBaseline - 0.3;
        maxMagnitude = profile.walkingBaseline + 1.2;
        break;
    }

    return StepDetectionConfig(
      peakThreshold: peakThreshold,
      valleyThreshold: valleyThreshold,
      minMagnitudeThreshold: minMagnitude,
      maxMagnitudeThreshold: maxMagnitude,
      isCalibrated: true,
      userBaselineMagnitude: profile.idleBaseline,
    );
  }

  /// Save configuration to shared preferences
  Future<void> _saveConfiguration(StepDetectionConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, _configToJson(config));
  }

  /// Save user profile to shared preferences
  Future<void> _saveUserProfile(UserStepProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProfileKey, _profileToJson(profile));
  }

  /// Load saved configuration
  Future<StepDetectionConfig?> loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_configKey);
    
    if (configJson != null) {
      return _configFromJson(configJson);
    }
    
    return null;
  }

  /// Load saved user profile
  Future<UserStepProfile?> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_userProfileKey);
    
    if (profileJson != null) {
      return _profileFromJson(profileJson);
    }
    
    return null;
  }

  /// Emit calibration result
  void _emitCalibrationResult(bool success, String message) {
    final result = CalibrationResult(
      success: success,
      message: message,
      userProfile: success ? _calculateUserProfile() : null,
    );
    
    _resultController.add(result);
  }

  /// Cancel calibration
  void cancelCalibration() {
    _isCalibrating = false;
    _calibrationTimer?.cancel();
    _emitCalibrationResult(false, 'Calibration cancelled');
  }

  /// Convert config to JSON string
  String _configToJson(StepDetectionConfig config) {
    return '${config.peakThreshold}|${config.valleyThreshold}|${config.minMagnitudeThreshold}|${config.maxMagnitudeThreshold}|${config.isCalibrated}|${config.userBaselineMagnitude}';
  }

  /// Convert JSON string to config
  StepDetectionConfig _configFromJson(String json) {
    final parts = json.split('|');
    return StepDetectionConfig(
      peakThreshold: double.parse(parts[0]),
      valleyThreshold: double.parse(parts[1]),
      minMagnitudeThreshold: double.parse(parts[2]),
      maxMagnitudeThreshold: double.parse(parts[3]),
      isCalibrated: parts[4] == 'true',
      userBaselineMagnitude: double.parse(parts[5]),
    );
  }

  /// Convert profile to JSON string
  String _profileToJson(UserStepProfile profile) {
    return '${profile.idleBaseline}|${profile.walkingBaseline}|${profile.stepAmplitude}|${profile.walkingVariability}|${profile.walkingStyle.name}|${profile.calibrationDate.millisecondsSinceEpoch}';
  }

  /// Convert JSON string to profile
  UserStepProfile _profileFromJson(String json) {
    final parts = json.split('|');
    return UserStepProfile(
      idleBaseline: double.parse(parts[0]),
      walkingBaseline: double.parse(parts[1]),
      stepAmplitude: double.parse(parts[2]),
      walkingVariability: double.parse(parts[3]),
      walkingStyle: WalkingStyle.values.firstWhere((e) => e.name == parts[4]),
      calibrationDate: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[5])),
    );
  }

  /// Dispose resources
  void dispose() {
    _calibrationTimer?.cancel();
    _progressController.close();
    _resultController.close();
  }
}

// Supporting classes
enum CalibrationPhase {
  preparing,
  idle,
  walking,
  analyzing,
}

class CalibrationProgress {
  final CalibrationPhase phase;
  final double progress;
  final String message;

  CalibrationProgress({
    required this.phase,
    required this.progress,
    required this.message,
  });
}

class CalibrationResult {
  final bool success;
  final String message;
  final UserStepProfile? userProfile;

  CalibrationResult({
    required this.success,
    required this.message,
    this.userProfile,
  });
}

enum WalkingStyle {
  light,
  normal,
  heavy,
  variable,
}

class UserStepProfile {
  final double idleBaseline;
  final double walkingBaseline;
  final double stepAmplitude;
  final double walkingVariability;
  final WalkingStyle walkingStyle;
  final DateTime calibrationDate;

  UserStepProfile({
    required this.idleBaseline,
    required this.walkingBaseline,
    required this.stepAmplitude,
    required this.walkingVariability,
    required this.walkingStyle,
    required this.calibrationDate,
  });
}
