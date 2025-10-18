import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firebase_service.dart';
import '../models/step_entry.dart';

class StepsFirebaseService {
  static final StepsFirebaseService _instance = StepsFirebaseService._internal();
  factory StepsFirebaseService() => _instance;
  StepsFirebaseService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final CollectionReference _stepsCollection = 
      FirebaseFirestore.instance.collection('step_entries');

  Future<StepEntry?> createStepEntry({
    required DateTime date,
    required int steps,
    double? distance,
    double? calories,
  }) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final now = DateTime.now();
      final entryId = '${user.uid}_${date.toIso8601String().split('T')[0]}';
      
      final entry = StepEntry(
        id: entryId,
        userId: user.uid,
        date: date,
        steps: steps,
        distance: distance,
        calories: calories,
        createdAt: now,
        updatedAt: now,
      );

      await _stepsCollection.doc(entryId).set(entry.toMap());
      return entry;
    } catch (e) {
      print('Error creating step entry: $e');
      return null;
    }
  }

  Future<StepEntry?> updateStepEntry({
    required String entryId,
    int? steps,
    double? distance,
    double? calories,
  }) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final doc = await _stepsCollection.doc(entryId).get();
      if (!doc.exists) return null;

      final currentEntry = StepEntry.fromMap(doc.data() as Map<String, dynamic>);
      final updatedEntry = currentEntry.copyWith(
        steps: steps,
        distance: distance,
        calories: calories,
        updatedAt: DateTime.now(),
      );

      await _stepsCollection.doc(entryId).update(updatedEntry.toMap());
      return updatedEntry;
    } catch (e) {
      print('Error updating step entry: $e');
      return null;
    }
  }

  Future<StepEntry?> getStepEntry(DateTime date) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final entryId = '${user.uid}_${date.toIso8601String().split('T')[0]}';
      final doc = await _stepsCollection.doc(entryId).get();
      
      if (doc.exists) {
        return StepEntry.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting step entry: $e');
      return null;
    }
  }

  Future<List<StepEntry>> getStepEntries({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return [];

      Query query = _stepsCollection
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
          .map((doc) => StepEntry.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting step entries: $e');
      return [];
    }
  }

  Stream<List<StepEntry>> getStepEntriesStream({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) {
    final user = _firebaseService.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    Query query = _stepsCollection
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
          .map((doc) => StepEntry.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<bool> deleteStepEntry(String entryId) async {
    try {
      await _stepsCollection.doc(entryId).delete();
      return true;
    } catch (e) {
      print('Error deleting step entry: $e');
      return false;
    }
  }

  Future<int> getTotalStepsForDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final entries = await getStepEntries(startDate: startDate, endDate: endDate);
      return entries.fold<int>(0, (sum, entry) => sum + entry.steps);
    } catch (e) {
      print('Error getting total steps: $e');
      return 0;
    }
  }
}
