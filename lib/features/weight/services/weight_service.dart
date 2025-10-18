import 'package:cloud_firestore/cloud_firestore.dart';
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
      if (user == null) return null;

      final now = DateTime.now();
      final entry = WeightEntry(
        id: _weightEntriesCollection.doc().id,
        userId: user.uid,
        weight: weight,
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      await _weightEntriesCollection.doc(entry.id).set(entry.toMap());
      return entry;
    } catch (e) {
      print('Error adding weight entry: $e');
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
      print('Error updating weight entry: $e');
      return null;
    }
  }

  Future<bool> deleteWeightEntry(String id) async {
    try {
      await _weightEntriesCollection.doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting weight entry: $e');
      return false;
    }
  }

  Future<List<WeightEntry>> getWeightEntries() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return [];

      final querySnapshot = await _weightEntriesCollection
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => WeightEntry.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting weight entries: $e');
      return [];
    }
  }

  Stream<List<WeightEntry>> getWeightEntriesStream() {
    final user = _firebaseService.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _weightEntriesCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WeightEntry.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }
}
