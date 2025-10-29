import 'package:flutter/material.dart';
import 'lib/features/step_tracking/services/step_tracking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final stepService = StepTrackingService();
  
  print('=== Step Counting Test ===');
  print('Testing pedometer package directly first...');
  
  await stepService.testPedometerPackage();
  
  print('\nStarting step tracking...');
  
  await stepService.startTracking();
  
  stepService.stepsStream.listen((steps) {
    print('Session steps detected: $steps');
    print('Total device steps: ${stepService.currentSteps}');
    print('Session steps: ${stepService.sessionSteps}');
  });
  
  stepService.walkingStateStream.listen((state) {
    print('Walking state: ${state.state} - ${state.message}');
  });
  
  print('Step tracking started. Walk around and check the console for updates.');
  print('If no steps are detected after 30 seconds, the system will fall back to traditional pedometer.');
  print('Press Ctrl+C to stop.');
  
  await Future.delayed(Duration(hours: 1));
}
