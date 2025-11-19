import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/enums/tracking_type.dart';
import 'habit_quick_action_button.dart';

/// Represents the status of a habit for a specific day
class DailyHabitStatus {
  final DateTime date;
  final double progress;
  final double target;
  final int quality; // 0-5 stars
  final bool isCurrentDay;
  final bool isEmpty; // For future days or days before creation

  const DailyHabitStatus({
    required this.date,
    this.progress = 0,
    this.target = 1,
    this.quality = 0,
    this.isCurrentDay = false,
    this.isEmpty = false,
  });

  bool get isCompleted => progress >= target;
}

class HabitCard extends ConsumerWidget {
  final Habit habit;
  final List<DailyHabitStatus> weeklyProgress;
  final int score;
  final double overallProgress; // 0.0 to 1.0
  final double? todayValue; // Today's logged value for value-based habits
  final VoidCallback? onQuickActionComplete;

  const HabitCard({
    super.key,
    required this.habit,
    required this.weeklyProgress,
    this.score = 0,
    this.overallProgress = 0,
    this.todayValue,
    this.onQuickActionComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Parse habit color
    Color habitColor;
    try {
      habitColor = Color(int.parse(habit.color.replaceFirst('0x', ''), radix: 16));
    } catch (e) {
      habitColor = colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header Row
            Row(
              children: [
                // Icon Box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: habitColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      habit.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Name and Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // We don't have category name directly in Habit, assuming passed or looked up
                      // For now, just showing "Category" placeholder or omitting if not available
                      // Ideally, we should pass the Category object or name to this widget
                      Text(
                        habit.description ?? '', // Using description as subtitle for now
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Today's Value Display (for value-based habits)
                if (habit.trackingType == TrackingType.value) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: habitColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      todayValue != null && todayValue! > 0
                          ? '${todayValue!.toInt()} ${habit.unit ?? ''}'.trim()
                          : '0 ${habit.unit ?? ''}'.trim(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: habitColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Score Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE67E22).withValues(alpha: 0.2), // Orange tint
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, size: 16, color: Color(0xFFE67E22)),
                      const SizedBox(width: 4),
                      Text(
                        score.toString(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFFE67E22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Quick Action Button
                HabitQuickActionButton(
                  habit: habit,
                  date: DateTime.now(),
                  onActionComplete: onQuickActionComplete,
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // Progress Body
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Weekly Days + Indicators
                Expanded(
                  child: _buildWeeklyProgress(context, habitColor),
                ),
                
                const SizedBox(width: 16),

                // Circular Progress
                _buildCircularProgress(context, habitColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgress(BuildContext context, Color habitColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: weeklyProgress.map((status) {
        return _buildDayColumn(context, status, habitColor);
      }).toList(),
    );
  }

  Widget _buildDayColumn(BuildContext context, DailyHabitStatus status, Color habitColor) {
    final theme = Theme.of(context);
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final dayLabel = weekDays[status.date.weekday - 1];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Day Label
        Text(
          dayLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        
        // Indicator (Bar or Dot)
        if (habit.trackingType == TrackingType.value)
          _buildBarIndicator(context, status, habitColor)
        else
          _buildDotIndicator(context, status, habitColor),
          
        // Quality Stars
        if (habit.qualityLayerEnabled) ...[
          const SizedBox(height: 4),
          _buildQualityStars(context, status),
        ],
      ],
    );
  }

  Widget _buildBarIndicator(BuildContext context, DailyHabitStatus status, Color habitColor) {
    if (status.isEmpty) {
      return Container(
        width: 8,
        height: 32,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    final double fillPercent = (status.progress / status.target).clamp(0.0, 1.0);
    
    return Container(
      width: 8,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: status.isCurrentDay 
            ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1)
            : null,
      ),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: fillPercent == 0 ? 0.1 : fillPercent, // Show at least a sliver if 0 but not empty? Or just 0.
        child: Container(
          decoration: BoxDecoration(
            color: fillPercent >= 1.0 ? habitColor : habitColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildDotIndicator(BuildContext context, DailyHabitStatus status, Color habitColor) {
    if (status.isEmpty) {
       return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
      );
    }

    final bool isCompleted = status.isCompleted;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isCompleted ? habitColor : Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: status.isCurrentDay 
            ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1)
            : null,
      ),
    );
  }

  Widget _buildQualityStars(BuildContext context, DailyHabitStatus status) {
    if (status.isEmpty || status.quality == 0) {
      return const SizedBox(height: 8, width: 8); // Placeholder to keep alignment
    }
    
    // For simplicity in this small space, maybe just one star if quality > 0?
    // Or a tiny row of stars? The design shows stars under the dots.
    // Let's show a single star icon, maybe color coded or just gold.
    // Wait, user said "show stars if qulty". Plural.
    // But space is very tight under a single day column.
    // The image shows 5 stars under the text "M T W...".
    // Ah, looking at the image again (I can't see it but based on description):
    // "if qulty and value show the stars under the bars"
    // "if yes no with qulty show the stars under the dots"
    // Usually daily columns are narrow. 5 stars won't fit under one day.
    // Maybe the stars are a single star icon representing the quality rating?
    // OR, maybe the quality is a single star that is either filled or outlined?
    // Let's assume a single star icon for now that represents "quality recorded".
    
    return Icon(
      Icons.star,
      size: 10,
      color: const Color(0xFFFFD700), // Gold
    );
  }

  Widget _buildCircularProgress(BuildContext context, Color habitColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            value: overallProgress,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            color: habitColor,
            strokeWidth: 4,
          ),
        ),
        Text(
          '${(overallProgress * 100).toInt()}%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
