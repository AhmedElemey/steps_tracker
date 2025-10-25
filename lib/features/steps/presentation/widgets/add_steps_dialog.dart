import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/steps_controller.dart';

class AddStepsDialog extends StatefulWidget {
  final int? initialSteps;
  final String? entryId;
  final bool isEditing;

  const AddStepsDialog({
    super.key,
    this.initialSteps,
    this.entryId,
    this.isEditing = false,
  });

  @override
  State<AddStepsDialog> createState() => _AddStepsDialogState();
}

class _AddStepsDialogState extends State<AddStepsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _stepsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialSteps != null) {
      _stepsController.text = widget.initialSteps.toString();
    }
  }

  @override
  void dispose() {
    _stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      title: Text(
        widget.isEditing ? 'Edit Steps Entry' : 'Add Steps Entry',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _stepsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Steps',
                hintText: 'Enter number of steps',
                prefixIcon: const Icon(Icons.directions_walk),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the number of steps';
                }
                final steps = int.tryParse(value);
                if (steps == null || steps <= 0) {
                  return 'Please enter a valid number of steps';
                }
                if (steps > 100000) {
                  return 'Please enter a realistic number of steps';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Consumer<StepsController>(
              builder: (context, stepsController, child) {
                if (stepsController.errorMessage.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            stepsController.errorMessage,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        Consumer<StepsController>(
          builder: (context, stepsController, child) {
            return ElevatedButton(
              onPressed: stepsController.isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: stepsController.isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(widget.isEditing ? 'Update' : 'Add'),
            );
          },
        ),
      ],
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final stepsController = context.read<StepsController>();
    final steps = int.parse(_stepsController.text.trim());
    
    bool success;
    if (widget.isEditing && widget.entryId != null) {
      success = await stepsController.updateStepsEntry(widget.entryId!, steps);
    } else {
      success = await stepsController.addStepsEntry(steps);
    }

    if (mounted) {
      // Close dialog
      Navigator.of(context).pop();
      
      // Show success/error message
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing 
                  ? 'Steps entry updated successfully'
                  : 'Steps entry added successfully',
            ),
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
  }
}
