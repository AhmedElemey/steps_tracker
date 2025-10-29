import 'package:flutter/foundation.dart';
import '../models/goal.dart';
import '../services/goals_firebase_service.dart';

class GoalsController extends ChangeNotifier {
  final GoalsFirebaseService _goalsService = GoalsFirebaseService();

  List<Goal> _goals = [];
  List<Goal> _activeGoals = [];
  List<Goal> _completedGoals = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Goal> get goals => _goals;
  List<Goal> get activeGoals => _activeGoals;
  List<Goal> get completedGoals => _completedGoals;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  GoalsController() {
    _initialize();
  }

  void _initialize() {
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      _isLoading = true;
      notifyListeners();

      final allGoals = await _goalsService.getGoals();
      _goals = allGoals;
      _activeGoals = allGoals.where((goal) => goal.status == GoalStatus.active).toList();
      _completedGoals = allGoals.where((goal) => goal.status == GoalStatus.completed).toList();

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading goals: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGoal({
    required GoalType type,
    required String title,
    required String description,
    required double targetValue,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      final goal = await _goalsService.createGoal(
        type: type,
        title: title,
        description: description,
        targetValue: targetValue,
        startDate: startDate,
        endDate: endDate,
      );

      if (goal != null) {
        _goals.insert(0, goal);
        _activeGoals.insert(0, goal);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to create goal';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error creating goal: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateGoal({
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
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      final updatedGoal = await _goalsService.updateGoal(
        goalId: goalId,
        title: title,
        description: description,
        targetValue: targetValue,
        currentValue: currentValue,
        startDate: startDate,
        endDate: endDate,
        status: status,
      );

      if (updatedGoal != null) {
        final index = _goals.indexWhere((goal) => goal.id == goalId);
        if (index != -1) {
          _goals[index] = updatedGoal;
        }

        _activeGoals = _goals.where((goal) => goal.status == GoalStatus.active).toList();
        _completedGoals = _goals.where((goal) => goal.status == GoalStatus.completed).toList();

        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to update goal';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating goal: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateGoalProgress({
    required String goalId,
    required double currentValue,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      final updatedGoal = await _goalsService.updateGoalProgress(
        goalId: goalId,
        currentValue: currentValue,
      );

      if (updatedGoal != null) {
        final index = _goals.indexWhere((goal) => goal.id == goalId);
        if (index != -1) {
          _goals[index] = updatedGoal;
        }

        _activeGoals = _goals.where((goal) => goal.status == GoalStatus.active).toList();
        _completedGoals = _goals.where((goal) => goal.status == GoalStatus.completed).toList();

        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to update goal progress';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating goal progress: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteGoal(String goalId) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      final success = await _goalsService.deleteGoal(goalId);
      if (success) {
        _goals.removeWhere((goal) => goal.id == goalId);
        _activeGoals.removeWhere((goal) => goal.id == goalId);
        _completedGoals.removeWhere((goal) => goal.id == goalId);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to delete goal';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error deleting goal: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshGoals() async {
    await _loadGoals();
  }

  Goal? getGoalById(String goalId) {
    try {
      return _goals.firstWhere((goal) => goal.id == goalId);
    } catch (e) {
      return null;
    }
  }

  List<Goal> getGoalsByType(GoalType type) {
    return _goals.where((goal) => goal.type == type).toList();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
