class StepsEntry {
  final String id;
  final String userId;
  final int steps;
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;

  StepsEntry({
    required this.id,
    required this.userId,
    required this.steps,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'steps': steps,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StepsEntry.fromMap(Map<String, dynamic> map) {
    return StepsEntry(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      steps: map['steps'] ?? 0,
      timestamp: DateTime.parse(map['timestamp']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  StepsEntry copyWith({
    String? id,
    String? userId,
    int? steps,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StepsEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      steps: steps ?? this.steps,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'StepsEntry(id: $id, steps: $steps, timestamp: $timestamp)';
  }
}
