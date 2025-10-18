class WeightEntry {
  final String id;
  final String userId;
  final DateTime date;
  final double weight; // in kg
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  WeightEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.weight,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'weight': weight,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date']),
      weight: map['weight']?.toDouble() ?? 0.0,
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  WeightEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? weight,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'WeightEntry(id: $id, date: $date, weight: $weight)';
  }
}