import '../../../core/database/database_helper.dart';
import '../models/daily_goal.dart';

class GoalsService {
  static final GoalsService _instance = GoalsService._internal();
  factory GoalsService() => _instance;
  GoalsService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<DailyGoal?> getActiveGoal() async {
    return await _databaseHelper.getActiveDailyGoal();
  }

  Future<List<DailyGoal>> getAllGoals() async {
    return await _databaseHelper.getAllDailyGoals();
  }

  Future<int> createGoal({
    required int targetSteps,
    required int targetCalories,
    required double targetDistance,
  }) async {
    final goal = DailyGoal(
      id: 0,
      targetSteps: targetSteps,
      targetCalories: targetCalories,
      targetDistance: targetDistance,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await _databaseHelper.insertDailyGoal(goal);
  }

  Future<void> updateActiveGoalSteps(int newTargetSteps) async {
    final activeGoal = await getActiveGoal();
    if (activeGoal != null) {
      final updatedGoal = activeGoal.copyWith(
        targetSteps: newTargetSteps,
        updatedAt: DateTime.now(),
      );
      await _databaseHelper.updateDailyGoal(updatedGoal);
    }
  }

  Future<void> updateActiveGoalCalories(int newTargetCalories) async {
    final activeGoal = await getActiveGoal();
    if (activeGoal != null) {
      final updatedGoal = activeGoal.copyWith(
        targetCalories: newTargetCalories,
        updatedAt: DateTime.now(),
      );
      await _databaseHelper.updateDailyGoal(updatedGoal);
    }
  }

  Future<void> updateActiveGoalDistance(double newTargetDistance) async {
    final activeGoal = await getActiveGoal();
    if (activeGoal != null) {
      final updatedGoal = activeGoal.copyWith(
        targetDistance: newTargetDistance,
        updatedAt: DateTime.now(),
      );
      await _databaseHelper.updateDailyGoal(updatedGoal);
    }
  }

  Future<void> updateGoal(DailyGoal goal) async {
    final updatedGoal = goal.copyWith(updatedAt: DateTime.now());
    await _databaseHelper.updateDailyGoal(updatedGoal);
  }

  Future<void> deleteGoal(int id) async {
    await _databaseHelper.deleteDailyGoal(id);
  }

  Future<void> deactivateAllGoals() async {
    final goals = await getAllGoals();
    for (final goal in goals) {
      if (goal.isActive) {
        final deactivatedGoal = goal.copyWith(
          isActive: false,
          updatedAt: DateTime.now(),
        );
        await _databaseHelper.updateDailyGoal(deactivatedGoal);
      }
    }
  }

  Future<void> setActiveGoal(int goalId) async {
    await deactivateAllGoals();
    
    final goals = await getAllGoals();
    final goalToActivate = goals.firstWhere((goal) => goal.id == goalId);
    final activatedGoal = goalToActivate.copyWith(
      isActive: true,
      updatedAt: DateTime.now(),
    );
    await _databaseHelper.updateDailyGoal(activatedGoal);
  }
}
