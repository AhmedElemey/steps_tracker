import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/steps_controller.dart';
import '../widgets/add_steps_dialog.dart';

class StepsEntriesPage extends StatelessWidget {
  const StepsEntriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Steps Entries',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddStepsDialog(context),
            icon: const Icon(Icons.add),
            tooltip: 'Add Steps Entry',
          ),
        ],
      ),
      body: Consumer<StepsController>(
        builder: (context, stepsController, child) {
          if (stepsController.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            );
          }

          if (stepsController.stepsEntries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_walk_outlined,
                    size: 64,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No steps entries yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first steps entry to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddStepsDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Steps Entry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stepsController.stepsEntries.length,
            itemBuilder: (context, index) {
              final entry = stepsController.stepsEntries[index];
              return _buildStepsEntryCard(context, entry);
            },
          );
        },
      ),
    );
  }

  Widget _buildStepsEntryCard(BuildContext context, dynamic entry) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.directions_walk,
            color: colorScheme.primary,
          ),
        ),
        title: Text(
          '${_formatSteps(entry.steps)} steps',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy - HH:mm').format(entry.timestamp),
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditStepsDialog(context, entry);
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, entry);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }
    return steps.toString();
  }

  void _showAddStepsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddStepsDialog(),
    );
  }

  void _showEditStepsDialog(BuildContext context, dynamic entry) {
    showDialog(
      context: context,
      builder: (context) => AddStepsDialog(
        initialSteps: entry.steps,
        entryId: entry.id,
        isEditing: true,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, dynamic entry) {
    showDialog(
      context: context,
      builder: (context) => Consumer<StepsController>(
        builder: (context, stepsController, child) {
          return AlertDialog(
            title: const Text('Delete Steps Entry'),
            content: Text('Are you sure you want to delete this entry of ${_formatSteps(entry.steps)} steps?'),
            actions: [
              TextButton(
                onPressed: stepsController.isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: stepsController.isLoading ? null : () async {
                  final success = await stepsController.deleteStepsEntry(entry.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Steps entry deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else if (stepsController.errorMessage.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(stepsController.errorMessage),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: stepsController.isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );
  }
}
