import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/habit_event.dart';
import '../models/enums/tracking_type.dart';
import '../providers/habits_provider.dart';

/// Quick log button for habits
/// Shows check icon for binary habits with quick log functionality
/// Shows plus icon for value/timed habits that opens a dialog
class HabitQuickLogButton extends ConsumerWidget {
  final Habit habit;

  const HabitQuickLogButton({
    super.key,
    required this.habit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show check icon for binary habits
    if (habit.trackingType == TrackingType.binary) {
      return IconButton(
        icon: const Icon(Icons.check_circle_outline),
        onPressed: () => _quickLogBinary(ref, context),
        tooltip: 'Mark complete',
      );
    }

    // Show plus icon for value/timed habits
    return IconButton(
      icon: const Icon(Icons.add_circle_outline),
      onPressed: () => _showLogDialog(context, ref),
      tooltip: 'Log ${habit.trackingType == TrackingType.value ? 'value' : 'time'}',
    );
  }

  /// Quick log for binary habits - creates an event with completed=true for today
  Future<void> _quickLogBinary(WidgetRef ref, BuildContext context) async {
    final now = DateTime.now();
    final event = HabitEvent(
      habitId: habit.id!,
      eventDate: DateTime(now.year, now.month, now.day),
      eventTimestamp: now,
      completed: true,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await ref.read(habitsProvider.notifier).logEvent(event);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${habit.name} completed!'),
            duration: const Duration(seconds: 2),
          ),
        );
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

  /// Show dialog for value/timed habits
  /// TODO: Implement LogHabitEventDialog in Phase 2 (task 10.1)
  void _showLogDialog(BuildContext context, WidgetRef ref) {
    // Placeholder for LogHabitEventDialog
    // This will be implemented in Phase 2 when the dialog is created
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Log dialog for ${habit.name} - Coming in Phase 2'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
