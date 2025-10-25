class StepDetectionConfig {
  // Peak detection thresholds
  final double peakThreshold;
  final double valleyThreshold;
  
  // Time-based validation
  final int minStepIntervalMs; // Minimum time between steps (ms)
  final int maxStepIntervalMs; // Maximum time between steps (ms)
  
  // Movement validation
  final double minMagnitudeThreshold; // Minimum acceleration magnitude for valid movement
  final double maxMagnitudeThreshold; // Maximum acceleration magnitude (filters out extreme movements)
  
  // Walking pattern validation
  final int minConsecutiveSteps; // Minimum consecutive steps to consider as walking
  final int maxStepsWithoutWalking; // Reset count if no walking detected for this many steps
  
  // Sensitivity adjustment
  final double sensitivity; // 0.0 to 1.0, affects threshold calculations
  
  // Calibration
  final bool isCalibrated;
  final double userBaselineMagnitude; // User's baseline acceleration magnitude

  const StepDetectionConfig({
    this.peakThreshold = 0.8,
    this.valleyThreshold = 0.6,
    this.minStepIntervalMs = 300, // ~2 steps per second max (more realistic)
    this.maxStepIntervalMs = 1500, // ~0.67 steps per second min
    this.minMagnitudeThreshold = 8.5, // More lenient for different devices
    this.maxMagnitudeThreshold = 18.0, // More lenient for different devices
    this.minConsecutiveSteps = 2, // Lower threshold for faster detection
    this.maxStepsWithoutWalking = 8,
    this.sensitivity = 0.6, // Slightly more sensitive by default
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

  // Calculate adjusted thresholds based on sensitivity
  double get adjustedPeakThreshold => peakThreshold + (sensitivity - 0.5) * 0.4;
  double get adjustedValleyThreshold => valleyThreshold + (sensitivity - 0.5) * 0.2;
  double get adjustedMinMagnitude => minMagnitudeThreshold + (sensitivity - 0.5) * 0.5;
  double get adjustedMaxMagnitude => maxMagnitudeThreshold + (sensitivity - 0.5) * 1.0;

  @override
  String toString() {
    return 'StepDetectionConfig(peakThreshold: $peakThreshold, valleyThreshold: $valleyThreshold, sensitivity: $sensitivity, isCalibrated: $isCalibrated)';
  }
}
