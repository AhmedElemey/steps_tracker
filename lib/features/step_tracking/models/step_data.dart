class StepData {
  final int id;
  final DateTime date;
  final int steps;
  final double distance; // in meters
  final int calories;
  final DateTime createdAt;
  final DateTime updatedAt;

  StepData({
    required this.id,
    required this.date,
    required this.steps,
    required this.distance,
    required this.calories,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'steps': steps,
      'distance': distance,
      'calories': calories,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory StepData.fromMap(Map<String, dynamic> map) {
    return StepData(
      id: map['id'] ?? 0,
      date: DateTime.parse(map['date']),
      steps: map['steps'] ?? 0,
      distance: map['distance']?.toDouble() ?? 0.0,
      calories: map['calories'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  StepData copyWith({
    int? id,
    DateTime? date,
    int? steps,
    double? distance,
    int? calories,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StepData(
      id: id ?? this.id,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      distance: distance ?? this.distance,
      calories: calories ?? this.calories,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'StepData(id: $id, date: $date, steps: $steps, distance: $distance, calories: $calories)';
  }
}
