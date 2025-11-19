import '../repositories/habit_repository.dart';
import '../models/habit.dart';
import '../models/habit_event.dart';
import '../models/habit_period_progress.dart';
import '../models/enums/frequency.dart';
import '../models/enums/active_days_mode.dart';
import '../models/enums/require_mode.dart';
import '../models/enums/goal_type.dart';
import '../models/enums/tracking_type.dart';

/// Service for calculating period progress for weekly/monthly habits
class PeriodProgressService {
  final HabitRepository _repository;

  PeriodProgressService(this._repository);

  /// Recalculate period progress for a habit
  Future<void> recalculatePeriodProgress(int habitId) async {
    final habit = await _repository.getHabitById(habitId);
    if (habit == null) return;

    // Only calculate for non-daily habits
    if (habit.frequency == Frequency.daily) return;

    final progress = await _calculatePeriodProgress(habit);
    await _repository.savePeriodProgress(progress);
  }

  /// Calculate period progress for a habit
  Future<HabitPeriodProgress> _calculatePeriodProgress(Habit habit) async {
    final period = _getCurrentPeriod(habit);
    final events = await _repository.getEventsForHabit(
      habit.id!,
      startDate: period.start,
      endDate: period.end,
    );

    final activeDays = _getActiveDaysInPeriod(habit, period.start, period.end);
    final adjustedTarget = _calculateAdjustedTarget(habit, activeDays.length);
    final currentValue = _calculateCurrentValue(habit, events, activeDays);
    final completed = _checkPeriodCompletion(
      habit,
      currentValue,
      adjustedTarget,
      events,
      activeDays,
    );

    // Calculate time window and quality completions
    int timeWindowCompletions = 0;
    int qualityCompletions = 0;

    if (habit.timeWindowEnabled) {
      timeWindowCompletions = events
          .where((e) => e.withinTimeWindow == true)
          .length;
    }

    if (habit.qualityLayerEnabled) {
      qualityCompletions = events
          .where((e) => e.qualityAchieved == true)
          .length;
    }

    final now = DateTime.now();
    return HabitPeriodProgress(
      habitId: habit.id!,
      periodType: habit.frequency,
      periodStartDate: period.start,
      periodEndDate: period.end,
      targetValue: adjustedTarget,
      currentValue: currentValue,
      completed: completed,
      completionDate: completed ? now : null,
      timeWindowCompletions: timeWindowCompletions,
      qualityCompletions: qualityCompletions,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Get the current period start and end dates based on habit frequency
  ({DateTime start, DateTime end}) _getCurrentPeriod(Habit habit) {
    final now = DateTime.now();

    switch (habit.frequency) {
      case Frequency.weekly:
        // Week starts on Monday (weekday 1)
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return (
          start: DateTime(monday.year, monday.month, monday.day),
          end: DateTime(monday.year, monday.month, monday.day)
              .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59)),
        );

      case Frequency.monthly:
        return (
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );

      case Frequency.custom:
        // Calculate based on periodStartDate and customPeriodDays
        final startDate = habit.periodStartDate ?? now;
        final daysSinceStart = now.difference(startDate).inDays;
        final periodLength = habit.customPeriodDays ?? 7;
        final periodNumber = daysSinceStart ~/ periodLength;
        final periodStart = startDate.add(Duration(days: periodNumber * periodLength));
        final periodEnd = periodStart
            .add(Duration(days: periodLength - 1, hours: 23, minutes: 59, seconds: 59));
        return (start: periodStart, end: periodEnd);

      case Frequency.daily:
        // Should not reach here, but return today
        return (
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
    }
  }

  /// Get list of active days within the period based on habit configuration
  List<DateTime> _getActiveDaysInPeriod(
    Habit habit,
    DateTime start,
    DateTime end,
  ) {
    final days = <DateTime>[];
    DateTime current = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    while (current.isBefore(endDay) || current.isAtSameMomentAs(endDay)) {
      if (habit.activeDaysMode == ActiveDaysMode.all ||
          habit.activeWeekdays?.contains(current.weekday) == true) {
        days.add(current);
      }
      current = current.add(const Duration(days: 1));
    }

    return days;
  }

  /// Calculate adjusted target based on require mode and active days
  double _calculateAdjustedTarget(Habit habit, int activeDaysCount) {
    switch (habit.requireMode) {
      case RequireMode.each:
        // Target applies to each active day
        return (habit.targetValue ?? 0) * activeDaysCount;

      case RequireMode.any:
      case RequireMode.total:
        // Target is for the entire period
        return habit.targetValue ?? 0;
    }
  }

  /// Calculate current value based on events and require mode
  double _calculateCurrentValue(
    Habit habit,
    List<HabitEvent> events,
    List<DateTime> activeDays,
  ) {
    if (habit.requireMode == RequireMode.each) {
      // Check each day individually and count completed days
      int completedDays = 0;

      for (final day in activeDays) {
        final dayEvents = events.where((e) {
          final eventDay = DateTime(
            e.eventDate.year,
            e.eventDate.month,
            e.eventDate.day,
          );
          return eventDay.isAtSameMomentAs(day);
        }).toList();

        if (_isDayCompleted(habit, dayEvents)) {
          completedDays++;
        }
      }

      return completedDays.toDouble();
    } else {
      // Sum all events for any/total mode
      if (habit.trackingType == TrackingType.binary) {
        // For binary habits, count completed events
        return events.where((e) => e.completed == true).length.toDouble();
      } else {
        // For value/timed habits, sum the values
        return events.fold<double>(
          0,
          (sum, e) => sum + (e.valueDelta ?? e.value ?? 0),
        );
      }
    }
  }

  /// Check if a specific day is completed based on habit configuration
  bool _isDayCompleted(Habit habit, List<HabitEvent> dayEvents) {
    if (dayEvents.isEmpty) return false;

    if (habit.trackingType == TrackingType.binary) {
      return dayEvents.any((e) => e.completed == true);
    }

    // For value/timed habits, check against target
    final dayTotal = dayEvents.fold<double>(
      0,
      (sum, e) => sum + (e.valueDelta ?? e.value ?? 0),
    );

    switch (habit.goalType) {
      case GoalType.minimum:
        return dayTotal >= (habit.targetValue ?? 0);
      case GoalType.maximum:
        return dayTotal <= (habit.targetValue ?? double.infinity);
     
    }
  }

  /// Check if the period is completed based on require mode
  bool _checkPeriodCompletion(
    Habit habit,
    double currentValue,
    double target,
    List<HabitEvent> events,
    List<DateTime> activeDays,
  ) {
    switch (habit.requireMode) {
      case RequireMode.each:
        // All active days must be completed
        return currentValue >= activeDays.length;

      case RequireMode.any:
        // At least one day must be completed
        return currentValue >= 1;

      case RequireMode.total:
        // Total must meet target based on goal type
        switch (habit.goalType) {
          case GoalType.minimum:
            return currentValue >= target;
          case GoalType.maximum:
            return currentValue <= target;
      
        }
    }
  }
}
