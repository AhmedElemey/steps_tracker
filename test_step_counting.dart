import 'package:flutter/material.dart';
import 'lib/features/step_tracking/services/step_tracking_service.dart';

/// Simple test script to help debug step counting issues
/// Run this to test step detection in isolation
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final stepService = StepTrackingService();
  
  print('=== Step Counting Test ===');
  print('Testing pedometer package directly first...');
  
  // Test pedometer package directly
  await stepService.testPedometerPackage();
  
  print('\nStarting step tracking...');
  
  // Start tracking
  await stepService.startTracking();
  
  // Listen to step updates
  stepService.stepsStream.listen((steps) {
    print('Session steps detected: $steps');
    print('Total device steps: ${stepService.currentSteps}');
    print('Session steps: ${stepService.sessionSteps}');
  });
  
  // Listen to walking state updates
  stepService.walkingStateStream.listen((state) {
    print('Walking state: ${state.state} - ${state.message}');
  });
  
  print('Step tracking started. Walk around and check the console for updates.');
  print('If no steps are detected after 30 seconds, the system will fall back to traditional pedometer.');
  print('Press Ctrl+C to stop.');
  
  // Keep the app running
  await Future.delayed(Duration(hours: 1));
}
