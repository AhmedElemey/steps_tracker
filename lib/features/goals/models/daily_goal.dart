class DailyGoal {
  final int id;
  final int targetSteps;
  final int targetCalories;
  final double targetDistance; // in meters
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyGoal({
    required this.id,
    required this.targetSteps,
    required this.targetCalories,
    required this.targetDistance,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'target_steps': targetSteps,
      'target_calories': targetCalories,
      'target_distance': targetDistance,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DailyGoal.fromMap(Map<String, dynamic> map) {
    return DailyGoal(
      id: map['id'] ?? 0,
      targetSteps: map['target_steps'] ?? 10000,
      targetCalories: map['target_calories'] ?? 500,
      targetDistance: map['target_distance']?.toDouble() ?? 8000.0,
      isActive: (map['is_active'] ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  DailyGoal copyWith({
    int? id,
    int? targetSteps,
    int? targetCalories,
    double? targetDistance,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyGoal(
      id: id ?? this.id,
      targetSteps: targetSteps ?? this.targetSteps,
      targetCalories: targetCalories ?? this.targetCalories,
      targetDistance: targetDistance ?? this.targetDistance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'DailyGoal(id: $id, targetSteps: $targetSteps, targetCalories: $targetCalories, targetDistance: $targetDistance, isActive: $isActive)';
  }
}
