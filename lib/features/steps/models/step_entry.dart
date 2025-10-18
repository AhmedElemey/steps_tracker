class StepEntry {
  final String id;
  final String userId;
  final DateTime date;
  final int steps;
  final double? distance; // in kilometers
  final double? calories;
  final DateTime createdAt;
  final DateTime updatedAt;

  StepEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.steps,
    this.distance,
    this.calories,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'steps': steps,
      'distance': distance,
      'calories': calories,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StepEntry.fromMap(Map<String, dynamic> map) {
    return StepEntry(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date']),
      steps: map['steps'] ?? 0,
      distance: map['distance']?.toDouble(),
      calories: map['calories']?.toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  StepEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? steps,
    double? distance,
    double? calories,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StepEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
    return 'StepEntry(id: $id, date: $date, steps: $steps)';
  }
}
