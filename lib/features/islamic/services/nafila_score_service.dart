import 'dart:math';

import '../models/nafila_event.dart';
import '../models/nafila_score.dart';
import '../models/enums/nafila_type.dart';
import '../repositories/nafila_repository.dart';
import '../../../core/utils/core_logging_utility.dart';

/// Service for calculating Nafila prayer strength scores using exponential moving average.
///
/// The algorithm is inspired by Loop Habit Tracker and reuses the same formula
/// as HabitScoreService and PrayerScoreService:
/// ```
/// newScore = previousScore × multiplier + checkmarkValue × (1 - multiplier)
/// multiplier = 0.5^(√frequency / 13.0)
/// ```
///
/// For Nafila prayers, frequency is always 1.0 (daily), so multiplier ≈ 0.948.
///
/// **Validates: Requirements 4.4, 4.5, 4.6**
class NafilaScoreService {
  final NafilaRepository _repository;

  NafilaScoreService({NafilaRepository? repository})
      : _repository = repository ?? NafilaRepository();

  // ============================================================================
  // CORE ALGORITHM (Reused from HabitScoreService/PrayerScoreService)
  // ============================================================================

  /// Calculate the decay multiplier based on frequency.
  ///
  /// For Nafila prayers, frequency is always 1.0 (daily), resulting in multiplier ≈ 0.948.
  /// Formula: multiplier = 0.5^(√frequency / 13.0)
  double calculateMultiplier(double frequency) {
    if (frequency <= 0) {
      frequency = 1.0;
    }
    return pow(0.5, sqrt(frequency) / 13.0).toDouble();
  }

  /// Calculate the checkmark value for a day's Nafila completion.
  ///
  /// - 0.0 if Nafila was not completed
  /// - 1.0 if Nafila was completed
  double calculateCheckmarkValue(List<NafilaEvent> events) {
    if (events.isEmpty) {
      return 0.0;
    }
    return 1.0;
  }

  /// Compute the new score using the exponential moving average formula.
  ///
  /// Formula: newScore = previousScore × multiplier + checkmarkValue × (1 - multiplier)
  double computeScore(
    double previousScore,
    double multiplier,
    double checkmarkValue,
  ) {
    final newScore =
        previousScore * multiplier + checkmarkValue * (1 - multiplier);
    return newScore.clamp(0.0, 1.0);
  }

  /// Calculate the full score for a Nafila type by iterating through all days
  /// from the first event to today.
  ///
  /// **Validates: Requirements 4.4**
  double calculateScore(
    NafilaType nafilaType,
    List<NafilaEvent> events, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final today = endDate ?? DateTime.now();

    if (events.isEmpty) {
      return 0.0;
    }

    // Filter events for this Nafila type
    final typeEvents = events.where((e) => e.nafilaType == nafilaType).toList();
    if (typeEvents.isEmpty) {
      return 0.0;
    }

    // Find the earliest event date as start date
    final sortedEvents = List<NafilaEvent>.from(typeEvents)
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

    final effectiveStartDate = startDate ??
        DateTime(
          sortedEvents.first.eventDate.year,
          sortedEvents.first.eventDate.month,
          sortedEvents.first.eventDate.day,
        );

    // Build a map of events by date for efficient lookup
    final eventsByDate = _groupEventsByDate(typeEvents);

    // Calculate multiplier (frequency = 1.0 for daily)
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

  /// Calculate current and longest streak for a Nafila type.
  ///
  /// Current streak: consecutive completed days ending at today (or most recent completed day)
  /// Longest streak: maximum consecutive completed days in history
  ///
  /// **Validates: Requirements 4.4**
  ({int currentStreak, int longestStreak}) calculateStreak(
    List<NafilaEvent> events, {
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
  // RAKAT AGGREGATION
  // ============================================================================

  /// Calculate total rakats for a Nafila type.
  ///
  /// **Validates: Requirements 4.5**
  int calculateTotalRakats(List<NafilaEvent> events) {
    if (events.isEmpty) {
      return 0;
    }
    return events.fold(0, (sum, event) => sum + event.rakatCount);
  }

  /// Calculate average rakats per session for a Nafila type.
  ///
  /// **Validates: Requirements 4.6**
  double calculateAverageRakats(List<NafilaEvent> events) {
    if (events.isEmpty) {
      return 0.0;
    }
    final totalRakats = calculateTotalRakats(events);
    return totalRakats / events.length;
  }

  // ============================================================================
  // FULL SCORE CALCULATION
  // ============================================================================

  /// Calculate all scores for all Nafila types.
  ///
  /// **Validates: Requirements 4.4, 4.5, 4.6**
  Future<Map<NafilaType, NafilaScore>> calculateAllScores({
    DateTime? endDate,
  }) async {
    final scores = <NafilaType, NafilaScore>{};
    final today = endDate ?? DateTime.now();

    for (final nafilaType in NafilaType.values) {
      // Skip custom type for aggregate calculations
      if (nafilaType == NafilaType.custom) continue;

      final events = await _repository.getEventsForType(nafilaType);
      scores[nafilaType] = _calculateScoreForType(nafilaType, events, today);
    }

    return scores;
  }

  /// Calculate score for a specific Nafila type from events.
  NafilaScore _calculateScoreForType(
    NafilaType nafilaType,
    List<NafilaEvent> events,
    DateTime endDate,
  ) {
    final scoreValue = calculateScore(nafilaType, events, endDate: endDate);
    final streaks = calculateStreak(events, endDate: endDate);
    final totalRakats = calculateTotalRakats(events);
    final totalCompletions = events.length;

    DateTime? lastEventDate;
    if (events.isNotEmpty) {
      lastEventDate = events
          .map((e) => e.eventDate)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }

    return NafilaScore(
      nafilaType: nafilaType,
      score: scoreValue,
      currentStreak: streaks.currentStreak,
      longestStreak: streaks.longestStreak,
      totalRakats: totalRakats,
      totalCompletions: totalCompletions,
      calculatedAt: DateTime.now(),
      lastEventDate: lastEventDate,
    );
  }

  // ============================================================================
  // CACHING OPERATIONS
  // ============================================================================

  /// Recalculate and cache the score for a Nafila type.
  ///
  /// **Validates: Requirements 4.4, 4.5, 4.6**
  Future<NafilaScore> recalculateScore(NafilaType nafilaType) async {
    CoreLoggingUtility.info(
      'NafilaScoreService',
      'recalculateScore',
      'Recalculating score for ${nafilaType.englishName}',
    );

    final events = await _repository.getEventsForType(nafilaType);
    final score = _calculateScoreForType(nafilaType, events, DateTime.now());

    // Cache the score
    await _repository.saveNafilaScore(score);

    CoreLoggingUtility.info(
      'NafilaScoreService',
      'recalculateScore',
      'Cached score ${score.score} (${score.percentage}%) for ${nafilaType.englishName}',
    );

    return score;
  }

  /// Recalculate and cache all Nafila scores.
  Future<void> recalculateAllScores() async {
    CoreLoggingUtility.info(
      'NafilaScoreService',
      'recalculateAllScores',
      'Recalculating all Nafila scores',
    );

    for (final nafilaType in NafilaType.values) {
      if (nafilaType == NafilaType.custom) continue;
      await recalculateScore(nafilaType);
    }
  }

  /// Get all cached Nafila scores.
  Future<Map<NafilaType, NafilaScore>> getAllScores() async {
    try {
      return await _repository.getAllNafilaScores();
    } catch (e) {
      CoreLoggingUtility.error(
        'NafilaScoreService',
        'getAllScores',
        'Failed to get all scores: $e',
      );
      return {};
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Group events by date for efficient lookup.
  Map<String, List<NafilaEvent>> _groupEventsByDate(List<NafilaEvent> events) {
    final Map<String, List<NafilaEvent>> eventsByDate = {};

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
