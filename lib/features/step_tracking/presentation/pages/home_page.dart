import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/step_tracking_controller.dart';
import '../widgets/step_counter_widget.dart';
import '../widgets/progress_ring_widget.dart';
import '../widgets/stats_card_widget.dart';
import '../widgets/step_history_widget.dart';
import '../widgets/location_permission_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _hasShownLocationDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowLocationDialog();
    });
  }

  Future<void> _checkAndShowLocationDialog() async {
    if (_hasShownLocationDialog) return;
    
    final hasPermission = await LocationPermissionService.checkLocationPermission();
    if (!hasPermission) {
      _hasShownLocationDialog = true;
      _showLocationPermissionDialog();
    } else {
      // Start tracking if permission is already granted
      context.read<StepTrackingController>().startTracking();
    }
  }

  void _showLocationPermissionDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationPermissionDialog(
        onPermissionGranted: () {
          if (!mounted) return;
          // Start step tracking after permission is granted
          context.read<StepTrackingController>().startTracking();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission granted! Step tracking started.'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onPermissionDenied: () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required for accurate step tracking.'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Steps Tracker',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
        IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<StepTrackingController>().refreshData();
            },
          ),
          
        ],
      ),
      body: Consumer<StepTrackingController>(
        builder: (context, controller, child) {
          if (controller.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.errorMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      controller.refreshData();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await controller.refreshData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Ring and Step Counter
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ProgressRingWidget(
                          progress: controller.progress,
                          steps: controller.currentSteps,
                          target: controller.targetSteps,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: StepCounterWidget(
                          currentSteps: controller.currentSteps,
                          targetSteps: controller.targetSteps,
                          progress: controller.progress,
                          pedestrianStatus: controller.pedestrianStatus,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: StatsCardWidget(
                          title: 'Remaining',
                          value: controller.getRemainingSteps(),
                          icon: Icons.directions_walk,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: StatsCardWidget(
                          title: 'Progress',
                          value: controller.getProgressPercentage(),
                          icon: Icons.trending_up,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Step History
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StepHistoryWidget(stepHistory: controller.stepHistory),
                  
                  const SizedBox(height: 24),
                  
                  // Tracking Status
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: controller.isTracking 
                          ? Colors.green.withOpacity(0.1) 
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: controller.isTracking ? Colors.green : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          controller.isTracking ? Icons.play_circle : Icons.pause_circle,
                          color: controller.isTracking ? Colors.green : Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.isTracking ? 'Tracking Active' : 'Tracking Paused',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                controller.isTracking 
                                  ? 'Your steps are being counted'
                                  : 'Tap to start tracking your steps',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (controller.isTracking) {
                              controller.stopTracking();
                            } else {
                              controller.startTracking();
                            }
                          },
                          icon: Icon(
                            controller.isTracking ? Icons.pause : Icons.play_arrow,
                            color: controller.isTracking ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
