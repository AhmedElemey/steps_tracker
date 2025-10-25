enum WalkingState {
  idle,           // No movement detected
  calibrating,    // Calibration in progress
  walking,        // Consistent walking pattern detected
  inconsistent,   // Movement detected but not consistent walking
  paused,         // Walking was detected but now paused
}

class WalkingStateData {
  final WalkingState state;
  final DateTime timestamp;
  final int consecutiveSteps;
  final double confidence; // 0.0 to 1.0, confidence in current state
  final String? message; // Optional message for user feedback

  WalkingStateData({
    required this.state,
    required this.timestamp,
    this.consecutiveSteps = 0,
    this.confidence = 0.0,
    this.message,
  });

  WalkingStateData copyWith({
    WalkingState? state,
    DateTime? timestamp,
    int? consecutiveSteps,
    double? confidence,
    String? message,
  }) {
    return WalkingStateData(
      state: state ?? this.state,
      timestamp: timestamp ?? this.timestamp,
      consecutiveSteps: consecutiveSteps ?? this.consecutiveSteps,
      confidence: confidence ?? this.confidence,
      message: message ?? this.message,
    );
  }

  bool get isWalking => state == WalkingState.walking;
  bool get isIdle => state == WalkingState.idle;
  bool get isCalibrating => state == WalkingState.calibrating;

  @override
  String toString() {
    return 'WalkingStateData(state: $state, consecutiveSteps: $consecutiveSteps, confidence: $confidence, message: $message)';
  }
}
