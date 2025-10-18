import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/firebase_service.dart';
import '../models/step_data.dart';
import '../../steps/services/steps_service.dart';

class StepTrackingService {
  static final StepTrackingService _instance = StepTrackingService._internal();
  factory StepTrackingService() => _instance;
  StepTrackingService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirebaseService _firebaseService = FirebaseService();
  final StepsService _stepsService = StepsService();
  StreamSubscription<StepCount>? _stepCountStream;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusStream;
  
  int _currentSteps = 0;
  DateTime? _lastUpdateTime;
  
  // Getters
  int get currentSteps => _currentSteps;
  DateTime? get lastUpdateTime => _lastUpdateTime;

  // Stream controllers for UI updates
  final StreamController<int> _stepsController = StreamController<int>.broadcast();
  final StreamController<PedestrianStatus> _statusController = StreamController<PedestrianStatus>.broadcast();

  Stream<int> get stepsStream => _stepsController.stream;
  Stream<PedestrianStatus> get statusStream => _statusController.stream;

  Future<bool> requestPermissions() async {
    // Request activity recognition permission
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  Future<bool> isPermissionGranted() async {
    final status = await Permission.activityRecognition.status;
    return status.isGranted;
  }

  Future<void> startTracking() async {
    try {
      // Check permissions first
      if (!await isPermissionGranted()) {
        final granted = await requestPermissions();
        if (!granted) {
          // For demo purposes, start with mock data if permission not granted
          print('Permission not granted, using mock data for demo');
          _startMockTracking();
          return;
        }
      }

      // Pedometer doesn't need initialization in this version

      // Listen to step count stream
      _stepCountStream = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
      );

      // Listen to pedestrian status stream
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatus,
        onError: _onPedestrianStatusError,
      );

      // Load today's step data
      await _loadTodayStepData();
    } catch (e) {
      print('Error starting step tracking: $e');
      // Start with mock data if real tracking fails
      _startMockTracking();
    }
  }

  void _startMockTracking() {
    // Simulate step tracking with mock data for demo purposes
    _currentSteps = 2500; // Start with some demo steps
    _stepsController.add(_currentSteps);
    
    // Simulate periodic step updates
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_stepCountStream == null) {
        _currentSteps += (1 + (DateTime.now().millisecond % 3)); // Add 1-3 steps
        _stepsController.add(_currentSteps);
        _saveStepData();
      } else {
        timer.cancel();
      }
    });
  }

  void _onStepCount(StepCount event) {
    _currentSteps = event.steps;
    _lastUpdateTime = event.timeStamp;
    
    // Emit to stream
    _stepsController.add(_currentSteps);
    
    // Save to local database
    _saveStepData();
    
    // Save to Firestore if user is signed in
    if (_firebaseService.isSignedIn) {
      _stepsService.addStepsEntry(_currentSteps);
    }
  }

  void _onStepCountError(error) {
    print('Step count error: $error');
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    _statusController.add(event);
  }

  void _onPedestrianStatusError(error) {
    print('Pedestrian status error: $error');
  }

  Future<void> _loadTodayStepData() async {
    final today = DateTime.now();
    final stepData = await _databaseHelper.getStepDataByDate(today);
    
    if (stepData != null) {
      _currentSteps = stepData.steps;
      _lastUpdateTime = stepData.updatedAt;
      _stepsController.add(_currentSteps);
    }
  }

  Future<void> _saveStepData() async {
    final today = DateTime.now();
    final existingData = await _databaseHelper.getStepDataByDate(today);
    
    // Calculate distance (assuming average step length of 0.7 meters)
    const double averageStepLength = 0.7;
    final distance = _currentSteps * averageStepLength;
    
    // Calculate calories (rough estimate: 0.04 calories per step)
    const double caloriesPerStep = 0.04;
    final calories = (_currentSteps * caloriesPerStep).round();

    final stepData = StepData(
      id: existingData?.id ?? -1, // Use -1 for new records, will be removed during insert
      date: today,
      steps: _currentSteps,
      distance: distance,
      calories: calories,
      createdAt: existingData?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (existingData != null) {
      await _databaseHelper.updateStepData(stepData);
    } else {
      await _databaseHelper.insertStepData(stepData);
    }
  }

  Future<void> stopTracking() async {
    await _stepCountStream?.cancel();
    await _pedestrianStatusStream?.cancel();
    _stepCountStream = null;
    _pedestrianStatusStream = null;
  }

  Future<List<StepData>> getStepHistory({int days = 7}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    return await _databaseHelper.getStepDataInRange(startDate, endDate);
  }

  Future<StepData?> getTodayStepData() async {
    return await _databaseHelper.getStepDataByDate(DateTime.now());
  }

  Future<List<StepData>> getAllStepData() async {
    return await _databaseHelper.getAllStepData();
  }

  void dispose() {
    _stepsController.close();
    _statusController.close();
    stopTracking();
  }
}
