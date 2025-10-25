# Advanced Step Detection System

This document describes the advanced step detection system implemented in the Steps Tracker app, which provides accurate step counting only during actual walking motion.

## Overview

The advanced step detection system uses accelerometer data to analyze movement patterns and distinguish between actual walking and other types of movement (shaking, device orientation changes, etc.). It implements sophisticated algorithms to ensure accurate step counting.

## Key Features

### 1. Accelerometer-Based Detection
- Uses raw accelerometer data from device sensors
- Analyzes acceleration magnitude to detect step patterns
- Filters out noise and invalid movements

### 2. Peak Detection Algorithm
- Implements threshold-based peak detection
- Identifies step patterns through acceleration peaks and valleys
- Validates step timing and magnitude differences

### 3. Movement Validation
- Distinguishes walking from other activities
- Validates movement magnitude ranges
- Filters out extreme movements and device orientation changes

### 4. Time-Based Validation
- Enforces minimum and maximum step intervals
- Typical walking frequency: 1-3 steps per second
- Prevents multiple counts from single movements

### 5. Walking Pattern Recognition
- Requires consecutive steps to confirm walking
- Resets count when no consistent walking is detected
- Provides real-time feedback on walking state

### 6. User Calibration
- Calibrates detection parameters for individual users
- Analyzes user's walking characteristics
- Optimizes thresholds based on personal walking style

### 7. Sensitivity Adjustment
- Allows fine-tuning of detection sensitivity
- Adjustable from 0.0 (low sensitivity) to 1.0 (high sensitivity)
- Real-time adjustment without restarting detection

## Architecture

### Core Components

#### 1. AdvancedStepDetectionService
- Main service for step detection logic
- Handles accelerometer data processing
- Implements peak detection algorithms
- Manages walking state transitions

#### 2. StepCalibrationService
- Handles user calibration process
- Analyzes walking patterns
- Creates optimized detection configurations
- Stores user-specific profiles

#### 3. Models
- `AccelerometerData`: Raw sensor data with magnitude calculation
- `StepDetectionConfig`: Configuration parameters for detection
- `WalkingState`: Current walking state and confidence levels
- `UserStepProfile`: User-specific walking characteristics

#### 4. UI Components
- `WalkingStateWidget`: Real-time walking state display
- `CalibrationWidget`: Calibration interface and controls
- Integration with existing step tracking UI

## Detection Algorithm

### 1. Data Collection
```dart
// Collect accelerometer data
AccelerometerData data = AccelerometerData(
  x: event.x,
  y: event.y,
  z: event.z,
  timestamp: DateTime.now(),
);
```

### 2. Magnitude Calculation
```dart
// Calculate acceleration magnitude
double magnitude = sqrt(x² + y² + z²);
```

### 3. Peak Detection
```dart
// Detect peaks and valleys
bool isPeak = current > previous && current > next && current > threshold;
bool isValley = current < previous && current < next && current < threshold;
```

### 4. Step Validation
```dart
// Validate step timing and magnitude
bool isValidStep = 
  peakValleyInterval >= 50ms && peakValleyInterval <= 500ms &&
  stepInterval >= minInterval && stepInterval <= maxInterval &&
  magnitudeDifference >= 0.5;
```

### 5. Walking State Management
```dart
// Update walking state based on consecutive steps
if (consecutiveSteps >= minConsecutiveSteps) {
  state = WalkingState.walking;
} else if (consecutiveSteps > 0) {
  state = WalkingState.inconsistent;
} else {
  state = WalkingState.idle;
}
```

## Configuration Parameters

### Default Values
- **Peak Threshold**: 1.2 (adjusted by sensitivity)
- **Valley Threshold**: 0.8 (adjusted by sensitivity)
- **Min Step Interval**: 200ms (max 3 steps/second)
- **Max Step Interval**: 2000ms (min 0.5 steps/second)
- **Min Magnitude**: 9.5 (slightly below gravity)
- **Max Magnitude**: 15.0 (filters extreme movements)
- **Min Consecutive Steps**: 3 (for walking confirmation)
- **Sensitivity**: 0.5 (0.0 to 1.0 range)

### Sensitivity Adjustment
- **Low (0.0-0.3)**: Conservative detection, fewer false positives
- **Medium (0.4-0.6)**: Balanced detection (default)
- **High (0.7-1.0)**: Sensitive detection, more steps detected

## Calibration Process

### 1. Idle Phase (5 seconds)
- User holds device still
- Collects baseline acceleration data
- Calculates idle magnitude baseline

### 2. Walking Phase (15 seconds)
- User walks normally
- Collects walking acceleration data
- Analyzes step patterns and variability

### 3. Analysis Phase (2 seconds)
- Calculates user-specific parameters
- Determines walking style (light, normal, heavy, variable)
- Creates optimized configuration

### 4. Profile Creation
```dart
UserStepProfile profile = UserStepProfile(
  idleBaseline: medianIdleMagnitude,
  walkingBaseline: medianWalkingMagnitude,
  stepAmplitude: walkingBaseline - idleBaseline,
  walkingVariability: standardDeviation,
  walkingStyle: determinedStyle,
  calibrationDate: DateTime.now(),
);
```

## Walking States

### 1. Idle
- No movement detected
- Step counting paused
- Default state when not walking

### 2. Calibrating
- Calibration in progress
- Collecting user data
- Temporary state during setup

### 3. Walking
- Consistent walking pattern detected
- Steps are being counted
- High confidence in detection

### 4. Inconsistent
- Movement detected but not consistent walking
- Waiting for walking pattern
- Low confidence in detection

### 5. Paused
- Walking was detected but now paused
- Step counting suspended
- Will resume when walking detected

## Usage

### Starting Detection
```dart
// Start advanced step detection
await stepTrackingService.startTracking();

// Listen to step updates
stepTrackingService.stepsStream.listen((steps) {
  print('Steps: $steps');
});

// Listen to walking state updates
stepTrackingService.walkingStateStream.listen((state) {
  print('Walking state: ${state.state}');
});
```

### Calibration
```dart
// Start calibration
await stepTrackingService.startCalibration();

// Listen to calibration progress
stepTrackingService.calibrationProgressStream.listen((progress) {
  print('Calibration: ${progress.progress * 100}%');
});

// Listen to calibration result
stepTrackingService.calibrationResultStream.listen((result) {
  if (result.success) {
    print('Calibration completed successfully!');
  }
});
```

### Sensitivity Adjustment
```dart
// Set sensitivity (0.0 to 1.0)
stepTrackingService.setSensitivity(0.7); // High sensitivity
```

## Benefits

### 1. Accuracy
- Only counts actual walking steps
- Filters out false positives from other movements
- Reduces over-counting significantly

### 2. User-Specific
- Calibrates to individual walking patterns
- Adapts to different walking styles
- Optimizes detection for each user

### 3. Real-Time Feedback
- Provides immediate walking state information
- Shows confidence levels in detection
- Gives clear feedback on system status

### 4. Configurable
- Adjustable sensitivity levels
- Customizable detection parameters
- Easy recalibration when needed

### 5. Robust
- Handles various device orientations
- Works with different walking speeds
- Maintains accuracy across different users

## Technical Implementation

### Dependencies
- `sensors_plus`: For accelerometer data access
- `shared_preferences`: For configuration storage
- `dart:math`: For mathematical calculations

### Performance Considerations
- Efficient data buffering (50 samples)
- Optimized peak detection algorithms
- Minimal battery impact
- Real-time processing capabilities

### Error Handling
- Graceful fallback to traditional pedometer
- Comprehensive error logging
- User-friendly error messages
- Automatic recovery mechanisms

## Future Enhancements

### Potential Improvements
1. **Machine Learning**: Implement ML-based pattern recognition
2. **Multi-Sensor Fusion**: Combine accelerometer with gyroscope data
3. **Activity Recognition**: Distinguish between walking, running, and other activities
4. **Adaptive Learning**: Continuously improve detection based on user feedback
5. **Cloud Sync**: Sync calibration data across devices

### Research Areas
- Optimal buffer sizes for different devices
- Advanced filtering algorithms
- Real-time adaptation to walking changes
- Integration with health platforms

## Conclusion

The advanced step detection system provides a significant improvement over traditional pedometer-based approaches by using sophisticated algorithms to analyze accelerometer data and ensure accurate step counting only during actual walking. The system is user-friendly, highly configurable, and provides real-time feedback to users about their walking activity.

The implementation is robust, efficient, and designed to work across different devices and user walking patterns, making it a reliable solution for accurate step tracking in fitness applications.
