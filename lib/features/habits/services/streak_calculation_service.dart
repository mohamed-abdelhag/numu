import '../models/habit.dart';
import '../models/habit_event.dart';
import '../models/habit_streak.dart';
import '../models/enums/streak_type.dart';
import '../models/enums/tracking_type.dart';
import '../models/enums/goal_type.dart';
import '../models/enums/active_days_mode.dart';
import '../repositories/habit_repository.dart';

/// Service for calculating habit streaks
/// Handles all streak calculation logic including current streak, longest streak, and consistency
class StreakCalculationService {
  final HabitRepository _repository;

  StreakCalculationService(this._repository);

  /// Calculate all streak types for a habit
  Future<void> recalculateStreaks(int habitId) async {
    final habit = await _repository.getHabitById(habitId);
    if (habit == null) return;

    for (final type in StreakType.values) {
      final streak = await _calculateStreak(habit, type);
      await _repository.saveStreak(streak);
    }
  }

  /// Calculate a specific streak type for a habit
  Future<HabitStreak> _calculateStreak(Habit habit, StreakType type) async {
    int currentStreak = 0;
    DateTime? currentStreakStart;
    int longestStreak = 0;
    DateTime? longestStreakStart;
    DateTime? longestStreakEnd;
    int totalCompletions = 0;
    int totalDaysActive = 0;
    DateTime? lastEventDate;

    // Walk backwards from today to calculate current streak
    DateTime currentDate = _normalizeDate(DateTime.now());
    bool streakBroken = false;
    int daysChecked = 0;
    const maxDaysToCheck = 365; // Safety limit: don't go back more than 1 year

    while (!streakBroken && daysChecked < maxDaysToCheck) {
      // Check if this date is relevant (active day)
      if (!_isActiveDay(habit, currentDate)) {
        currentDate = currentDate.subtract(const Duration(days: 1));
        daysChecked++;
        continue;
      }

      totalDaysActive++;

      // Check if habit was completed on this date
      final completed = await _checkDayCompletion(habit, currentDate, type);

      if (completed) {
        currentStreak++;
        totalCompletions++;
        currentStreakStart = currentDate;
        lastEventDate ??= currentDate;
      } else {
        // Only break streak if we're past today (don't break for today if not yet completed)
        if (currentDate.isBefore(_normalizeDate(DateTime.now()))) {
          streakBroken = true;
        }
      }

      currentDate = currentDate.subtract(const Duration(days: 1));
      daysChecked++;
    }

    // Calculate longest streak by scanning historical data
    longestStreak = await _findLongestStreak(habit, type);
    if (longestStreak < currentStreak) {
      longestStreak = currentStreak;
      longestStreakStart = currentStreakStart;
      longestStreakEnd = _normalizeDate(DateTime.now());
    }

    // Calculate consistency rate
    final consistencyRate = totalDaysActive > 0
        ? (totalCompletions / totalDaysActive) * 100
        : 0.0;

    return HabitStreak(
      habitId: habit.id!,
      streakType: type,
      currentStreak: currentStreak,
      currentStreakStartDate: currentStreakStart,
      longestStreak: longestStreak,
      longestStreakStartDate: longestStreakStart,
      longestStreakEndDate: longestStreakEnd,
      totalCompletions: totalCompletions,
      totalDaysActive: totalDaysActive,
      consistencyRate: consistencyRate,
      lastCalculatedAt: DateTime.now(),
      lastEventDate: lastEventDate,
    );
  }

  /// Check if a given date is an active day for the habit
  bool _isActiveDay(Habit habit, DateTime date) {
    if (habit.activeDaysMode == ActiveDaysMode.all) {
      return true;
    }

    // Check if the weekday is in the active weekdays list
    final weekday = date.weekday; // 1-7, Monday-Sunday
    return habit.activeWeekdays?.contains(weekday) ?? true;
  }

  /// Check if the habit was completed on a specific date for a given streak type
  Future<bool> _checkDayCompletion(
    Habit habit,
    DateTime date,
    StreakType type,
  ) async {
    final events = await _repository.getEventsForDate(habit.id!, date);

    if (events.isEmpty) return false;

    switch (type) {
      case StreakType.completion:
        return _checkBasicCompletion(habit, events);
      case StreakType.timeWindow:
        return _checkTimeWindowCompletion(habit, events);
      case StreakType.quality:
        return _checkQualityCompletion(habit, events);
      case StreakType.perfect:
        return _checkPerfectCompletion(habit, events);
    }
  }

  /// Check basic completion (habit goal was met)
  bool _checkBasicCompletion(Habit habit, List<HabitEvent> events) {
    if (habit.trackingType == TrackingType.binary) {
      // For binary habits, check if any event is marked as completed
      return events.any((e) => e.completed == true);
    }

    // For value habits, sum up the values
    final total = events.fold<double>(0, (sum, e) => sum + (e.valueDelta ?? 0));

    switch (habit.goalType) {
      case GoalType.minimum:
        return total >= (habit.targetValue ?? 0);
      case GoalType.maximum:
        return total <= (habit.targetValue ?? double.infinity);
    }
  }

  /// Check time window completion (habit was completed within time window)
  bool _checkTimeWindowCompletion(Habit habit, List<HabitEvent> events) {
    if (!habit.timeWindowEnabled) return false;
    return events.any((e) => e.withinTimeWindow == true);
  }

  /// Check quality completion (habit was completed with quality achievement)
  bool _checkQualityCompletion(Habit habit, List<HabitEvent> events) {
    if (!habit.qualityLayerEnabled) return false;
    return events.any((e) => e.qualityAchieved == true);
  }

  /// Check perfect completion (all criteria met)
  bool _checkPerfectCompletion(Habit habit, List<HabitEvent> events) {
    final basicComplete = _checkBasicCompletion(habit, events);
    final timeWindowComplete = !habit.timeWindowEnabled || 
                               _checkTimeWindowCompletion(habit, events);
    final qualityComplete = !habit.qualityLayerEnabled || 
                           _checkQualityCompletion(habit, events);

    return basicComplete && timeWindowComplete && qualityComplete;
  }

  /// Find the longest streak in historical data
  /// This is a simplified implementation - a full implementation would scan all events
  Future<int> _findLongestStreak(Habit habit, StreakType type) async {
    // For now, we'll use a simplified approach
    // A full implementation would scan all historical events to find the longest streak
    // This would be expensive, so we cache the result
    
    // Get all events for the habit (limited to last year for performance)
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    final events = await _repository.getEventsForHabit(
      habit.id!,
      startDate: oneYearAgo,
    );

    if (events.isEmpty) return 0;

    int maxStreak = 0;
    int currentStreakCount = 0;
    DateTime? lastDate;

    // Group events by date and check each day
    final eventsByDate = <DateTime, List<HabitEvent>>{};
    for (final event in events) {
      final normalizedDate = _normalizeDate(event.eventDate);
      eventsByDate.putIfAbsent(normalizedDate, () => []).add(event);
    }

    // Sort dates
    final sortedDates = eventsByDate.keys.toList()..sort();

    for (final date in sortedDates) {
      if (!_isActiveDay(habit, date)) continue;

      final dayEvents = eventsByDate[date]!;
      final completed = _checkDayCompletionSync(habit, dayEvents, type);

      if (completed) {
        if (lastDate == null || date.difference(lastDate).inDays == 1) {
          currentStreakCount++;
        } else {
          // Streak broken, start new streak
          maxStreak = currentStreakCount > maxStreak ? currentStreakCount : maxStreak;
          currentStreakCount = 1;
        }
        lastDate = date;
      } else {
        maxStreak = currentStreakCount > maxStreak ? currentStreakCount : maxStreak;
        currentStreakCount = 0;
        lastDate = null;
      }
    }

    // Check final streak
    maxStreak = currentStreakCount > maxStreak ? currentStreakCount : maxStreak;

    return maxStreak;
  }

  /// Synchronous version of day completion check for historical scanning
  bool _checkDayCompletionSync(
    Habit habit,
    List<HabitEvent> events,
    StreakType type,
  ) {
    if (events.isEmpty) return false;

    switch (type) {
      case StreakType.completion:
        return _checkBasicCompletion(habit, events);
      case StreakType.timeWindow:
        return _checkTimeWindowCompletion(habit, events);
      case StreakType.quality:
        return _checkQualityCompletion(habit, events);
      case StreakType.perfect:
        return _checkPerfectCompletion(habit, events);
    }
  }

  /// Normalize a date to start of day (midnight)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
