import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

class StepCounterWidget extends StatelessWidget {
  final int currentSteps;
  final int targetSteps;
  final double progress;
  final PedestrianStatus? pedestrianStatus;

  const StepCounterWidget({
    super.key,
    required this.currentSteps,
    required this.targetSteps,
    required this.progress,
    required this.pedestrianStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_walk,
                color: Color(0xFF2E7D32),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Steps Today',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatSteps(currentSteps),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'of ${_formatSteps(targetSteps)} goal',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: colorScheme.surfaceContainerHighest,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: progress >= 1.0 ? Colors.green : const Color(0xFF2E7D32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStatusColor(),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: 12,
                  color: _getStatusColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSteps(int steps) {
    return steps.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Color _getStatusColor() {
    if (pedestrianStatus == null) return Colors.grey;
    
    switch (pedestrianStatus!.status) {
      case 'walking':
        return Colors.green;
      case 'stopped':
        return Colors.orange;
      case 'unknown':
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    if (pedestrianStatus == null) return 'Unknown';
    
    switch (pedestrianStatus!.status) {
      case 'walking':
        return 'Walking';
      case 'stopped':
        return 'Stopped';
      case 'unknown':
      default:
        return 'Unknown';
    }
  }
}
