import 'dart:math';

import '../models/prayer_event.dart';
import '../models/prayer_score.dart';
import '../models/enums/prayer_type.dart';
import '../repositories/prayer_repository.dart';
import '../../../core/utils/core_logging_utility.dart';

/// Service for calculating prayer strength scores using exponential moving average.
///
/// The algorithm is inspired by Loop Habit Tracker and reuses the same formula
/// as HabitScoreService:
/// ```
/// newScore = previousScore × multiplier + checkmarkValue × (1 - multiplier)
/// multiplier = 0.5^(√frequency / 13.0)
/// ```
///
/// For prayers, frequency is always 1.0 (daily), so multiplier ≈ 0.948.
/// Jamaah (congregation) prayers receive a quality multiplier bonus.
///
/// **Validates: Requirements 4.1, 4.5**
class PrayerScoreService {
  final PrayerRepository _repository;

  /// Quality multiplier applied when prayer is performed in Jamaah (congregation).
  /// This increases the checkmark value by 20% (capped at 1.0).
  static const double jamaahQualityMultiplier = 1.2;

  PrayerScoreService({PrayerRepository? repository})
      : _repository = repository ?? PrayerRepository();

  // ============================================================================
  // CORE ALGORITHM (Reused from HabitScoreService)
  // ============================================================================

  /// Calculate the decay multiplier based on frequency.
  ///
  /// For prayers, frequency is always 1.0 (daily), resulting in multiplier ≈ 0.948.
  /// Formula: multiplier = 0.5^(√frequency / 13.0)
  ///
  /// **Validates: Requirements 4.1**
  double calculateMultiplier(double frequency) {
    if (frequency <= 0) {
      frequency = 1.0;
    }
    return pow(0.5, sqrt(frequency) / 13.0).toDouble();
  }

  /// Calculate the checkmark value for a day's prayer completion.
  ///
  /// - 0.0 if prayer was not completed
  /// - 1.0 if prayer was completed individually
  /// - min(1.0, 1.0 * jamaahQualityMultiplier) if prayer was completed in Jamaah
  ///
  /// **Validates: Requirements 4.1, 4.5**
  double calculateCheckmarkValue(List<PrayerEvent> events) {
    if (events.isEmpty) {
      return 0.0;
    }

    // Check if any event was prayed in Jamaah
    final hasJamaah = events.any((e) => e.prayedInJamaah);

    if (hasJamaah) {
      // Apply Jamaah quality multiplier (capped at 1.0)
      return min(1.0, 1.0 * jamaahQualityMultiplier);
    }

    // Prayer completed individually
    return 1.0;
  }

  /// Compute the new score using the exponential moving average formula.
  ///
  /// Formula: newScore = previousScore × multiplier + checkmarkValue × (1 - multiplier)
  ///
  /// **Validates: Requirements 4.1**
  double computeScore(
    double previousScore,
    double multiplier,
    double checkmarkValue,
  ) {
    final newScore =
        previousScore * multiplier + checkmarkValue * (1 - multiplier);
    return newScore.clamp(0.0, 1.0);
  }

  /// Calculate the full score for a prayer type by iterating through all days
  /// from the first event to today.
  ///
  /// **Validates: Requirements 4.1, 4.5**
  double calculateScore(
    PrayerType prayerType,
    List<PrayerEvent> events, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final today = endDate ?? DateTime.now();

    if (events.isEmpty) {
      return 0.0;
    }

    // Find the earliest event date as start date
    final sortedEvents = List<PrayerEvent>.from(events)
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

    final effectiveStartDate = startDate ??
        DateTime(
          sortedEvents.first.eventDate.year,
          sortedEvents.first.eventDate.month,
          sortedEvents.first.eventDate.day,
        );

    // Build a map of events by date for efficient lookup
    final eventsByDate = _groupEventsByDate(events);

    // Calculate multiplier (frequency = 1.0 for daily prayers)
    final multiplier = calculateMultiplier(1.0);

    // Start with score of 0
    double currentScore = 0.0;

    // Iterate through each day from start to today
    DateTime currentDate = DateTime(
      effectiveStartDate.year,
      effectiveStartDate.month,
      effectiveStartDate.day,
    );
    final endDay = DateTime(today.year, today.month, today.day);

    while (!currentDate.isAfter(endDay)) {
      // Get events for this date
      final dayEvents = eventsByDate[_dateKey(currentDate)] ?? [];

      // Calculate checkmark value for this day
      final checkmarkValue = calculateCheckmarkValue(dayEvents);

      // Update score using exponential moving average
      currentScore = computeScore(currentScore, multiplier, checkmarkValue);

      // Move to next day
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return currentScore;
  }

  // ============================================================================
  // STREAK CALCULATION
  // ============================================================================

  /// Calculate current and longest streak for a prayer type.
  ///
  /// Current streak: consecutive completed days ending at today (or most recent completed day)
  /// Longest streak: maximum consecutive completed days in history
  ///
  /// **Validates: Requirements 4.4**
  ({int currentStreak, int longestStreak}) calculateStreaks(
    List<PrayerEvent> events, {
    DateTime? endDate,
  }) {
    if (events.isEmpty) {
      return (currentStreak: 0, longestStreak: 0);
    }

    // Get unique completed dates
    final completedDates = events
        .map((e) => DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day))
        .toSet()
        .toList()
      ..sort();

    if (completedDates.isEmpty) {
      return (currentStreak: 0, longestStreak: 0);
    }

    final today = endDate ?? DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    // Calculate current streak (working backwards from today or most recent date)
    int currentStreak = 0;
    DateTime checkDate = normalizedToday;

    // First, check if today or yesterday has a completion to start the streak
    final hasToday = completedDates.any((d) =>
        d.year == normalizedToday.year &&
        d.month == normalizedToday.month &&
        d.day == normalizedToday.day);

    final yesterday = normalizedToday.subtract(const Duration(days: 1));
    final hasYesterday = completedDates.any((d) =>
        d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day);

    if (hasToday) {
      checkDate = normalizedToday;
    } else if (hasYesterday) {
      checkDate = yesterday;
    } else {
      // No recent completion, current streak is 0
      currentStreak = 0;
      checkDate = normalizedToday; // Will not find any matches
    }

    // Count consecutive days backwards
    if (hasToday || hasYesterday) {
      while (true) {
        final hasCompletion = completedDates.any((d) =>
            d.year == checkDate.year &&
            d.month == checkDate.month &&
            d.day == checkDate.day);

        if (hasCompletion) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    // Calculate longest streak
    int longestStreak = 0;
    int tempStreak = 1;

    for (int i = 1; i < completedDates.length; i++) {
      final prevDate = completedDates[i - 1];
      final currDate = completedDates[i];
      final diff = currDate.difference(prevDate).inDays;

      if (diff == 1) {
        tempStreak++;
      } else {
        longestStreak = max(longestStreak, tempStreak);
        tempStreak = 1;
      }
    }
    longestStreak = max(longestStreak, tempStreak);

    // Ensure longest streak is at least as large as current streak
    longestStreak = max(longestStreak, currentStreak);

    return (currentStreak: currentStreak, longestStreak: longestStreak);
  }

  // ============================================================================
  // JAMAAH RATE CALCULATION
  // ============================================================================

  /// Calculate the Jamaah (congregation) rate for a prayer type.
  ///
  /// Returns the percentage of prayers performed in congregation (0.0 to 1.0).
  ///
  /// **Validates: Requirements 4.5**
  double calculateJamaahRate(List<PrayerEvent> events) {
    if (events.isEmpty) {
      return 0.0;
    }

    final jamaahCount = events.where((e) => e.prayedInJamaah).length;
    return jamaahCount / events.length;
  }

  // ============================================================================
  // WEEKLY COMPLETION PERCENTAGE
  // ============================================================================

  /// Calculate weekly completion percentage for a prayer type.
  ///
  /// Returns (number of completed prayers / number of days in range) × 100,
  /// bounded between 0 and 100.
  ///
  /// **Validates: Requirements 4.6**
  double calculateWeeklyCompletionPercentage(
    List<PrayerEvent> events,
    DateTime weekStart,
    DateTime weekEnd,
  ) {
    // Normalize dates
    final normalizedStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final normalizedEnd = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);

    // Calculate number of days in range (inclusive)
    final daysInRange = normalizedEnd.difference(normalizedStart).inDays + 1;

    if (daysInRange <= 0) {
      return 0.0;
    }

    // Filter events within the date range
    final eventsInRange = events.where((e) {
      final eventDate = DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day);
      return !eventDate.isBefore(normalizedStart) && !eventDate.isAfter(normalizedEnd);
    }).toList();

    // Count unique completed days
    final completedDays = eventsInRange
        .map((e) => DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day))
        .toSet()
        .length;

    // Calculate percentage (bounded 0-100)
    final percentage = (completedDays / daysInRange) * 100;
    return percentage.clamp(0.0, 100.0);
  }

  // ============================================================================
  // OVERALL SCORE AGGREGATION
  // ============================================================================

  /// Calculate overall prayer score as the arithmetic mean of all five prayer scores.
  ///
  /// **Validates: Requirements 4.2, 4.3**
  double calculateOverallScore(Map<PrayerType, double> individualScores) {
    if (individualScores.isEmpty) {
      return 0.0;
    }

    // Ensure we have all 5 prayer types, defaulting to 0.0 for missing ones
    double totalScore = 0.0;
    for (final type in PrayerType.values) {
      totalScore += individualScores[type] ?? 0.0;
    }

    return totalScore / PrayerType.values.length;
  }

  // ============================================================================
  // CACHING OPERATIONS
  // ============================================================================

  /// Get the cached score for a prayer type, or null if not available.
  Future<PrayerScore?> getScore(PrayerType prayerType) async {
    try {
      return await _repository.getPrayerScore(prayerType);
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerScoreService',
        'getScore',
        'Failed to get score for ${prayerType.englishName}: $e',
      );
      return null;
    }
  }

  /// Recalculate and cache the score for a prayer type.
  ///
  /// **Validates: Requirements 4.1, 4.4, 4.5**
  Future<PrayerScore> recalculateScore(PrayerType prayerType) async {
    CoreLoggingUtility.info(
      'PrayerScoreService',
      'recalculateScore',
      'Recalculating score for ${prayerType.englishName}',
    );

    // Fetch all events for this prayer type
    final events = await _repository.getEventsForPrayer(prayerType);

    // Calculate the score
    final scoreValue = calculateScore(prayerType, events);

    // Calculate streaks
    final streaks = calculateStreaks(events);

    // Calculate Jamaah rate
    final jamaahRate = calculateJamaahRate(events);

    // Find the last event date
    DateTime? lastEventDate;
    if (events.isNotEmpty) {
      lastEventDate = events
          .map((e) => e.eventDate)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }

    // Create the score object
    final score = PrayerScore(
      prayerType: prayerType,
      score: scoreValue,
      currentStreak: streaks.currentStreak,
      longestStreak: streaks.longestStreak,
      jamaahRate: jamaahRate,
      calculatedAt: DateTime.now(),
      lastEventDate: lastEventDate,
    );

    // Cache the score
    await _repository.savePrayerScore(score);

    CoreLoggingUtility.info(
      'PrayerScoreService',
      'recalculateScore',
      'Cached score ${score.score} (${score.percentage}%) for ${prayerType.englishName}',
    );

    return score;
  }

  /// Get the score for a prayer type, calculating if necessary.
  Future<PrayerScore> getOrCalculateScore(PrayerType prayerType) async {
    final cachedScore = await getScore(prayerType);
    if (cachedScore != null) {
      return cachedScore;
    }
    return recalculateScore(prayerType);
  }

  /// Recalculate and cache all prayer scores.
  Future<void> recalculateAllScores() async {
    CoreLoggingUtility.info(
      'PrayerScoreService',
      'recalculateAllScores',
      'Recalculating all prayer scores',
    );

    for (final prayerType in PrayerType.values) {
      await recalculateScore(prayerType);
    }
  }

  /// Get all cached prayer scores.
  Future<Map<PrayerType, PrayerScore>> getAllScores() async {
    try {
      return await _repository.getAllPrayerScores();
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerScoreService',
        'getAllScores',
        'Failed to get all scores: $e',
      );
      return {};
    }
  }

  /// Calculate overall score from cached scores.
  ///
  /// **Validates: Requirements 4.2, 4.3**
  Future<double> getOverallScore() async {
    final scores = await getAllScores();
    final individualScores = <PrayerType, double>{};

    for (final entry in scores.entries) {
      individualScores[entry.key] = entry.value.score;
    }

    return calculateOverallScore(individualScores);
  }

  /// Invalidate the cached score for a prayer type.
  Future<void> invalidateScore(PrayerType prayerType) async {
    try {
      await _repository.deletePrayerScore(prayerType);
      CoreLoggingUtility.info(
        'PrayerScoreService',
        'invalidateScore',
        'Invalidated score cache for ${prayerType.englishName}',
      );
    } catch (e) {
      CoreLoggingUtility.error(
        'PrayerScoreService',
        'invalidateScore',
        'Failed to invalidate score for ${prayerType.englishName}: $e',
      );
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Group events by date for efficient lookup.
  Map<String, List<PrayerEvent>> _groupEventsByDate(List<PrayerEvent> events) {
    final Map<String, List<PrayerEvent>> eventsByDate = {};

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
}
