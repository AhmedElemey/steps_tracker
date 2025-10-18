import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/services/firebase_service.dart';
import '../models/weight_entry.dart';

class WeightFirebaseService {
  static final WeightFirebaseService _instance = WeightFirebaseService._internal();
  factory WeightFirebaseService() => _instance;
  WeightFirebaseService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final CollectionReference _weightCollection = 
      FirebaseFirestore.instance.collection('weight_entries');

  Future<WeightEntry?> createWeightEntry({
    required DateTime date,
    required double weight,
    String? notes,
  }) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final now = DateTime.now();
      final entryId = '${user.uid}_${date.toIso8601String().split('T')[0]}';
      
      final entry = WeightEntry(
        id: entryId,
        userId: user.uid,
        date: date,
        weight: weight,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      await _weightCollection.doc(entryId).set(entry.toMap());
      return entry;
    } catch (e) {
      debugPrint('Error creating weight entry: $e');
      return null;
    }
  }

  Future<WeightEntry?> updateWeightEntry({
    required String entryId,
    double? weight,
    String? notes,
  }) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final doc = await _weightCollection.doc(entryId).get();
      if (!doc.exists) return null;

      final currentEntry = WeightEntry.fromMap(doc.data() as Map<String, dynamic>);
      final updatedEntry = currentEntry.copyWith(
        weight: weight,
        notes: notes,
        updatedAt: DateTime.now(),
      );

      await _weightCollection.doc(entryId).update(updatedEntry.toMap());
      return updatedEntry;
    } catch (e) {
      debugPrint('Error updating weight entry: $e');
      return null;
    }
  }

  Future<WeightEntry?> getWeightEntry(DateTime date) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final entryId = '${user.uid}_${date.toIso8601String().split('T')[0]}';
      final doc = await _weightCollection.doc(entryId).get();
      
      if (doc.exists) {
        return WeightEntry.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting weight entry: $e');
      return null;
    }
  }

  Future<List<WeightEntry>> getWeightEntries({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return [];

      Query query = _weightCollection
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => WeightEntry.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting weight entries: $e');
      return [];
    }
  }

  Stream<List<WeightEntry>> getWeightEntriesStream({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) {
    final user = _firebaseService.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    Query query = _weightCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .limit(limit);

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: endDate.toIso8601String());
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => WeightEntry.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<bool> deleteWeightEntry(String entryId) async {
    try {
      await _weightCollection.doc(entryId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting weight entry: $e');
      return false;
    }
  }

  Future<WeightEntry?> getLatestWeightEntry() async {
    try {
      final entries = await getWeightEntries(limit: 1);
      return entries.isNotEmpty ? entries.first : null;
    } catch (e) {
      debugPrint('Error getting latest weight entry: $e');
      return null;
    }
  }

  Future<double> getWeightChange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startEntry = await getWeightEntry(startDate);
      final endEntry = await getWeightEntry(endDate);
      
      if (startEntry == null || endEntry == null) return 0.0;
      
      return endEntry.weight - startEntry.weight;
    } catch (e) {
      debugPrint('Error calculating weight change: $e');
      return 0.0;
    }
  }
}
