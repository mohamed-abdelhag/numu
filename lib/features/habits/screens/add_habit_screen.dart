import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/habit.dart';
import '../models/enums/tracking_type.dart';
import '../models/enums/goal_type.dart';
import '../models/enums/frequency.dart';
import '../models/enums/active_days_mode.dart';
import '../models/enums/require_mode.dart';
import '../providers/habits_provider.dart';
import '../widgets/forms/tracking_type_selector.dart';
import '../widgets/forms/goal_type_selector.dart';
import '../widgets/forms/frequency_selector.dart';
import '../widgets/forms/icon_picker.dart';
import '../widgets/forms/color_picker.dart';

class AddHabitScreen extends ConsumerStatefulWidget {
  const AddHabitScreen({super.key});

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _unitController = TextEditingController();

  // Form state
  TrackingType _trackingType = TrackingType.binary;
  GoalType _goalType = GoalType.none;
  Frequency _frequency = Frequency.daily;
  String _selectedIcon = '🎯';
  String _selectedColor = '0xFF64B5F6';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetValueController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final now = DateTime.now();
      
      // Parse target value if provided
      double? targetValue;
      if (_targetValueController.text.trim().isNotEmpty) {
        targetValue = double.tryParse(_targetValueController.text.trim());
      }

      final habit = Habit(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        trackingType: _trackingType,
        goalType: _goalType,
        targetValue: targetValue,
        unit: _unitController.text.trim().isEmpty
            ? null
            : _unitController.text.trim(),
        frequency: _frequency,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(habitsProvider.notifier).addHabit(habit);

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        // Navigate back to habits screen
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create habit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Habit'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Habit Name',
                hintText: 'e.g., Exercise, Read, Meditate',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a habit name';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add more details about this habit',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            Text(
              'Tracking Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TrackingTypeSelector(
              value: _trackingType,
              onChanged: (value) {
                setState(() {
                  _trackingType = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Goal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            GoalTypeSelector(
              value: _goalType,
              onChanged: (value) {
                setState(() {
                  _goalType = value;
                });
              },
            ),
            if (_goalType != GoalType.none) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetValueController,
                decoration: InputDecoration(
                  labelText: 'Target Value',
                  hintText: 'e.g., 30',
                  border: const OutlineInputBorder(),
                  suffixText: _unitController.text.trim().isEmpty
                      ? null
                      : _unitController.text.trim(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_goalType != GoalType.none &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Please enter a target value';
                  }
                  if (value != null &&
                      value.trim().isNotEmpty &&
                      double.tryParse(value.trim()) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ],
            if (_trackingType == TrackingType.value) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit (optional)',
                  hintText: 'e.g., minutes, glasses, km',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Frequency',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            FrequencySelector(
              value: _frequency,
              onChanged: (value) {
                setState(() {
                  _frequency = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Icon',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            IconPicker(
              selectedIcon: _selectedIcon,
              onIconSelected: (icon) {
                setState(() {
                  _selectedIcon = icon;
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Color',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ColorPicker(
              selectedColor: _selectedColor,
              onColorSelected: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveHabit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Habit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
