import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/goals_controller.dart';
import '../../models/goal.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoalsController>().refreshGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateGoalDialog(context),
          ),
        ],
      ),
      body: Consumer<GoalsController>(
        builder: (context, goalsController, child) {
          if (goalsController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (goalsController.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    goalsController.errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => goalsController.refreshGoals(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (goalsController.goals.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No goals yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your first goal to start tracking your progress',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Color(0xFF2E7D32),
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'Active'),
                    Tab(text: 'Completed'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildGoalsList(goalsController.activeGoals, goalsController),
                      _buildGoalsList(goalsController.completedGoals, goalsController),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalsList(List<Goal> goals, GoalsController controller) {
    if (goals.isEmpty) {
      return const Center(
        child: Text(
          'No goals in this category',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              goal.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.description),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: goal.progressPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    goal.isCompleted ? Colors.green : const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${goal.currentValue.toStringAsFixed(0)} / ${goal.targetValue.toStringAsFixed(0)} (${goal.progressPercentage.toStringAsFixed(1)}%)',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: const Text('Edit'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: const Text('Delete'),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditGoalDialog(context, goal, controller);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, goal, controller);
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showCreateGoalDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final targetController = TextEditingController();
    GoalType selectedType = GoalType.steps;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Goal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GoalType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: GoalType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) selectedType = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetController,
                decoration: const InputDecoration(
                  labelText: 'Target Value',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty &&
                  targetController.text.isNotEmpty) {
                context.read<GoalsController>().createGoal(
                  type: selectedType,
                  title: titleController.text,
                  description: descriptionController.text,
                  targetValue: double.parse(targetController.text),
                  startDate: startDate,
                  endDate: endDate,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, Goal goal, GoalsController controller) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon!')),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Goal goal, GoalsController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteGoal(goal.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
