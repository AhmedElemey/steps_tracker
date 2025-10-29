import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/services/firebase_service.dart';
import '../models/steps_entry.dart';

class StepsService {
  static final StepsService _instance = StepsService._internal();
  factory StepsService() => _instance;
  StepsService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final CollectionReference _stepsEntriesCollection = 
      FirebaseFirestore.instance.collection('steps_entries');

  Future<StepsEntry?> addStepsEntry(int steps) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final now = DateTime.now();
      final entry = StepsEntry(
        id: _stepsEntriesCollection.doc().id,
        userId: user.uid,
        steps: steps,
        timestamp: now,
        createdAt: now,
        updatedAt: now,
      );

      await _stepsEntriesCollection.doc(entry.id).set(entry.toMap());
      return entry;
    } catch (e) {
      debugPrint('Error adding steps entry: $e');
      return null;
    }
  }

  Future<StepsEntry?> updateStepsEntry(String id, int steps) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final entry = StepsEntry(
        id: id,
        userId: user.uid,
        steps: steps,
        timestamp: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _stepsEntriesCollection.doc(id).update(entry.toMap());
      return entry;
    } catch (e) {
      debugPrint('Error updating steps entry: $e');
      return null;
    }
  }

  Future<bool> deleteStepsEntry(String id) async {
    try {
      await _stepsEntriesCollection.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting steps entry: $e');
      return false;
    }
  }

  Future<List<StepsEntry>> getStepsEntries() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return [];

      QuerySnapshot querySnapshot;
      try {
        querySnapshot = await _stepsEntriesCollection
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .get();
      } catch (e) {
        debugPrint('OrderBy query failed, trying without orderBy: $e');
        querySnapshot = await _stepsEntriesCollection
            .where('userId', isEqualTo: user.uid)
            .get();
        
        final entries = querySnapshot.docs
            .map((doc) => StepsEntry.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
        
        entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return entries;
      }

      return querySnapshot.docs
          .map((doc) => StepsEntry.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting steps entries: $e');
      return [];
    }
  }

  Stream<List<StepsEntry>> getStepsEntriesStream() {
    final user = _firebaseService.currentUser;
    if (user == null) {
      debugPrint('StepsService: User is null, returning empty stream');
      return Stream.value([]);
    }

    debugPrint('StepsService: Listening to steps entries for user ${user.uid}');
    
    return _stepsEntriesCollection
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          debugPrint('StepsService: Received ${snapshot.docs.length} steps entries');
          final entries = snapshot.docs
              .map((doc) {
                try {
                  return StepsEntry.fromMap(doc.data() as Map<String, dynamic>);
                } catch (e) {
                  debugPrint('Error parsing steps entry: $e');
                  return null;
                }
              })
              .where((entry) => entry != null)
              .cast<StepsEntry>()
              .toList();
          entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return entries;
        })
        .handleError((error) {
          debugPrint('Error in steps entries stream: $error');
        });
  }

  Future<List<StepsEntry>> getHourlyStepsEntries() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return [];

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _stepsEntriesCollection
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => StepsEntry.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting hourly steps entries: $e');
      return [];
    }
  }

  Stream<List<StepsEntry>> getHourlyStepsEntriesStream() {
    final user = _firebaseService.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _stepsEntriesCollection
        .where('userId', isEqualTo: user.uid)
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StepsEntry.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }
}
