import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums/streak_type.dart';
import '../repositories/habit_repository.dart';

/// Widget to display streak information for a habit
/// Shows current streak, longest streak, and consistency rate
class HabitStreakDisplay extends ConsumerWidget {
  final int habitId;
  final bool compact;
  final StreakType streakType;

  const HabitStreakDisplay({
    super.key,
    required this.habitId,
    this.compact = false,
    this.streakType = StreakType.completion,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: HabitRepository().getStreakForHabit(habitId, streakType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return compact
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return compact
              ? Text(
                  'No streak',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                )
              : const SizedBox.shrink();
        }

        final streak = snapshot.data!;

        if (compact) {
          return _buildCompactView(context, streak);
        } else {
          return _buildFullView(context, streak);
        }
      },
    );
  }

  Widget _buildCompactView(BuildContext context, dynamic streak) {
    return Row(
      children: [
        Icon(
          Icons.local_fire_department,
          size: 16,
          color: streak.currentStreak > 0
              ? Colors.orange
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          '${streak.currentStreak} ${streak.currentStreak == 1 ? 'day' : 'days'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildFullView(BuildContext context, dynamic streak) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Streak Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  icon: Icons.local_fire_department,
                  label: 'Current Streak',
                  value: '${streak.currentStreak}',
                  unit: streak.currentStreak == 1 ? 'day' : 'days',
                  iconColor: streak.currentStreak > 0 ? Colors.orange : null,
                ),
                _buildStatItem(
                  context,
                  icon: Icons.emoji_events,
                  label: 'Longest Streak',
                  value: '${streak.longestStreak}',
                  unit: streak.longestStreak == 1 ? 'day' : 'days',
                  iconColor: streak.longestStreak > 0 ? Colors.amber : null,
                ),
                _buildStatItem(
                  context,
                  icon: Icons.trending_up,
                  label: 'Consistency',
                  value: '${(streak.consistencyRate * 100).toStringAsFixed(0)}',
                  unit: '%',
                  iconColor: streak.consistencyRate > 0.7 ? Colors.green : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    Color? iconColor,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          unit,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
