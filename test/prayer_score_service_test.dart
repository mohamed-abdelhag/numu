import 'package:glados/glados.dart';
import 'package:numu/features/islamic/models/enums/prayer_type.dart';
import 'package:numu/features/islamic/models/prayer_event.dart';
import 'package:numu/features/islamic/services/prayer_score_service.dart';
import 'package:numu/features/habits/services/habit_score_service.dart';

/// Custom generators for PrayerScoreService tests
extension PrayerScoreGenerators on Any {
  /// Generator for PrayerType enum values
  Generator<PrayerType> get prayerType => choose(PrayerType.values);

  /// Generator for a valid date (date-only, no time component)
  Generator<DateTime> get dateOnly => intInRange(2020, 2025).bind((year) =>
      intInRange(1, 12).bind((month) => intInRange(1, 28).map((day) =>
          DateTime(year, month, day))));

  /// Generator for a valid timestamp on a given date
  Generator<DateTime> timestampOnDate(DateTime date) {
    return intInRange(0, 23).bind((hour) =>
        intInRange(0, 59).bind((minute) =>
            intInRange(0, 59).map((second) =>
                DateTime(date.year, date.month, date.day, hour, minute, second))));
  }

  /// Generator for a list of consecutive dates starting from a base date
  Generator<List<DateTime>> consecutiveDates(int minDays, int maxDays) {
    return dateOnly.bind((startDate) =>
        intInRange(minDays, maxDays).map((numDays) {
          final dates = <DateTime>[];
          for (int i = 0; i < numDays; i++) {
            dates.add(startDate.add(Duration(days: i)));
          }
          return dates;
        }));
  }

  /// Generator for a prayer event on a specific date
  Generator<PrayerEvent> prayerEventOnDate(DateTime date, PrayerType type, bool jamaah) {
    return timestampOnDate(date).map((timestamp) => PrayerEvent(
      prayerType: type,
      eventDate: date,
      eventTimestamp: timestamp,
      prayedInJamaah: jamaah,
      withinTimeWindow: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  /// Generator for a list of prayer events with varying Jamaah status
  Generator<List<PrayerEvent>> prayerEventsWithJamaah(int count, bool allJamaah) {
    return dateOnly.bind((startDate) =>
        prayerType.map((type) {
          final events = <PrayerEvent>[];
          for (int i = 0; i < count; i++) {
            final date = startDate.add(Duration(days: i));
            events.add(PrayerEvent(
              prayerType: type,
              eventDate: date,
              eventTimestamp: DateTime(date.year, date.month, date.day, 12, 0),
              prayedInJamaah: allJamaah,
              withinTimeWindow: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));
          }
          return events;
        }));
  }

  /// Generator for individual prayer scores (0.0 to 1.0)
  Generator<double> get scoreValue => doubleInRange(0.0, 1.0);

  /// Generator for a map of all five prayer scores
  Generator<Map<PrayerType, double>> get allPrayerScores {
    return scoreValue.bind((fajr) =>
        scoreValue.bind((dhuhr) =>
            scoreValue.bind((asr) =>
                scoreValue.bind((maghrib) =>
                    scoreValue.map((isha) => {
                      PrayerType.fajr: fajr,
                      PrayerType.dhuhr: dhuhr,
                      PrayerType.asr: asr,
                      PrayerType.maghrib: maghrib,
                      PrayerType.isha: isha,
                    })))));
  }

  /// Generator for week date range
  Generator<({DateTime start, DateTime end})> get weekDateRange {
    return dateOnly.map((startDate) => (
      start: startDate,
      end: startDate.add(const Duration(days: 6)),
    ));
  }

  /// Generator for number of events in a week (0 to 7)
  Generator<int> get weekEventCount => intInRange(0, 7);
}

void main() {
  late PrayerScoreService prayerScoreService;
  late HabitScoreService habitScoreService;

  setUp(() {
    prayerScoreService = PrayerScoreService();
    habitScoreService = HabitScoreService();
  });

  group('PrayerScoreService Property Tests', () {
    /// **Feature: islamic-prayer-system, Property 6: Score Calculation Consistency**
    /// **Validates: Requirements 4.1**
    ///
    /// *For any* sequence of prayer events for a single prayer type, the prayer score
    /// calculation SHALL produce the same result as the habit score service when given
    /// equivalent input data (same completion dates and values).
    Glados(any.intInRange(1, 30)).test(
      'Property 6: Score Calculation Consistency - prayer score uses same algorithm as habit score',
      (numDays) {
        // Both services should use the same multiplier for daily frequency
        const dailyFrequency = 1.0;
        
        final prayerMultiplier = prayerScoreService.calculateMultiplier(dailyFrequency);
        final habitMultiplier = habitScoreService.calculateMultiplier(dailyFrequency);
        
        expect(prayerMultiplier, equals(habitMultiplier),
            reason: 'Multiplier calculation should be identical');

        // Test computeScore with same inputs produces same output
        final previousScore = 0.5;
        final checkmarkValue = 1.0;
        
        final prayerScore = prayerScoreService.computeScore(
          previousScore,
          prayerMultiplier,
          checkmarkValue,
        );
        final habitScore = habitScoreService.computeScore(
          previousScore,
          habitMultiplier,
          checkmarkValue,
        );
        
        expect(prayerScore, equals(habitScore),
            reason: 'Score computation should be identical for same inputs');
      },
    );

    /// **Feature: islamic-prayer-system, Property 7: Overall Score Aggregation**
    /// **Validates: Requirements 4.2, 4.3**
    ///
    /// *For any* set of five individual prayer scores (one per prayer type),
    /// the overall prayer score SHALL equal the arithmetic mean of the five individual scores.
    Glados(any.allPrayerScores).test(
      'Property 7: Overall Score Aggregation - overall score is arithmetic mean of five prayers',
      (scores) {
        final overallScore = prayerScoreService.calculateOverallScore(scores);
        
        // Calculate expected mean
        final expectedMean = (scores[PrayerType.fajr]! +
            scores[PrayerType.dhuhr]! +
            scores[PrayerType.asr]! +
            scores[PrayerType.maghrib]! +
            scores[PrayerType.isha]!) / 5.0;
        
        expect(overallScore, closeTo(expectedMean, 0.0001),
            reason: 'Overall score should be arithmetic mean of all five prayer scores');
      },
    );

    /// **Feature: islamic-prayer-system, Property 8: Streak Calculation Correctness**
    /// **Validates: Requirements 4.4**
    ///
    /// *For any* sequence of prayer events for a single prayer type ordered by date,
    /// the current streak SHALL equal the count of consecutive completed days ending
    /// at today (or the most recent completed day), and the longest streak SHALL be
    /// greater than or equal to the current streak.
    Glados(any.consecutiveDates(1, 20)).test(
      'Property 8: Streak Calculation Correctness - longest streak >= current streak',
      (dates) {
        // Create events for all dates
        final events = dates.map((date) => PrayerEvent(
          prayerType: PrayerType.fajr,
          eventDate: date,
          eventTimestamp: DateTime(date.year, date.month, date.day, 5, 0),
          prayedInJamaah: false,
          withinTimeWindow: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )).toList();

        final streaks = prayerScoreService.calculateStreaks(
          events,
          endDate: dates.last,
        );

        // Longest streak should always be >= current streak
        expect(streaks.longestStreak, greaterThanOrEqualTo(streaks.currentStreak),
            reason: 'Longest streak must be >= current streak');

        // For consecutive dates, longest streak should equal the number of dates
        expect(streaks.longestStreak, equals(dates.length),
            reason: 'Consecutive dates should form a streak equal to count');
      },
    );

    /// **Feature: islamic-prayer-system, Property 9: Jamaah Quality Multiplier**
    /// **Validates: Requirements 4.5**
    ///
    /// *For any* two identical sequences of prayer events where one sequence has all
    /// Jamaah flags set to true and the other has all set to false, the Jamaah rate
    /// for the first sequence SHALL be 100% and for the second SHALL be 0%.
    Glados(any.intInRange(1, 20)).test(
      'Property 9: Jamaah Quality Multiplier - Jamaah rate is 100% for all Jamaah, 0% for none',
      (eventCount) {
        final baseDate = DateTime(2024, 1, 1);
        
        // Create events with all Jamaah = true
        final jamaahEvents = List.generate(eventCount, (i) => PrayerEvent(
          prayerType: PrayerType.fajr,
          eventDate: baseDate.add(Duration(days: i)),
          eventTimestamp: DateTime(2024, 1, 1 + i, 5, 0),
          prayedInJamaah: true,
          withinTimeWindow: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        // Create events with all Jamaah = false
        final nonJamaahEvents = List.generate(eventCount, (i) => PrayerEvent(
          prayerType: PrayerType.fajr,
          eventDate: baseDate.add(Duration(days: i)),
          eventTimestamp: DateTime(2024, 1, 1 + i, 5, 0),
          prayedInJamaah: false,
          withinTimeWindow: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        final jamaahRate = prayerScoreService.calculateJamaahRate(jamaahEvents);
        final nonJamaahRate = prayerScoreService.calculateJamaahRate(nonJamaahEvents);

        expect(jamaahRate, equals(1.0),
            reason: 'Jamaah rate should be 100% when all prayers are in Jamaah');
        expect(nonJamaahRate, equals(0.0),
            reason: 'Jamaah rate should be 0% when no prayers are in Jamaah');
      },
    );

    /// **Feature: islamic-prayer-system, Property 10: Weekly Completion Percentage**
    /// **Validates: Requirements 4.6**
    ///
    /// *For any* prayer type and week date range, the weekly completion percentage
    /// SHALL equal (number of completed prayers / number of days in range) × 100,
    /// bounded between 0 and 100.
    Glados2(any.weekDateRange, any.weekEventCount).test(
      'Property 10: Weekly Completion Percentage - bounded between 0 and 100',
      (weekRange, eventCount) {
        final events = <PrayerEvent>[];
        
        // Create events for the specified count of days
        for (int i = 0; i < eventCount; i++) {
          final date = weekRange.start.add(Duration(days: i));
          events.add(PrayerEvent(
            prayerType: PrayerType.fajr,
            eventDate: date,
            eventTimestamp: DateTime(date.year, date.month, date.day, 5, 0),
            prayedInJamaah: false,
            withinTimeWindow: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }

        final percentage = prayerScoreService.calculateWeeklyCompletionPercentage(
          events,
          weekRange.start,
          weekRange.end,
        );

        // Percentage should be bounded between 0 and 100
        expect(percentage, greaterThanOrEqualTo(0.0),
            reason: 'Percentage should be >= 0');
        expect(percentage, lessThanOrEqualTo(100.0),
            reason: 'Percentage should be <= 100');

        // Calculate expected percentage
        final daysInRange = weekRange.end.difference(weekRange.start).inDays + 1;
        final expectedPercentage = (eventCount / daysInRange) * 100;
        
        expect(percentage, closeTo(expectedPercentage.clamp(0.0, 100.0), 0.0001),
            reason: 'Percentage should equal (completed / total) * 100');
      },
    );
  });

  group('PrayerScoreService Unit Tests', () {
    test('calculateMultiplier returns correct value for daily frequency', () {
      // For daily frequency (1.0), multiplier should be approximately 0.948
      final multiplier = prayerScoreService.calculateMultiplier(1.0);
      expect(multiplier, closeTo(0.948, 0.001));
    });

    test('calculateCheckmarkValue returns 0 for empty events', () {
      final value = prayerScoreService.calculateCheckmarkValue([]);
      expect(value, equals(0.0));
    });

    test('calculateCheckmarkValue returns 1.0 for non-Jamaah completion', () {
      final events = [
        PrayerEvent(
          prayerType: PrayerType.fajr,
          eventDate: DateTime(2024, 1, 15),
          eventTimestamp: DateTime(2024, 1, 15, 5, 0),
          prayedInJamaah: false,
          withinTimeWindow: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      final value = prayerScoreService.calculateCheckmarkValue(events);
      expect(value, equals(1.0));
    });

    test('calculateCheckmarkValue returns 1.0 (capped) for Jamaah completion', () {
      final events = [
        PrayerEvent(
          prayerType: PrayerType.fajr,
          eventDate: DateTime(2024, 1, 15),
          eventTimestamp: DateTime(2024, 1, 15, 5, 0),
          prayedInJamaah: true,
          withinTimeWindow: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      final value = prayerScoreService.calculateCheckmarkValue(events);
      // Jamaah multiplier is 1.2, but capped at 1.0
      expect(value, equals(1.0));
    });

    test('computeScore clamps result between 0 and 1', () {
      // Test upper bound
      final highScore = prayerScoreService.computeScore(1.0, 0.5, 1.0);
      expect(highScore, lessThanOrEqualTo(1.0));

      // Test lower bound
      final lowScore = prayerScoreService.computeScore(0.0, 0.5, 0.0);
      expect(lowScore, greaterThanOrEqualTo(0.0));
    });

    test('calculateStreaks returns 0 for empty events', () {
      final streaks = prayerScoreService.calculateStreaks([]);
      expect(streaks.currentStreak, equals(0));
      expect(streaks.longestStreak, equals(0));
    });

    test('calculateJamaahRate returns 0 for empty events', () {
      final rate = prayerScoreService.calculateJamaahRate([]);
      expect(rate, equals(0.0));
    });

    test('calculateOverallScore returns 0 for empty scores', () {
      final overall = prayerScoreService.calculateOverallScore({});
      expect(overall, equals(0.0));
    });

    test('calculateOverallScore handles partial scores correctly', () {
      // Only 2 prayers have scores
      final scores = {
        PrayerType.fajr: 0.8,
        PrayerType.dhuhr: 0.6,
      };
      
      final overall = prayerScoreService.calculateOverallScore(scores);
      // Should average across all 5 prayers (missing ones count as 0)
      final expected = (0.8 + 0.6 + 0.0 + 0.0 + 0.0) / 5.0;
      expect(overall, closeTo(expected, 0.0001));
    });

    test('calculateWeeklyCompletionPercentage handles empty events', () {
      final percentage = prayerScoreService.calculateWeeklyCompletionPercentage(
        [],
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 7),
      );
      expect(percentage, equals(0.0));
    });

    test('calculateWeeklyCompletionPercentage returns 100 for full week', () {
      final events = List.generate(7, (i) => PrayerEvent(
        prayerType: PrayerType.fajr,
        eventDate: DateTime(2024, 1, 1 + i),
        eventTimestamp: DateTime(2024, 1, 1 + i, 5, 0),
        prayedInJamaah: false,
        withinTimeWindow: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final percentage = prayerScoreService.calculateWeeklyCompletionPercentage(
        events,
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 7),
      );
      expect(percentage, equals(100.0));
    });
  });
}
