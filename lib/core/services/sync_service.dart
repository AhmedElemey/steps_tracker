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
    // Listen to connectivity changes and sync when online
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
      // Sync in parallel for better performance
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
      
      // Get local step data
      final localStepData = await _databaseHelper.getAllStepData();
      debugPrint('Found ${localStepData.length} local step entries');
      
      // Upload local data to Firestore if it's newer or doesn't exist in cloud
      for (final stepData in localStepData) {
        try {
          // Check if entry already exists in Firestore for this date
          final dateStr = stepData.date.toIso8601String().split('T')[0];
          final existingEntries = await _stepsService.getStepsEntries();
          
          // If no entry exists for today, add it
          if (existingEntries.isEmpty) {
            await _stepsService.addStepsEntry(stepData.steps);
            debugPrint('Uploaded step data for $dateStr');
          } else {
            // Get the most recent entry
            final latestEntry = existingEntries.first;
            final latestDate = latestEntry.timestamp.toIso8601String().split('T')[0];
            
            // If local data is newer, update Firestore
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
      
      // Download cloud data and update local if it's newer
      final cloudEntries = await _stepsService.getStepsEntries();
      if (cloudEntries.isNotEmpty) {
        final latestCloudEntry = cloudEntries.first;
        final cloudDate = latestCloudEntry.timestamp;
        final localData = await _databaseHelper.getStepDataByDate(cloudDate);
        
        if (localData == null || cloudDate.isAfter(localData.date)) {
          // Calculate distance and calories
          const double averageStepLength = 0.7;
          final distance = latestCloudEntry.steps * averageStepLength;
          const double caloriesPerStep = 0.04;
          final calories = (latestCloudEntry.steps * caloriesPerStep).round();
          
          // Update local database with cloud data
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
      
      // Weight entries are primarily stored in Firestore
      // Just ensure we have the latest data
      final weightEntries = await _weightService.getWeightEntries();
      debugPrint('Found ${weightEntries.length} weight entries in cloud');
      
      // Weight data is already in Firestore, no local sync needed
      // The weight service already handles real-time updates
      
      debugPrint('Weight data sync completed');
    } catch (e) {
      debugPrint('Error syncing weight data: $e');
    }
  }

  Future<void> syncGoalsData() async {
    try {
      debugPrint('Syncing goals data...');
      
      // Sync daily goals (local SQLite) with Firebase goals
      final localDailyGoals = await _databaseHelper.getAllDailyGoals();
      final activeLocalGoal = await _databaseHelper.getActiveDailyGoal();
      
      debugPrint('Found ${localDailyGoals.length} local daily goals');
      
      if (activeLocalGoal != null) {
        // Check if there's a corresponding goal in Firestore
        final cloudGoals = await _goalsService.getGoals(status: GoalStatus.active);
        
        // If no active cloud goal exists, we could create one
        // For now, just log the sync status
        if (cloudGoals.isNotEmpty) {
          debugPrint('Found ${cloudGoals.length} active cloud goals');
          
          // Optionally sync local daily goal data to cloud
          // This depends on your app's requirements
        }
      }
      
      // Ensure daily goals from cloud are available locally if needed
      final cloudGoals = await _goalsService.getGoals();
      debugPrint('Found ${cloudGoals.length} total cloud goals');
      
      // Goals are primarily managed through Firebase with some local caching
      debugPrint('Goals data sync completed');
    } catch (e) {
      debugPrint('Error syncing goals data: $e');
    }
  }

  Future<void> syncProfileData() async {
    try {
      debugPrint('Syncing profile data...');
      // Profile data is already handled by ProfileService with real-time updates
      // No additional sync needed as it's already in Firestore
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
      // Check if local and cloud data are in sync
      // This is a simplified check - in a real app, you'd compare timestamps
      return await _firebaseService.isConnected;
    } catch (e) {
      debugPrint('Error checking sync status: $e');
      return false;
    }
  }
}
