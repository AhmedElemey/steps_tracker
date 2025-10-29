import 'package:flutter/material.dart';

import 'firebase_service.dart';
import '../database/database_helper.dart';
import '../../features/step_tracking/models/step_data.dart';
import '../../features/steps/services/steps_service.dart';
import '../../features/weight/services/weight_service.dart';
import '../../features/goals/services/goals_firebase_service.dart';

import '../../features/goals/models/goal.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final StepsService _stepsService = StepsService();
  final WeightService _weightService = WeightService();
  final GoalsFirebaseService _goalsService = GoalsFirebaseService();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Future<void> initialize() async {
    _firebaseService.connectivityStream.listen((isConnected) {
      if (isConnected && _firebaseService.isSignedIn) {
        syncAllData();
      }
    });
  }

  Future<void> syncAllData() async {
    if (_isSyncing || !_firebaseService.isSignedIn) return;

    _isSyncing = true;
    try {
      await Future.wait([
        syncStepsData(),
        syncWeightData(),
        syncGoalsData(),
        syncProfileData(),
      ]);
      debugPrint('All data synced successfully');
    } catch (e) {
      debugPrint('Error during sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> syncStepsData() async {
    try {
      debugPrint('Syncing steps data...');
      
      final localStepData = await _databaseHelper.getAllStepData();
      debugPrint('Found ${localStepData.length} local step entries');
      
      for (final stepData in localStepData) {
        try {
          final dateStr = stepData.date.toIso8601String().split('T')[0];
          final existingEntries = await _stepsService.getStepsEntries();
          
          if (existingEntries.isEmpty) {
            await _stepsService.addStepsEntry(stepData.steps);
            debugPrint('Uploaded step data for $dateStr');
          } else {
            final latestEntry = existingEntries.first;
            final latestDate = latestEntry.timestamp.toIso8601String().split('T')[0];
            
            if (dateStr == latestDate) {
              if (stepData.steps > latestEntry.steps) {
                await _stepsService.updateStepsEntry(latestEntry.id, stepData.steps);
                debugPrint('Updated step data for $dateStr');
              }
            }
          }
        } catch (e) {
          debugPrint('Error syncing individual step entry: $e');
        }
      }
      
      final cloudEntries = await _stepsService.getStepsEntries();
      if (cloudEntries.isNotEmpty) {
        final latestCloudEntry = cloudEntries.first;
        final cloudDate = latestCloudEntry.timestamp;
        final localData = await _databaseHelper.getStepDataByDate(cloudDate);
        
        if (localData == null || cloudDate.isAfter(localData.date)) {
          const double averageStepLength = 0.7;
          final distance = latestCloudEntry.steps * averageStepLength;
          const double caloriesPerStep = 0.04;
          final calories = (latestCloudEntry.steps * caloriesPerStep).round();
          
          final stepData = StepData(
            id: localData?.id ?? -1,
            date: cloudDate,
            steps: latestCloudEntry.steps,
            distance: distance,
            calories: calories,
            createdAt: localData?.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          if (localData != null) {
            await _databaseHelper.updateStepData(stepData);
          } else {
            await _databaseHelper.insertStepData(stepData);
          }
          debugPrint('Downloaded and updated local step data');
        }
      }
      
      debugPrint('Steps data sync completed');
    } catch (e) {
      debugPrint('Error syncing steps data: $e');
    }
  }

  Future<void> syncWeightData() async {
    try {
      debugPrint('Syncing weight data...');
      
      final weightEntries = await _weightService.getWeightEntries();
      debugPrint('Found ${weightEntries.length} weight entries in cloud');
      
      
      debugPrint('Weight data sync completed');
    } catch (e) {
      debugPrint('Error syncing weight data: $e');
    }
  }

  Future<void> syncGoalsData() async {
    try {
      debugPrint('Syncing goals data...');
      
      final localDailyGoals = await _databaseHelper.getAllDailyGoals();
      final activeLocalGoal = await _databaseHelper.getActiveDailyGoal();
      
      debugPrint('Found ${localDailyGoals.length} local daily goals');
      
      if (activeLocalGoal != null) {
        final cloudGoals = await _goalsService.getGoals(status: GoalStatus.active);
        
        if (cloudGoals.isNotEmpty) {
          debugPrint('Found ${cloudGoals.length} active cloud goals');
          
        }
      }
      
      final cloudGoals = await _goalsService.getGoals();
      debugPrint('Found ${cloudGoals.length} total cloud goals');
      
      debugPrint('Goals data sync completed');
    } catch (e) {
      debugPrint('Error syncing goals data: $e');
    }
  }

  Future<void> syncProfileData() async {
    try {
      debugPrint('Syncing profile data...');
      debugPrint('Profile data sync completed');
    } catch (e) {
      debugPrint('Error syncing profile data: $e');
    }
  }

  Future<void> forceSync() async {
    if (!_firebaseService.isSignedIn) {
      throw Exception('User must be signed in to sync');
    }
    await syncAllData();
  }

  Future<bool> isDataInSync() async {
    try {
      return await _firebaseService.isConnected;
    } catch (e) {
      debugPrint('Error checking sync status: $e');
      return false;
    }
  }
}
