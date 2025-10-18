import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/step_tracking_controller.dart';
import '../widgets/step_counter_widget.dart';
import '../widgets/progress_ring_widget.dart';
import '../widgets/stats_card_widget.dart';
import '../widgets/step_history_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StepTrackingController>().startTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Steps Tracker',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<StepTrackingController>().refreshData();
            },
          ),
        ],
      ),
      body: Consumer<StepTrackingController>(
        builder: (context, controller, child) {
          if (controller.errorMessage?.isNotEmpty == true) {
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
                    controller.errorMessage ?? 'Unknown error',
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
                          progress: controller.progress ?? 0.0,
                          steps: controller.currentSteps ?? 0,
                          target: controller.targetSteps ?? 10000,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: StepCounterWidget(
                          currentSteps: controller.currentSteps ?? 0,
                          targetSteps: controller.targetSteps ?? 10000,
                          progress: controller.progress ?? 0.0,
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
                          value: controller.getRemainingSteps() ?? '0',
                          icon: Icons.directions_walk,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCardWidget(
                          title: 'Progress',
                          value: controller.getProgressPercentage() ?? '0%',
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StepHistoryWidget(stepHistory: controller.stepHistory ?? []),
                  
                  const SizedBox(height: 24),
                  
                  // Tracking Status
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (controller.isTracking ?? false) ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (controller.isTracking ?? false) ? Colors.green : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          (controller.isTracking ?? false) ? Icons.play_circle : Icons.pause_circle,
                          color: (controller.isTracking ?? false) ? Colors.green : Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (controller.isTracking ?? false) ? 'Tracking Active' : 'Tracking Paused',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                (controller.isTracking ?? false) 
                                  ? 'Your steps are being counted'
                                  : 'Tap to start tracking your steps',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (controller.isTracking ?? false) {
                              controller.stopTracking();
                            } else {
                              controller.startTracking();
                            }
                          },
                          icon: Icon(
                            (controller.isTracking ?? false) ? Icons.pause : Icons.play_arrow,
                            color: (controller.isTracking ?? false) ? Colors.green : Colors.orange,
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
