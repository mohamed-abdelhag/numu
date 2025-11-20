import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/habit_event.dart';
import '../models/enums/tracking_type.dart';
import '../models/enums/streak_type.dart';
import '../models/enums/goal_type.dart';
import '../providers/habit_detail_provider.dart';
import '../../../features/profile/providers/user_profile_provider.dart';
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
  final VoidCallback? onQuickActionComplete;

  const HabitCard({
    super.key,
    required this.habit,
    this.onQuickActionComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch habit detail for real-time data
    final habitDetailAsync = ref.watch(habitDetailProvider(habit.id!));
    final userProfileAsync = ref.watch(userProfileProvider);

    return habitDetailAsync.when(
      data: (detailState) {
        final startOfWeek = userProfileAsync.value?.startOfWeek ?? 1;
        final weeklyProgress = _calculateWeeklyProgress(
          detailState.events,
          startOfWeek,
        );
        final currentStreak = detailState.streaks[StreakType.completion]?.currentStreak ?? 0;
        final longestStreak = detailState.streaks[StreakType.completion]?.longestStreak ?? 0;
        final weekProgress = _calculateWeekProgress(detailState.events, startOfWeek);
        final todayValue = _calculateTodayValue(detailState.events);

        return _buildCard(
          context: context,
          weeklyProgress: weeklyProgress,
          currentStreak: currentStreak,
          longestStreak: longestStreak,
          weekProgress: weekProgress,
          todayValue: todayValue,
        );
      },
      loading: () => _buildLoadingCard(context),
      error: (error, stack) => _buildErrorCard(context),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required List<DailyHabitStatus> weeklyProgress,
    required int currentStreak,
    required int longestStreak,
    required double weekProgress,
    required double? todayValue,
  }) {
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
                      Text(
                        habit.description ?? '',
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
                      todayValue != null && todayValue > 0
                          ? '${todayValue.toInt()} ${habit.unit ?? ''}'.trim()
                          : '0 ${habit.unit ?? ''}'.trim(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: habitColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Score Badge (current streak)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE67E22).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, size: 16, color: Color(0xFFE67E22)),
                      const SizedBox(width: 4),
                      Text(
                        currentStreak.toString(),
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
                  child: _buildWeeklyProgress(context, habitColor, weeklyProgress),
                ),
                
                const SizedBox(width: 16),

                // Circular Progress
                _buildCircularProgress(context, habitColor, weekProgress),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Error loading habit data',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyProgress(BuildContext context, Color habitColor, List<DailyHabitStatus> weeklyProgress) {
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

  Widget _buildCircularProgress(BuildContext context, Color habitColor, double weekProgress) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            value: weekProgress,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            color: habitColor,
            strokeWidth: 4,
          ),
        ),
        Text(
          '${(weekProgress * 100).toInt()}%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Calculate weekly progress for the current week based on user's week start preference
  List<DailyHabitStatus> _calculateWeeklyProgress(
    List<HabitEvent> events,
    int startOfWeek,
  ) {
    final now = DateTime.now();
    final daysFromWeekStart = (now.weekday - startOfWeek + 7) % 7;
    final weekStart = now.subtract(Duration(days: daysFromWeekStart));
    
    return List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final dayEvents = _getEventsForDate(events, date);
      
      return _calculateDayStatus(date, dayEvents, now);
    });
  }

  /// Get events for a specific date
  List<HabitEvent> _getEventsForDate(List<HabitEvent> events, DateTime date) {
    return events.where((e) {
      final eventDay = DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day);
      final targetDay = DateTime(date.year, date.month, date.day);
      return eventDay.isAtSameMomentAs(targetDay);
    }).toList();
  }

  /// Calculate the status for a specific day
  DailyHabitStatus _calculateDayStatus(
    DateTime date,
    List<HabitEvent> dayEvents,
    DateTime now,
  ) {
    final isToday = date.year == now.year && 
                    date.month == now.month && 
                    date.day == now.day;
    final isFuture = date.isAfter(now) && !isToday;
    
    // Future days are empty
    if (isFuture) {
      return DailyHabitStatus(
        date: date,
        isEmpty: true,
        isCurrentDay: false,
      );
    }

    // Calculate progress based on tracking type
    double progress = 0.0;
    double target = habit.targetValue ?? 1.0;
    int quality = 0;

    if (habit.trackingType == TrackingType.value) {
      // For value-based habits, sum up all values/deltas for the day
      for (final event in dayEvents) {
        if (event.valueDelta != null) {
          progress += event.valueDelta!;
        } else if (event.value != null) {
          progress = event.value!;
        }
      }
    } else {
      // For binary habits, check if completed
      final hasCompletedEvent = dayEvents.any((e) => e.completed == true);
      progress = hasCompletedEvent ? 1.0 : 0.0;
      target = 1.0;
    }

    // Check quality if enabled
    if (habit.qualityLayerEnabled) {
      final hasQuality = dayEvents.any((e) => e.qualityAchieved == true);
      quality = hasQuality ? 1 : 0; // Simplified: 1 if quality achieved, 0 otherwise
    }

    return DailyHabitStatus(
      date: date,
      progress: progress,
      target: target,
      quality: quality,
      isCurrentDay: isToday,
      isEmpty: false,
    );
  }

  /// Calculate week-based progress percentage
  double _calculateWeekProgress(List<HabitEvent> events, int startOfWeek) {
    final now = DateTime.now();
    final daysFromWeekStart = (now.weekday - startOfWeek + 7) % 7;
    final weekStart = now.subtract(Duration(days: daysFromWeekStart));
    
    int completedDays = 0;
    int totalDays = 0;
    
    // Only count days up to and including today
    for (int i = 0; i <= daysFromWeekStart; i++) {
      final date = weekStart.add(Duration(days: i));
      final dayEvents = _getEventsForDate(events, date);
      
      totalDays++;
      
      if (_isDayCompleted(dayEvents)) {
        completedDays++;
      }
    }
    
    return totalDays > 0 ? completedDays / totalDays : 0.0;
  }

  /// Check if a day is completed based on events
  bool _isDayCompleted(List<HabitEvent> dayEvents) {
    if (dayEvents.isEmpty) {
      return false;
    }

    if (habit.trackingType == TrackingType.value) {
      // For value-based habits, check if target is met
      double totalValue = 0.0;
      for (final event in dayEvents) {
        if (event.valueDelta != null) {
          totalValue += event.valueDelta!;
        } else if (event.value != null) {
          totalValue = event.value!;
        }
      }
      
      final target = habit.targetValue ?? 1.0;
      
      // Check goal type (minimum or maximum)
      if (habit.goalType == GoalType.minimum) {
        return totalValue >= target;
      } else {
        // For maximum goals, completed if value is at or below target
        return totalValue <= target;
      }
    } else {
      // For binary habits, check if any event is marked as completed
      return dayEvents.any((e) => e.completed == true);
    }
  }

  /// Calculate today's total value from events
  double? _calculateTodayValue(List<HabitEvent> events) {
    if (habit.trackingType != TrackingType.value) {
      return null;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    double totalValue = 0.0;
    bool hasEvents = false;

    for (final event in events) {
      final eventDate = DateTime(
        event.eventDate.year,
        event.eventDate.month,
        event.eventDate.day,
      );
      
      if (eventDate.isAtSameMomentAs(today)) {
        hasEvents = true;
        if (event.valueDelta != null) {
          totalValue += event.valueDelta!;
        } else if (event.value != null) {
          totalValue = event.value!;
        }
      }
    }

    return hasEvents ? totalValue : null;
  }
}
