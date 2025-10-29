class StepDetectionConfig {
  final double peakThreshold;
  final double valleyThreshold;
  
  final int minStepIntervalMs; // Minimum time between steps (ms)
  final int maxStepIntervalMs; // Maximum time between steps (ms)
  
  final double minMagnitudeThreshold; // Minimum acceleration magnitude for valid movement
  final double maxMagnitudeThreshold; // Maximum acceleration magnitude (filters out extreme movements)
  
  final int minConsecutiveSteps; // Minimum consecutive steps to consider as walking
  final int maxStepsWithoutWalking; // Reset count if no walking detected for this many steps
  
  final double sensitivity; // 0.0 to 1.0, affects threshold calculations
  
  final bool isCalibrated;
  final double userBaselineMagnitude; // User's baseline acceleration magnitude

  const StepDetectionConfig({
    this.peakThreshold = 0.3, // Much more sensitive peak detection
    this.valleyThreshold = 0.2, // Much more sensitive valley detection
    this.minStepIntervalMs = 200, // ~3 steps per second max (faster walking allowed)
    this.maxStepIntervalMs = 3000, // ~0.33 steps per second min (very slow walking)
    this.minMagnitudeThreshold = 7.0, // More lenient for different devices
    this.maxMagnitudeThreshold = 25.0, // More lenient for different devices
    this.minConsecutiveSteps = 1, // Count individual steps immediately
    this.maxStepsWithoutWalking = 10,
    this.sensitivity = 0.9, // Very sensitive by default for better detection
    this.isCalibrated = false,
    this.userBaselineMagnitude = 9.81, // Standard gravity
  });

  StepDetectionConfig copyWith({
    double? peakThreshold,
    double? valleyThreshold,
    int? minStepIntervalMs,
    int? maxStepIntervalMs,
    double? minMagnitudeThreshold,
    double? maxMagnitudeThreshold,
    int? minConsecutiveSteps,
    int? maxStepsWithoutWalking,
    double? sensitivity,
    bool? isCalibrated,
    double? userBaselineMagnitude,
  }) {
    return StepDetectionConfig(
      peakThreshold: peakThreshold ?? this.peakThreshold,
      valleyThreshold: valleyThreshold ?? this.valleyThreshold,
      minStepIntervalMs: minStepIntervalMs ?? this.minStepIntervalMs,
      maxStepIntervalMs: maxStepIntervalMs ?? this.maxStepIntervalMs,
      minMagnitudeThreshold: minMagnitudeThreshold ?? this.minMagnitudeThreshold,
      maxMagnitudeThreshold: maxMagnitudeThreshold ?? this.maxMagnitudeThreshold,
      minConsecutiveSteps: minConsecutiveSteps ?? this.minConsecutiveSteps,
      maxStepsWithoutWalking: maxStepsWithoutWalking ?? this.maxStepsWithoutWalking,
      sensitivity: sensitivity ?? this.sensitivity,
      isCalibrated: isCalibrated ?? this.isCalibrated,
      userBaselineMagnitude: userBaselineMagnitude ?? this.userBaselineMagnitude,
    );
  }

  double get adjustedPeakThreshold => peakThreshold + (sensitivity - 0.5) * 0.4;
  double get adjustedValleyThreshold => valleyThreshold + (sensitivity - 0.5) * 0.2;
  double get adjustedMinMagnitude => minMagnitudeThreshold + (sensitivity - 0.5) * 0.5;
  double get adjustedMaxMagnitude => maxMagnitudeThreshold + (sensitivity - 0.5) * 1.0;

  @override
  String toString() {
    return 'StepDetectionConfig(peakThreshold: $peakThreshold, valleyThreshold: $valleyThreshold, sensitivity: $sensitivity, isCalibrated: $isCalibrated)';
  }
}
