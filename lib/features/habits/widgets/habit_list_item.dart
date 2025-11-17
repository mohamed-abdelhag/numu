import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/habit.dart';
import 'habit_quick_log_button.dart';
import 'habit_streak_display.dart';

/// Widget displaying a single habit in the list
/// Shows habit icon, name, and basic information
/// Tapping navigates to the habit detail screen
class HabitListItem extends StatelessWidget {
  final Habit habit;

  const HabitListItem({
    super.key,
    required this.habit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/habits/${habit.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon with color
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(int.parse(habit.color.replaceFirst('0x', ''), radix: 16)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    habit.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Habit info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (habit.description != null && habit.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        habit.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Streak display
                    if (habit.id != null)
                      HabitStreakDisplay(
                        habitId: habit.id!,
                        compact: true,
                      ),
                  ],
                ),
              ),

              // Quick log button
              HabitQuickLogButton(habit: habit),
            ],
          ),
        ),
      ),
    );
  }
}
