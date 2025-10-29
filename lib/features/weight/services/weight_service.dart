import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/services/firebase_service.dart';
import '../models/weight_entry.dart';

class WeightService {
  static final WeightService _instance = WeightService._internal();
  factory WeightService() => _instance;
  WeightService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final CollectionReference _weightEntriesCollection = 
      FirebaseFirestore.instance.collection('weight_entries');

  Future<WeightEntry?> addWeightEntry(double weight) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('Cannot add weight entry: User is null');
        return null;
      }

      final now = DateTime.now();
      final entry = WeightEntry(
        id: _weightEntriesCollection.doc().id,
        userId: user.uid,
        weight: weight,
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      debugPrint('Adding weight entry to Firestore: userId=${user.uid}, weight=$weight');
      await _weightEntriesCollection.doc(entry.id).set(entry.toMap());
      debugPrint('Successfully added weight entry with id: ${entry.id}');
      return entry;
    } catch (e) {
      debugPrint('Error adding weight entry: $e');
      return null;
    }
  }

  Future<WeightEntry?> updateWeightEntry(String id, double weight) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final entry = WeightEntry(
        id: id,
        userId: user.uid,
        weight: weight,
        date: DateTime.now(), // Keep original date
        createdAt: DateTime.now(), // Keep original creation date
        updatedAt: DateTime.now(),
      );

      await _weightEntriesCollection.doc(id).update(entry.toMap());
      return entry;
    } catch (e) {
      debugPrint('Error updating weight entry: $e');
      return null;
    }
  }

  Future<bool> deleteWeightEntry(String id) async {
    try {
      await _weightEntriesCollection.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting weight entry: $e');
      return false;
    }
  }

  Future<List<WeightEntry>> getWeightEntries() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('Cannot get weight entries: User is null');
        return [];
      }

      debugPrint('Fetching weight entries for user: ${user.uid}');
      
      try {
        final querySnapshot = await _weightEntriesCollection
            .where('userId', isEqualTo: user.uid)
            .orderBy('date', descending: true)
            .get();

        final entries = querySnapshot.docs
            .map((doc) {
              debugPrint('Document data: ${doc.data()}');
              return WeightEntry.fromMap(doc.data() as Map<String, dynamic>);
            })
            .toList();
        
        debugPrint('Successfully fetched ${entries.length} weight entries');
        return entries;
      } catch (e) {
        debugPrint('Error with orderBy query: $e');
        debugPrint('Trying without orderBy...');
        
        final querySnapshot = await _weightEntriesCollection
            .where('userId', isEqualTo: user.uid)
            .get();

        final entries = querySnapshot.docs
            .map((doc) => WeightEntry.fromMap(doc.data() as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date)); // Sort descending by date
        
        debugPrint('Successfully fetched ${entries.length} weight entries (without Firestore orderBy)');
        return entries;
      }
    } catch (e) {
      debugPrint('Error getting weight entries: $e');
      return [];
    }
  }

  Stream<List<WeightEntry>> getWeightEntriesStream() {
    final user = _firebaseService.currentUser;
    if (user == null) {
      debugPrint('Cannot listen to weight entries: User is null');
      return Stream.value([]);
    }

    debugPrint('Listening to weight entries stream for user: ${user.uid}');
    
    return _weightEntriesCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint('Stream snapshot: ${snapshot.docs.length} documents');
          return snapshot.docs
              .map((doc) => WeightEntry.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
        })
        .handleError((error) {
          debugPrint('Stream error: $error');
          return _weightEntriesCollection
              .where('userId', isEqualTo: user.uid)
              .snapshots()
              .map((snapshot) {
                final entries = snapshot.docs
                    .map((doc) => WeightEntry.fromMap(doc.data() as Map<String, dynamic>))
                    .toList()
                  ..sort((a, b) => b.date.compareTo(a.date));
                return entries;
              });
        });
  }
}
