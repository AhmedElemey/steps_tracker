import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/services/firebase_service.dart';
import '../models/goal.dart';

class GoalsFirebaseService {
  static final GoalsFirebaseService _instance = GoalsFirebaseService._internal();
  factory GoalsFirebaseService() => _instance;
  GoalsFirebaseService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final CollectionReference _goalsCollection = 
      FirebaseFirestore.instance.collection('goals');

  Future<Goal?> createGoal({
    required GoalType type,
    required String title,
    required String description,
    required double targetValue,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final now = DateTime.now();
      final goalId = _goalsCollection.doc().id;
      
      final goal = Goal(
        id: goalId,
        userId: user.uid,
        type: type,
        title: title,
        description: description,
        targetValue: targetValue,
        currentValue: 0.0,
        startDate: startDate,
        endDate: endDate,
        status: GoalStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      await _goalsCollection.doc(goalId).set(goal.toMap());
      return goal;
    } catch (e) {
      debugPrint('Error creating goal: $e');
      return null;
    }
  }

  Future<Goal?> updateGoal({
    required String goalId,
    String? title,
    String? description,
    double? targetValue,
    double? currentValue,
    DateTime? startDate,
    DateTime? endDate,
    GoalStatus? status,
  }) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return null;

      final doc = await _goalsCollection.doc(goalId).get();
      if (!doc.exists) return null;

      final currentGoal = Goal.fromMap(doc.data() as Map<String, dynamic>);
      final updatedGoal = currentGoal.copyWith(
        title: title,
        description: description,
        targetValue: targetValue,
        currentValue: currentValue,
        startDate: startDate,
        endDate: endDate,
        status: status,
        updatedAt: DateTime.now(),
      );

      await _goalsCollection.doc(goalId).update(updatedGoal.toMap());
      return updatedGoal;
    } catch (e) {
      debugPrint('Error updating goal: $e');
      return null;
    }
  }

  Future<Goal?> getGoal(String goalId) async {
    try {
      final doc = await _goalsCollection.doc(goalId).get();
      if (doc.exists) {
        return Goal.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting goal: $e');
      return null;
    }
  }

  Future<List<Goal>> getGoals({
    GoalType? type,
    GoalStatus? status,
    int limit = 50,
  }) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return [];

      Query query = _goalsCollection
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Goal.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting goals: $e');
      return [];
    }
  }

  Stream<List<Goal>> getGoalsStream({
    GoalType? type,
    GoalStatus? status,
    int limit = 50,
  }) {
    final user = _firebaseService.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    Query query = _goalsCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Goal.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<bool> deleteGoal(String goalId) async {
    try {
      await _goalsCollection.doc(goalId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting goal: $e');
      return false;
    }
  }

  Future<List<Goal>> getActiveGoals() async {
    return await getGoals(status: GoalStatus.active);
  }

  Future<List<Goal>> getCompletedGoals() async {
    return await getGoals(status: GoalStatus.completed);
  }

  Future<Goal?> updateGoalProgress({
    required String goalId,
    required double currentValue,
  }) async {
    try {
      final goal = await getGoal(goalId);
      if (goal == null) return null;

      GoalStatus newStatus = goal.status;
      if (currentValue >= goal.targetValue && goal.status == GoalStatus.active) {
        newStatus = GoalStatus.completed;
      }

      return await updateGoal(
        goalId: goalId,
        currentValue: currentValue,
        status: newStatus,
      );
    } catch (e) {
      debugPrint('Error updating goal progress: $e');
      return null;
    }
  }
}
