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
import '../repositories/habit_repository.dart';
import '../widgets/forms/tracking_type_selector.dart';
import '../widgets/forms/goal_type_selector.dart';
import '../widgets/forms/frequency_selector.dart';
import '../widgets/forms/icon_picker.dart';
import '../widgets/forms/color_picker.dart';
import '../widgets/forms/time_window_picker.dart';
import '../widgets/forms/quality_layer_toggle.dart';
import '../widgets/forms/weekday_selector.dart';

class EditHabitScreen extends ConsumerStatefulWidget {
  final int habitId;

  const EditHabitScreen({
    super.key,
    required this.habitId,
  });

  @override
  ConsumerState<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends ConsumerState<EditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _unitController = TextEditingController();

  // Form state
  int? _selectedCategoryId;
  TrackingType _trackingType = TrackingType.binary;
  GoalType? _goalType;
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

  Habit? _originalHabit;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabit();
  }

  Future<void> _loadHabit() async {
    try {
      final repository = HabitRepository();
      final habit = await repository.getHabitById(widget.habitId);
      
      if (habit == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Habit not found'),
              backgroundColor: Colors.red,
            ),
          );
          context.pop();
        }
        return;
      }

      setState(() {
        _originalHabit = habit;
        
        // Populate form fields
        _nameController.text = habit.name;
        _descriptionController.text = habit.description ?? '';
        _selectedCategoryId = habit.categoryId;
        _trackingType = habit.trackingType;
        _goalType = habit.goalType;
        _targetValueController.text = habit.targetValue?.toString() ?? '';
        _unitController.text = habit.unit ?? '';
        _frequency = habit.frequency;
        _selectedIcon = habit.icon;
        _selectedColor = habit.color;
        
        // Advanced options
        _activeDaysMode = habit.activeDaysMode;
        _activeWeekdays = habit.activeWeekdays;
        _requireMode = habit.requireMode;
        _timeWindowEnabled = habit.timeWindowEnabled;
        _timeWindowStart = habit.timeWindowStart;
        _timeWindowEnd = habit.timeWindowEnd;
        _timeWindowMode = habit.timeWindowMode != null
            ? TimeWindowMode.values.firstWhere(
                (e) => e.name == habit.timeWindowMode,
                orElse: () => TimeWindowMode.soft,
              )
            : TimeWindowMode.soft;
        _qualityLayerEnabled = habit.qualityLayerEnabled;
        _qualityLayerLabel = habit.qualityLayerLabel;
        
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to load habit. Please try again.';
        
        if (e is HabitNotFoundException) {
          errorMessage = 'Habit not found. It may have been deleted.';
        } else if (e is HabitDatabaseException) {
          errorMessage = 'Database error. Please try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        context.pop();
      }
    }
  }

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
      // Parse target value if provided
      double? targetValue;
      if (_targetValueController.text.trim().isNotEmpty) {
        targetValue = double.tryParse(_targetValueController.text.trim());
      }

      final updatedHabit = _originalHabit!.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        categoryId: _selectedCategoryId,
        icon: _selectedIcon,
        color: _selectedColor,
        trackingType: _trackingType,
        goalType: _trackingType == TrackingType.value 
            ? (_goalType ?? GoalType.minimum)
            : GoalType.minimum,
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
      );

      await ref.read(habitsProvider.notifier).updateHabit(updatedHabit);

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        // Navigate back
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Determine error message based on exception type
        String errorMessage = 'Failed to update habit. Please try again.';
        
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

  Future<void> _deleteHabit() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: const Text(
          'Are you sure you want to delete this habit? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
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
      await ref.read(habitsProvider.notifier).archiveHabit(widget.habitId);

      if (!mounted) return;
      
      // Close loading dialog
      Navigator.of(context).pop();
      // Navigate back to habits list
      context.go('/habits');
    } catch (e) {
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Determine error message based on exception type
      String errorMessage = 'Failed to delete habit. Please try again.';
      
      if (e is HabitDatabaseException) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Habit'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Habit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteHabit,
            tooltip: 'Delete habit',
          ),
        ],
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
                  // Clear value-specific fields when switching to binary
                  if (value == TrackingType.binary) {
                    _goalType = null;
                    _targetValueController.clear();
                    _unitController.clear();
                  }
                });
              },
            ),
            if (_trackingType == TrackingType.value) ...[
              const SizedBox(height: 24),
              Text(
                'Goal Type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GoalTypeSelector(
                value: _goalType ?? GoalType.minimum,
                onChanged: (value) {
                  setState(() {
                    _goalType = value;
                  });
                },
              ),
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
                  if (_trackingType == TrackingType.value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a target value';
                    }
                    final parsedValue = double.tryParse(value.trim());
                    if (parsedValue == null) {
                      return 'Please enter a valid number';
                    }
                    if (parsedValue <= 0) {
                      return 'Target value must be greater than 0';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  hintText: 'e.g., pages, reps, km',
                  border: OutlineInputBorder(),
                  helperText: 'Enter the unit for this value (required)',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (_trackingType == TrackingType.value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a unit';
                    }
                  }
                  return null;
                },
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
              initiallyExpanded: _timeWindowEnabled || _qualityLayerEnabled || _activeDaysMode == ActiveDaysMode.selected,
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
                child: const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
