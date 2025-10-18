import 'package:flutter/material.dart';

import 'firebase_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final FirebaseService _firebaseService = FirebaseService();

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
    } catch (e) {
      debugPrint('Error during sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> syncStepsData() async {
    try {
      // This would sync local SQLite data with Firebase
      // For now, we'll just ensure Firebase data is up to date
      debugPrint('Syncing steps data...');
      // TODO: Implement local-to-cloud sync logic
    } catch (e) {
      debugPrint('Error syncing steps data: $e');
    }
  }

  Future<void> syncWeightData() async {
    try {
      debugPrint('Syncing weight data...');
      // TODO: Implement local-to-cloud sync logic
    } catch (e) {
      debugPrint('Error syncing weight data: $e');
    }
  }

  Future<void> syncGoalsData() async {
    try {
      debugPrint('Syncing goals data...');
      // TODO: Implement local-to-cloud sync logic
    } catch (e) {
      debugPrint('Error syncing goals data: $e');
    }
  }

  Future<void> syncProfileData() async {
    try {
      debugPrint('Syncing profile data...');
      // Profile data is already handled by ProfileService
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
