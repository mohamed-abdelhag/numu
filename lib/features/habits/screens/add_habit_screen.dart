import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/habit.dart';
import '../models/enums/tracking_type.dart';
import '../models/enums/goal_type.dart';
import '../models/enums/frequency.dart';
import '../models/enums/active_days_mode.dart';
import '../models/enums/require_mode.dart';
import '../models/enums/time_window_mode.dart';
import '../models/exceptions/habit_exception.dart';
import '../providers/habits_provider.dart';
import '../providers/categories_provider.dart';
import '../widgets/forms/tracking_type_selector.dart';
import '../widgets/forms/goal_type_selector.dart';
import '../widgets/forms/frequency_selector.dart';
import '../widgets/forms/icon_picker.dart';
import '../widgets/forms/color_picker.dart';
import '../widgets/forms/time_window_picker.dart';
import '../widgets/forms/quality_layer_toggle.dart';
import '../widgets/forms/weekday_selector.dart';

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
  int? _selectedCategoryId;
  TrackingType _trackingType = TrackingType.binary;
  GoalType _goalType = GoalType.none;
  Frequency _frequency = Frequency.daily;
  String _selectedIcon = '🎯';
  String _selectedColor = '0xFF64B5F6';
  
  // Advanced options state
  ActiveDaysMode _activeDaysMode = ActiveDaysMode.all;
  List<int>? _activeWeekdays;
  RequireMode _requireMode = RequireMode.each;
  bool _timeWindowEnabled = false;
  TimeOfDay? _timeWindowStart;
  TimeOfDay? _timeWindowEnd;
  TimeWindowMode _timeWindowMode = TimeWindowMode.soft;
  bool _qualityLayerEnabled = false;
  String? _qualityLayerLabel;

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
        categoryId: _selectedCategoryId,
        icon: _selectedIcon,
        color: _selectedColor,
        trackingType: _trackingType,
        goalType: _goalType,
        targetValue: targetValue,
        unit: _unitController.text.trim().isEmpty
            ? null
            : _unitController.text.trim(),
        frequency: _frequency,
        activeDaysMode: _activeDaysMode,
        activeWeekdays: _activeDaysMode == ActiveDaysMode.selected
            ? _activeWeekdays
            : null,
        requireMode: _requireMode,
        timeWindowEnabled: _timeWindowEnabled,
        timeWindowStart: _timeWindowEnabled ? _timeWindowStart : null,
        timeWindowEnd: _timeWindowEnabled ? _timeWindowEnd : null,
        timeWindowMode: _timeWindowEnabled ? _timeWindowMode.name : null,
        qualityLayerEnabled: _qualityLayerEnabled,
        qualityLayerLabel: _qualityLayerEnabled ? _qualityLayerLabel : null,
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
        
        // Determine error message based on exception type
        String errorMessage = 'Failed to create habit. Please try again.';
        
        if (e is HabitValidationException) {
          errorMessage = e.message;
        } else if (e is HabitDatabaseException) {
          errorMessage = 'Database error. Please try again.';
        }
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
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
              'Category (optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, child) {
                final categoriesAsync = ref.watch(categoriesProvider);
                
                return categoriesAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Text(
                    'Failed to load categories',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  data: (categories) {
                    return DropdownButtonFormField<int?>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select a category',
                      ),
                      initialValue: _selectedCategoryId,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...categories.map((category) {
                          return DropdownMenuItem<int?>(
                            value: category.id,
                            child: Row(
                              children: [
                                if (category.icon != null) ...[
                                  Text(category.icon!, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                ],
                                Text(category.name),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    );
                  },
                );
              },
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
            ExpansionTile(
              title: const Text('Advanced Options'),
              subtitle: const Text('Time windows, quality tracking, and more'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Days',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      WeekdaySelector(
                        mode: _activeDaysMode,
                        selectedWeekdays: _activeWeekdays,
                        onModeChanged: (mode) {
                          setState(() {
                            _activeDaysMode = mode;
                            if (mode == ActiveDaysMode.selected &&
                                _activeWeekdays == null) {
                              // Default to weekdays (Mon-Fri)
                              _activeWeekdays = [1, 2, 3, 4, 5];
                            }
                          });
                        },
                        onWeekdaysChanged: (weekdays) {
                          setState(() {
                            _activeWeekdays = weekdays;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Require Mode',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<RequireMode>(
                        segments: const [
                          ButtonSegment(
                            value: RequireMode.each,
                            label: Text('Each'),
                            tooltip: 'Complete on each active day',
                          ),
                          ButtonSegment(
                            value: RequireMode.any,
                            label: Text('Any'),
                            tooltip: 'Complete on any active day',
                          ),
                          ButtonSegment(
                            value: RequireMode.total,
                            label: Text('Total'),
                            tooltip: 'Reach total target across period',
                          ),
                        ],
                        selected: {_requireMode},
                        onSelectionChanged: (Set<RequireMode> selected) {
                          if (selected.isNotEmpty) {
                            setState(() {
                              _requireMode = selected.first;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _requireMode == RequireMode.each
                            ? 'Must complete the habit on each active day'
                            : _requireMode == RequireMode.any
                                ? 'Must complete on at least one active day'
                                : 'Total progress across all active days',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 24),
                      TimeWindowPicker(
                        enabled: _timeWindowEnabled,
                        startTime: _timeWindowStart,
                        endTime: _timeWindowEnd,
                        mode: _timeWindowMode,
                        onEnabledChanged: (enabled) {
                          setState(() {
                            _timeWindowEnabled = enabled;
                            if (enabled &&
                                _timeWindowStart == null &&
                                _timeWindowEnd == null) {
                              // Set default time window (e.g., 6 AM - 10 AM)
                              _timeWindowStart = const TimeOfDay(hour: 6, minute: 0);
                              _timeWindowEnd = const TimeOfDay(hour: 10, minute: 0);
                            }
                          });
                        },
                        onStartTimeChanged: (time) {
                          setState(() {
                            _timeWindowStart = time;
                          });
                        },
                        onEndTimeChanged: (time) {
                          setState(() {
                            _timeWindowEnd = time;
                          });
                        },
                        onModeChanged: (mode) {
                          setState(() {
                            _timeWindowMode = mode;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      QualityLayerToggle(
                        enabled: _qualityLayerEnabled,
                        label: _qualityLayerLabel,
                        onEnabledChanged: (enabled) {
                          setState(() {
                            _qualityLayerEnabled = enabled;
                          });
                        },
                        onLabelChanged: (label) {
                          setState(() {
                            _qualityLayerLabel = label;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
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
