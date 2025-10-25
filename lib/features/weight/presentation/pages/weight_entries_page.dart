import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/weight_controller.dart';
import '../widgets/add_weight_dialog.dart';

class WeightEntriesPage extends StatelessWidget {
  const WeightEntriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Weight Entries',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddWeightDialog(context),
            icon: const Icon(Icons.add),
            tooltip: 'Add Weight Entry',
          ),
        ],
      ),
      body: Consumer<WeightController>(
        builder: (context, weightController, child) {
          if (weightController.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            );
          }

          if (weightController.weightEntries.isEmpty) {
                          return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monitor_weight_outlined,
                      size: 64,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No weight entries yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first weight entry to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddWeightDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Weight Entry'),
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
            itemCount: weightController.weightEntries.length,
            itemBuilder: (context, index) {
              final entry = weightController.weightEntries[index];
              return _buildWeightEntryCard(context, entry);
            },
          );
        },
      ),
    );
  }

  Widget _buildWeightEntryCard(BuildContext context, dynamic entry) {
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
            Icons.monitor_weight,
            color: colorScheme.primary,
          ),
        ),
        title: Text(
          '${entry.weight.toStringAsFixed(1)} kg',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy - HH:mm').format(entry.date),
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditWeightDialog(context, entry);
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

  void _showAddWeightDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddWeightDialog(),
    );
  }

  void _showEditWeightDialog(BuildContext context, dynamic entry) {
    showDialog(
      context: context,
      builder: (context) => AddWeightDialog(
        initialWeight: entry.weight,
        entryId: entry.id,
        isEditing: true,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, dynamic entry) {
    showDialog(
      context: context,
      builder: (context) => Consumer<WeightController>(
        builder: (context, weightController, child) {
          return AlertDialog(
            title: const Text('Delete Weight Entry'),
            content: Text('Are you sure you want to delete this weight entry of ${entry.weight.toStringAsFixed(1)} kg?'),
            actions: [
              TextButton(
                onPressed: weightController.isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: weightController.isLoading ? null : () async {
                  final success = await weightController.deleteWeightEntry(entry.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Weight entry deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else if (weightController.errorMessage.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(weightController.errorMessage),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: weightController.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
