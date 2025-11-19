import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/habit_event.dart';
import '../models/enums/tracking_type.dart';
import '../models/enums/goal_type.dart';
import '../providers/habits_provider.dart';
import '../repositories/habit_repository.dart';
import 'log_habit_event_dialog.dart';

/// Quick log button for habits with smart click behavior
/// Handles different tracking types and quality tracking scenarios
class HabitQuickLogButton extends ConsumerStatefulWidget {
  final Habit habit;

  const HabitQuickLogButton({
    super.key,
    required this.habit,
  });

  @override
  ConsumerState<HabitQuickLogButton> createState() => _HabitQuickLogButtonState();
}

class _HabitQuickLogButtonState extends ConsumerState<HabitQuickLogButton> {
  final HabitRepository _repository = HabitRepository();

  @override
  Widget build(BuildContext context) {
    // Show check icon for binary habits
    if (widget.habit.trackingType == TrackingType.binary) {
      return IconButton(
        icon: const Icon(Icons.check_circle_outline),
        onPressed: () => _handleClick(context),
        tooltip: 'Mark complete',
      );
    }

    // Show plus icon for value/timed habits
    return IconButton(
      icon: const Icon(Icons.add_circle_outline),
      onPressed: () => _handleClick(context),
      tooltip: 'Log ${widget.habit.trackingType == TrackingType.value ? 'value' : 'time'}',
    );
  }

  /// Main click handler that routes to appropriate behavior based on habit configuration
  Future<void> _handleClick(BuildContext context) async {
    if (widget.habit.trackingType == TrackingType.binary) {
      if (widget.habit.qualityLayerEnabled) {
        await _handleBooleanWithQuality(context);
      } else {
        await _handleBooleanWithoutQuality(context);
      }
    } else if (widget.habit.trackingType == TrackingType.value) {
      if (widget.habit.qualityLayerEnabled) {
        await _handleCountableWithQuality(context);
      } else {
        await _handleCountableWithoutQuality(context);
      }
    } else {
      // Timed habits - show dialog
      _showLogDialog(context);
    }
  }

  /// Handle boolean habit with quality tracking (3-state)
  /// First click: mark done, Second click: mark quality, Third click: no action
  Future<void> _handleBooleanWithQuality(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    try {
      // Get today's event
      final events = await _repository.getEventsForDate(widget.habit.id!, today);
      final existingEvent = events.isNotEmpty ? events.first : null;

      if (existingEvent == null) {
        // First click: mark as done
        final event = HabitEvent(
          habitId: widget.habit.id!,
          eventDate: today,
          eventTimestamp: now,
          completed: true,
          qualityAchieved: false,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(habitsProvider.notifier).logEvent(event);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.habit.name} completed!'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (existingEvent.completed == true && existingEvent.qualityAchieved != true) {
        // Second click: mark quality as achieved
        final updatedEvent = existingEvent.copyWith(
          qualityAchieved: true,
          updatedAt: now,
        );
        await ref.read(habitsProvider.notifier).logEvent(updatedEvent);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.habit.name} quality achieved! ⭐'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
      // Third click: no action (quality already achieved)
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log habit: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Handle boolean habit without quality (done/undone with confirmation)
  /// First click: mark done, Second click: show confirmation to unmark
  Future<void> _handleBooleanWithoutQuality(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    try {
      // Get today's event
      final events = await _repository.getEventsForDate(widget.habit.id!, today);
      final existingEvent = events.isNotEmpty ? events.first : null;

      if (existingEvent == null || existingEvent.completed != true) {
        // First click: mark as done
        final event = HabitEvent(
          habitId: widget.habit.id!,
          eventDate: today,
          eventTimestamp: now,
          completed: true,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(habitsProvider.notifier).logEvent(event);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.habit.name} completed!'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Second click: show confirmation dialog to unmark
        if (context.mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Unmark Habit'),
              content: const Text('Are you sure you want to unmark this habit?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Unmark'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            // User confirmed: remove the done status
            final updatedEvent = existingEvent.copyWith(
              completed: false,
              updatedAt: now,
            );
            await ref.read(habitsProvider.notifier).logEvent(updatedEvent);
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.habit.name} unmarked'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log habit: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Handle countable habit without quality (increment with manual entry)
  /// Click increments by 1, show dialog when target reached
  Future<void> _handleCountableWithoutQuality(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    try {
      // Get today's event
      final events = await _repository.getEventsForDate(widget.habit.id!, today);
      final existingEvent = events.isNotEmpty ? events.first : null;
      
      final currentValue = existingEvent?.value ?? 0.0;
      final newValue = currentValue + 1;
      final targetValue = widget.habit.targetValue ?? 0.0;
      
      // Check if target is reached or exceeded
      final targetReached = _isTargetReached(newValue, targetValue, widget.habit.goalType);
      
      if (targetReached) {
        // Show input dialog for manual entry
        if (context.mounted) {
          final enteredValue = await showDialog<double>(
            context: context,
            builder: (context) => _CountInputDialog(
              habit: widget.habit,
              initialValue: newValue,
            ),
          );

          if (enteredValue != null) {
            final event = HabitEvent(
              habitId: widget.habit.id!,
              eventDate: today,
              eventTimestamp: now,
              value: enteredValue,
              createdAt: existingEvent?.createdAt ?? now,
              updatedAt: now,
            );
            await ref.read(habitsProvider.notifier).logEvent(event);
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.habit.name}: $enteredValue ${widget.habit.unit ?? ''}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        }
      } else {
        // Just increment by 1
        final event = HabitEvent(
          habitId: widget.habit.id!,
          eventDate: today,
          eventTimestamp: now,
          value: newValue,
          createdAt: existingEvent?.createdAt ?? now,
          updatedAt: now,
        );
        await ref.read(habitsProvider.notifier).logEvent(event);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.habit.name}: $newValue / $targetValue ${widget.habit.unit ?? ''}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log habit: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Handle countable habit with quality (increment with advanced dialog)
  /// Click increments by 1 until target, then show advanced dialog
  Future<void> _handleCountableWithQuality(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    try {
      // Get today's event
      final events = await _repository.getEventsForDate(widget.habit.id!, today);
      final existingEvent = events.isNotEmpty ? events.first : null;
      
      final currentValue = existingEvent?.value ?? 0.0;
      final newValue = currentValue + 1;
      final targetValue = widget.habit.targetValue ?? 0.0;
      
      // Check if target is reached
      final targetReached = _isTargetReached(newValue, targetValue, widget.habit.goalType);
      
      if (targetReached) {
        // Show advanced dialog with count input and quality checkbox
        if (context.mounted) {
          final result = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => _CountWithQualityDialog(
              habit: widget.habit,
              initialValue: newValue,
            ),
          );

          if (result != null) {
            final event = HabitEvent(
              habitId: widget.habit.id!,
              eventDate: today,
              eventTimestamp: now,
              value: result['value'] as double,
              qualityAchieved: result['quality'] as bool,
              createdAt: existingEvent?.createdAt ?? now,
              updatedAt: now,
            );
            await ref.read(habitsProvider.notifier).logEvent(event);
            
            if (context.mounted) {
              final qualityText = result['quality'] == true ? ' ⭐' : '';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.habit.name}: ${result['value']} ${widget.habit.unit ?? ''}$qualityText'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        }
      } else {
        // Just increment by 1
        final event = HabitEvent(
          habitId: widget.habit.id!,
          eventDate: today,
          eventTimestamp: now,
          value: newValue,
          qualityAchieved: existingEvent?.qualityAchieved ?? false,
          createdAt: existingEvent?.createdAt ?? now,
          updatedAt: now,
        );
        await ref.read(habitsProvider.notifier).logEvent(event);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.habit.name}: $newValue / $targetValue ${widget.habit.unit ?? ''}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log habit: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Check if target is reached based on goal type
  bool _isTargetReached(double currentValue, double targetValue, GoalType goalType) {
    if (goalType == GoalType.minimum) {
      return currentValue >= targetValue;
    } else if (goalType == GoalType.maximum) {
      return currentValue >= targetValue;
    }
    return false;
  }

  /// Show dialog for timed habits
  void _showLogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LogHabitEventDialog(habit: widget.habit),
    );
  }
}

/// Dialog for entering count value (without quality)
class _CountInputDialog extends StatefulWidget {
  final Habit habit;
  final double initialValue;

  const _CountInputDialog({
    required this.habit,
    required this.initialValue,
  });

  @override
  State<_CountInputDialog> createState() => _CountInputDialogState();
}

class _CountInputDialogState extends State<_CountInputDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue.toStringAsFixed(widget.initialValue.truncateToDouble() == widget.initialValue ? 0 : 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Log ${widget.habit.name}'),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Count${widget.habit.unit != null ? ' (${widget.habit.unit})' : ''}',
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final value = double.tryParse(_controller.text);
            if (value != null && value > 0) {
              Navigator.of(context).pop(value);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Dialog for entering count value with quality checkbox
class _CountWithQualityDialog extends StatefulWidget {
  final Habit habit;
  final double initialValue;

  const _CountWithQualityDialog({
    required this.habit,
    required this.initialValue,
  });

  @override
  State<_CountWithQualityDialog> createState() => _CountWithQualityDialogState();
}

class _CountWithQualityDialogState extends State<_CountWithQualityDialog> {
  late TextEditingController _controller;
  bool _qualityAchieved = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue.toStringAsFixed(widget.initialValue.truncateToDouble() == widget.initialValue ? 0 : 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Log ${widget.habit.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Count${widget.habit.unit != null ? ' (${widget.habit.unit})' : ''}',
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: Text(widget.habit.qualityLayerLabel ?? 'Quality'),
            value: _qualityAchieved,
            onChanged: (value) {
              setState(() {
                _qualityAchieved = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final value = double.tryParse(_controller.text);
            if (value != null && value > 0) {
              Navigator.of(context).pop({
                'value': value,
                'quality': _qualityAchieved,
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
