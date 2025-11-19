import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums/frequency.dart';
import '../models/enums/goal_type.dart';
import '../repositories/habit_repository.dart';

/// Widget that displays progress for weekly/monthly habits
/// Shows a progress bar and "X/Y" text indicating completion status
class HabitProgressIndicator extends ConsumerWidget {
  final int habitId;

  const HabitProgressIndicator({
    super.key,
    required this.habitId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: _loadProgressData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 20,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        
        // Don't show progress for daily habits
        if (data['frequency'] == Frequency.daily) {
          return const SizedBox.shrink();
        }

        final currentValue = data['currentValue'] as double;
        final targetValue = data['targetValue'] as double;
        final unit = data['unit'] as String?;
        final frequency = data['frequency'] as Frequency;
        final goalType = data['goalType'] as GoalType;

        // Calculate progress percentage based on goal type
        final progress = _calculateProgress(currentValue, targetValue, goalType);

        // Format display text
        String displayText;
        if (unit != null && unit.isNotEmpty) {
          // For value-based habits (e.g., "8/10 km")
          displayText = '${currentValue.toStringAsFixed(currentValue.truncateToDouble() == currentValue ? 0 : 1)}/${targetValue.toStringAsFixed(targetValue.truncateToDouble() == targetValue ? 0 : 1)} $unit';
        } else {
          // For day-based habits (e.g., "3/5 days")
          displayText = '${currentValue.toInt()}/${targetValue.toInt()} days';
        }

        // Add frequency context
        final frequencyLabel = frequency == Frequency.weekly ? 'this week' : 'this month';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                Text(
                  frequencyLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Calculate progress based on goal type
  /// For minimum goals: progress = (current / target)
  /// For maximum goals: progress = (target - current) / target
  double _calculateProgress(double currentValue, double targetValue, GoalType goalType) {
    if (targetValue <= 0) return 0.0;
    
    if (goalType == GoalType.minimum) {
      // For minimum goals, progress increases as current approaches target
      return (currentValue / targetValue).clamp(0.0, 1.0);
    } else if (goalType == GoalType.maximum) {
      // For maximum goals, progress is 1.0 when current is 0, and decreases as current approaches target
      // If current exceeds target, progress becomes negative (clamped to 0)
      return ((targetValue - currentValue) / targetValue).clamp(0.0, 1.0);
    }
    
    // Default to minimum behavior for GoalType.none
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  /// Load progress data for the habit
  Future<Map<String, dynamic>> _loadProgressData() async {
    final repository = HabitRepository();
    
    // Get habit details
    final habit = await repository.getHabitById(habitId);
    if (habit == null) {
      throw Exception('Habit not found');
    }

    // Get current period progress
    final periodProgress = await repository.getCurrentPeriodProgress(habitId);

    return {
      'frequency': habit.frequency,
      'currentValue': periodProgress?.currentValue ?? 0.0,
      'targetValue': periodProgress?.targetValue ?? habit.targetValue ?? 0.0,
      'unit': habit.unit,
      'goalType': habit.goalType,
    };
  }
}
