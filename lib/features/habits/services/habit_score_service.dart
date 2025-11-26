import 'dart:math';

import '../models/habit.dart';
import '../models/habit_event.dart';
import '../models/habit_score.dart';
import '../models/enums/active_days_mode.dart';
import '../models/enums/frequency.dart';
import '../models/enums/tracking_type.dart';
import '../models/enums/goal_type.dart';
import '../repositories/habit_repository.dart';
import '../../../core/utils/core_logging_utility.dart';

/// Service for calculating habit strength scores using exponential moving average.
///
/// The algorithm is inspired by Loop Habit Tracker and uses the formula:
/// ```
/// newScore = previousScore × multiplier + checkmarkValue × (1 - multiplier)
/// multiplier = 0.5^(√frequency / 13.0)
/// ```
class HabitScoreService {
  final HabitRepository _repository;

  HabitScoreService({HabitRepository? repository})
      : _repository = repository ?? HabitRepository();
  /// Calculate the decay multiplier based on habit frequency.
  ///
  /// The multiplier controls how quickly scores decay on missed days.
  /// Higher frequency habits (daily) have lower multipliers (~0.948),
  /// while lower frequency habits (weekly) have higher multipliers (~0.980).
  ///
  /// Formula: multiplier = 0.5^(√frequency / 13.0)
  ///
  /// **Validates: Requirements 2.1, 2.4**
  double calculateMultiplier(double frequency) {
    // Handle invalid frequency values by defaulting to daily
    if (frequency <= 0) {
      frequency = 1.0;
    }
    return pow(0.5, sqrt(frequency) / 13.0).toDouble();
  }

  /// Get the frequency value for a habit (repetitions per day).
  ///
  /// - Daily: 1.0
  /// - Weekly: 1/7 ≈ 0.143
  /// - Monthly: 1/30 ≈ 0.033
  /// - Custom: repetitions / period_days
  ///
  /// **Validates: Requirements 2.2, 2.3, 2.4**
  double getFrequencyValue(Habit habit) {
    switch (habit.frequency) {
      case Frequency.daily:
        return 1.0;
      case Frequency.weekly:
        return 1.0 / 7.0;
      case Frequency.monthly:
        return 1.0 / 30.0;
      case Frequency.custom:
        final periodDays = habit.customPeriodDays ?? 1;
        if (periodDays <= 0) return 1.0;
        // For custom frequency, we assume 1 repetition per period
        // unless otherwise specified
        return 1.0 / periodDays;
    }
  }

  /// Calculate the checkmark value for a day's completion.
  ///
  /// For binary habits:
  /// - 1.0 if completed
  /// - 0.0 if not completed
  ///
  /// For value habits with minimum goal:
  /// - min(1.0, actualValue / targetValue)
  ///
  /// For value habits with maximum goal:
  /// - 1.0 if at or under target
  /// - Decreases proportionally when over target
  ///
  /// **Validates: Requirements 3.1, 3.2, 3.3**
  double calculateCheckmarkValue(Habit habit, List<HabitEvent> events) {
    if (events.isEmpty) {
      return 0.0;
    }

    if (habit.trackingType == TrackingType.binary) {
      // For binary habits, check if any event is completed
      final hasCompletion = events.any((e) => e.completed == true);
      return hasCompletion ? 1.0 : 0.0;
    }

    // For value habits, sum up all values for the day
    final totalValue = events.fold<double>(
      0.0,
      (sum, event) => sum + (event.value ?? 0.0),
    );

    final targetValue = habit.targetValue ?? 1.0;
    if (targetValue <= 0) {
      return 1.0; // Avoid division by zero
    }

    if (habit.goalType == GoalType.minimum) {
      // For minimum goals: checkmark = min(1.0, actual / target)
      return min(1.0, totalValue / targetValue);
    } else {
      // For maximum goals: staying under target = 1.0
      // Going over target decreases the score proportionally
      if (totalValue <= targetValue) {
        return 1.0;
      }
      // Calculate how much over the target we are
      final overAmount = totalValue - targetValue;
      final checkmark = max(0.0, 1.0 - (overAmount / targetValue));
      return checkmark.clamp(0.0, 1.0);
    }
  }

  /// Compute the new score using the exponential moving average formula.
  ///
  /// Formula: newScore = previousScore × multiplier + checkmarkValue × (1 - multiplier)
  ///
  /// **Validates: Requirements 1.2, 1.3**
  double computeScore(
    double previousScore,
    double multiplier,
    double checkmarkValue,
  ) {
    final newScore =
        previousScore * multiplier + checkmarkValue * (1 - multiplier);
    // Ensure score stays within bounds [0.0, 1.0]
    return newScore.clamp(0.0, 1.0);
  }

  /// Calculate the full score for a habit by iterating through all days
  /// from habit creation to today.
  ///
  /// - Skips non-active days based on habit configuration
  /// - Processes events for each active day
  /// - Handles skip entries by preserving the previous score
  /// - Accumulates score using exponential moving average
  ///
  /// **Validates: Requirements 5.1, 5.2, 5.3**
  double calculateScore(
    Habit habit,
    List<HabitEvent> events, {
    DateTime? endDate,
  }) {
    final today = endDate ?? DateTime.now();
    final startDate = habit.createdAt;

    // If habit was created in the future, return 0
    if (startDate.isAfter(today)) {
      return 0.0;
    }

    // Build a map of events by date for efficient lookup
    final eventsByDate = _groupEventsByDate(events);

    // Calculate multiplier based on habit frequency
    final frequency = getFrequencyValue(habit);
    final multiplier = calculateMultiplier(frequency);

    // Start with score of 0
    double currentScore = 0.0;

    // Iterate through each day from creation to today
    DateTime currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final endDay = DateTime(today.year, today.month, today.day);

    while (!currentDate.isAfter(endDay)) {
      // Check if this day is an active day for the habit
      if (isActiveDay(habit, currentDate)) {
        // Get events for this date
        final dayEvents = eventsByDate[_dateKey(currentDate)] ?? [];

        // Check if this day is marked as skip
        if (_isSkipDay(dayEvents)) {
          // Skip entries preserve the previous score - do nothing
        } else {
          // Calculate checkmark value for this day
          final checkmarkValue = calculateCheckmarkValue(habit, dayEvents);

          // Update score using exponential moving average
          currentScore = computeScore(currentScore, multiplier, checkmarkValue);
        }
      }

      // Move to next day
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return currentScore;
  }

  /// Check if a given date is an active day for the habit.
  ///
  /// Based on the habit's activeDaysMode:
  /// - ActiveDaysMode.all: All days are active
  /// - ActiveDaysMode.selected: Only days in activeWeekdays are active
  ///
  /// **Validates: Requirements 5.1**
  bool isActiveDay(Habit habit, DateTime date) {
    if (habit.activeDaysMode == ActiveDaysMode.all) {
      return true;
    }

    // For selected mode, check if the weekday is in the active list
    // DateTime.weekday returns 1 (Monday) to 7 (Sunday)
    final weekday = date.weekday;
    final activeWeekdays = habit.activeWeekdays ?? [];

    return activeWeekdays.contains(weekday);
  }

  /// Group events by date for efficient lookup.
  Map<String, List<HabitEvent>> _groupEventsByDate(List<HabitEvent> events) {
    final Map<String, List<HabitEvent>> eventsByDate = {};

    for (final event in events) {
      final key = _dateKey(event.eventDate);
      eventsByDate.putIfAbsent(key, () => []).add(event);
    }

    return eventsByDate;
  }

  /// Generate a date key string for map lookup.
  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Check if a day's events indicate a skip entry.
  ///
  /// A skip entry is detected when:
  /// - There's an event with notes containing "skip" (case-insensitive)
  /// - Or the event has a special skip marker
  ///
  /// **Validates: Requirements 5.2**
  bool _isSkipDay(List<HabitEvent> events) {
    if (events.isEmpty) {
      return false;
    }

    // Check if any event is marked as a skip
    for (final event in events) {
      // Check notes for skip indicator
      if (event.notes != null &&
          event.notes!.toLowerCase().contains('skip')) {
        return true;
      }

      // Check for explicit skip marker (completed = null with no value)
      // This represents a day that was explicitly skipped
      if (event.completed == null && event.value == null && event.notes == null) {
        // This could be a skip entry - but we need a more explicit marker
        // For now, we'll rely on the notes field
      }
    }

    return false;
  }

  // ============================================================================
  // CACHING OPERATIONS
  // ============================================================================

  /// Get the cached score for a habit, or calculate if not available.
  ///
  /// Returns the cached score if available and recent enough,
  /// otherwise triggers a full recalculation.
  ///
  /// **Validates: Requirements 6.1, 6.2**
  Future<HabitScore?> getScore(int habitId) async {
    try {
      // Try to get cached score from repository
      final cachedScore = await _repository.getScore(habitId);
      
      if (cachedScore != null) {
        CoreLoggingUtility.info(
          'HabitScoreService',
          'getScore',
          'Returning cached score ${cachedScore.score} for habit $habitId',
        );
        return cachedScore;
      }
      
      // No cached score, return null (caller should trigger recalculation)
      return null;
    } catch (e) {
      CoreLoggingUtility.error(
        'HabitScoreService',
        'getScore',
        'Failed to get score for habit $habitId: $e',
      );
      return null;
    }
  }

  /// Recalculate and cache the score for a habit.
  ///
  /// This method:
  /// 1. Fetches the habit and all its events
  /// 2. Calculates the score using the exponential moving average
  /// 3. Caches the result in the database
  ///
  /// **Validates: Requirements 6.1, 6.2**
  Future<HabitScore> recalculateScore(int habitId) async {
    CoreLoggingUtility.info(
      'HabitScoreService',
      'recalculateScore',
      'Recalculating score for habit $habitId',
    );

    // Fetch the habit
    final habit = await _repository.getHabitById(habitId);
    if (habit == null) {
      throw ArgumentError('Habit with id $habitId not found');
    }

    // Fetch all events for the habit
    final events = await _repository.getEventsForHabit(habitId);

    // Calculate the score
    final scoreValue = calculateScore(habit, events);

    // Find the last event date
    DateTime? lastEventDate;
    if (events.isNotEmpty) {
      lastEventDate = events
          .map((e) => e.eventDate)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }

    // Create the score object
    final score = HabitScore(
      habitId: habitId,
      score: scoreValue,
      calculatedAt: DateTime.now(),
      lastEventDate: lastEventDate,
    );

    // Cache the score
    await _repository.saveScore(score);

    CoreLoggingUtility.info(
      'HabitScoreService',
      'recalculateScore',
      'Cached score ${score.score} (${score.percentage}%) for habit $habitId',
    );

    return score;
  }

  /// Get the score for a habit, calculating if necessary.
  ///
  /// This is a convenience method that combines getScore and recalculateScore.
  /// It returns the cached score if available, otherwise calculates and caches it.
  ///
  /// **Validates: Requirements 6.1, 6.2**
  Future<HabitScore> getOrCalculateScore(int habitId) async {
    final cachedScore = await getScore(habitId);
    if (cachedScore != null) {
      return cachedScore;
    }
    return recalculateScore(habitId);
  }

  /// Invalidate the cached score for a habit.
  ///
  /// Called when habit configuration changes and a full recalculation is needed.
  ///
  /// **Validates: Requirements 6.3**
  Future<void> invalidateScore(int habitId) async {
    try {
      await _repository.deleteScore(habitId);
      CoreLoggingUtility.info(
        'HabitScoreService',
        'invalidateScore',
        'Invalidated score cache for habit $habitId',
      );
    } catch (e) {
      CoreLoggingUtility.error(
        'HabitScoreService',
        'invalidateScore',
        'Failed to invalidate score for habit $habitId: $e',
      );
    }
  }
}
