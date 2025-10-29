import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/weight_controller.dart';

class AddWeightDialog extends StatefulWidget {
  final double? initialWeight;
  final String? entryId;
  final bool isEditing;

  const AddWeightDialog({
    super.key,
    this.initialWeight,
    this.entryId,
    this.isEditing = false,
  });

  @override
  State<AddWeightDialog> createState() => _AddWeightDialogState();
}

class _AddWeightDialogState extends State<AddWeightDialog> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialWeight != null) {
      _weightController.text = widget.initialWeight.toString();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isEditing ? 'Edit Weight Entry' : 'Add Weight Entry',
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
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Weight (kg)',
                hintText: 'Enter your weight',
                prefixIcon: const Icon(Icons.monitor_weight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your weight';
                }
                final weight = double.tryParse(value);
                if (weight == null || weight <= 0) {
                  return 'Please enter a valid weight';
                }
                if (weight > 500) {
                  return 'Please enter a realistic weight';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Consumer<WeightController>(
              builder: (context, weightController, child) {
                if (weightController.errorMessage.isNotEmpty) {
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
                            weightController.errorMessage,
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
        Consumer<WeightController>(
          builder: (context, weightController, child) {
            return ElevatedButton(
              onPressed: weightController.isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: weightController.isLoading
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

    final weightController = context.read<WeightController>();
    final weight = double.parse(_weightController.text.trim());
    
    bool success;
    if (widget.isEditing && widget.entryId != null) {
      success = await weightController.updateWeightEntry(widget.entryId!, weight);
    } else {
      success = await weightController.addWeightEntry(weight);
    }

    if (mounted) {
      Navigator.of(context).pop();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing 
                  ? 'Weight entry updated successfully'
                  : 'Weight entry added successfully',
            ),
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
  }
}
