import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/habit.dart';
import '../providers/habit_detail_provider.dart';

import 'habit_card.dart';
import '../models/enums/tracking_type.dart';
import '../models/enums/streak_type.dart';

/// Widget displaying a single habit in the list
/// Shows habit icon, name, and basic information
/// Tapping navigates to the habit detail screen
class HabitListItem extends ConsumerStatefulWidget {
  final Habit habit;

  const HabitListItem({
    super.key,
    required this.habit,
  });

  @override
  ConsumerState<HabitListItem> createState() => _HabitListItemState();
}

class _HabitListItemState extends ConsumerState<HabitListItem> {
  DateTime? _lastClickTime;

  void _handleTap(BuildContext context) {
    final now = DateTime.now();
    
    // Implement 500ms debounce logic
    if (_lastClickTime != null && 
        now.difference(_lastClickTime!).inMilliseconds < 500) {
      // Ignore rapid successive clicks
      return;
    }
    
    // Update last click time
    _lastClickTime = now;
    
    // Navigate to habit detail screen
    context.push('/habits/${widget.habit.id}');
  }

  @override
  Widget build(BuildContext context) {
    // Watch habit detail to get today's events
    final habitDetailAsync = ref.watch(habitDetailProvider(widget.habit.id!));

    // Calculate today's value from events
    final todayValue = habitDetailAsync.whenOrNull(
      data: (detailState) => _calculateTodayValue(detailState.events),
    );

    // Calculate accurate streak from habit detail provider
    final currentStreak = habitDetailAsync.whenOrNull(
      data: (detailState) => _getCurrentStreak(detailState),
    ) ?? 0;

    // Calculate accurate completion percentage
    final completionPercentage = habitDetailAsync.whenOrNull(
      data: (detailState) => _calculateCompletionPercentage(detailState),
    ) ?? 0.0;

    // Generate mock weekly progress
    final weeklyProgress = _generateMockWeeklyProgress();

    return InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(16),
      child: HabitCard(
        habit: widget.habit,
        weeklyProgress: weeklyProgress,
        score: currentStreak,
        overallProgress: completionPercentage,
        todayValue: todayValue,
        onQuickActionComplete: () {
          // Refresh habit detail when quick action completes
          ref.invalidate(habitDetailProvider(widget.habit.id!));
        },
      ),
    );
  }

  /// Calculate today's total value from events
  double? _calculateTodayValue(List<dynamic> events) {
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

  /// Get current streak from habit detail state
  /// Uses completion streak as the primary streak type
  int _getCurrentStreak(HabitDetailState detailState) {
    // Get completion streak (primary streak type)
    final completionStreak = detailState.streaks[StreakType.completion];
    return completionStreak?.currentStreak ?? 0;
  }

  /// Calculate completion percentage based on habit streak data
  /// Returns a value between 0.0 and 1.0
  double _calculateCompletionPercentage(HabitDetailState detailState) {
    // Get completion streak (primary streak type)
    final completionStreak = detailState.streaks[StreakType.completion];
    
    if (completionStreak == null) {
      return 0.0;
    }
    
    // Use the consistency rate from streak data
    // consistencyRate is a percentage (0-100), convert to 0.0-1.0
    return (completionStreak.consistencyRate / 100.0).clamp(0.0, 1.0);
  }

  List<DailyHabitStatus> _generateMockWeeklyProgress() {
    final now = DateTime.now();
    // Generate for the last 7 days or current week (Mon-Sun)
    // Let's do current week Mon-Sun
    final currentWeekday = now.weekday; // 1 = Mon, 7 = Sun
    final monday = now.subtract(Duration(days: currentWeekday - 1));

    return List.generate(7, (index) {
      final date = monday.add(Duration(days: index));
      final isFuture = date.isAfter(now);
      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
      
      // Mock data logic
      // If future, empty.
      // If past, random progress.
      
      if (isFuture && !isToday) {
        return DailyHabitStatus(
          date: date,
          isEmpty: true,
        );
      }

      // For today, let's make it partially done or empty
      if (isToday) {
        return DailyHabitStatus(
          date: date,
          progress: widget.habit.trackingType == TrackingType.value ? (widget.habit.targetValue ?? 1) * 0.5 : 0,
          target: widget.habit.targetValue ?? 1,
          isCurrentDay: true,
          isEmpty: false, // Today is never "empty" in terms of existence, but progress might be 0
        );
      }

      // Past days
      return DailyHabitStatus(
        date: date,
        progress: widget.habit.trackingType == TrackingType.value 
            ? (index % 2 == 0 ? (widget.habit.targetValue ?? 1) : (widget.habit.targetValue ?? 1) * 0.2) 
            : (index % 2 == 0 ? 1 : 0),
        target: widget.habit.targetValue ?? 1,
        quality: widget.habit.qualityLayerEnabled ? (index % 3 == 0 ? 5 : 0) : 0,
        isEmpty: false,
      );
    });
  }
}
