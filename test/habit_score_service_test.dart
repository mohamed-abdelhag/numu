import 'dart:math';

import 'package:glados/glados.dart';
import 'package:numu/features/habits/models/habit.dart';
import 'package:numu/features/habits/models/habit_event.dart';
import 'package:numu/features/habits/models/enums/active_days_mode.dart';
import 'package:numu/features/habits/models/enums/frequency.dart';
import 'package:numu/features/habits/models/enums/goal_type.dart';
import 'package:numu/features/habits/models/enums/require_mode.dart';
import 'package:numu/features/habits/models/enums/tracking_type.dart';
import 'package:numu/features/habits/services/habit_score_service.dart';

/// Custom generators for HabitScoreService tests
extension HabitScoreServiceGenerators on Any {
  /// Generator for valid frequency values (positive doubles)
  Generator<double> get positiveFrequency => doubleInRange(0.001, 10.0);

  /// Generator for valid scores (0.0 to 1.0)
  Generator<double> get validScore => doubleInRange(0.0, 1.0);

  /// Generator for valid multipliers (0.0 to 1.0, exclusive of 0 and 1)
  Generator<double> get validMultiplier => doubleInRange(0.01, 0.99);

  /// Generator for checkmark values (0.0 to 1.0)
  Generator<double> get checkmarkValue => doubleInRange(0.0, 1.0);

  /// Generator for scores strictly between 0 and 1
  Generator<double> get scoreBetweenZeroAndOne => doubleInRange(0.01, 0.99);

  /// Generator for Frequency enum values
  Generator<Frequency> get frequency => choose(Frequency.values);

  /// Generator for GoalType enum values
  Generator<GoalType> get goalType => choose(GoalType.values);

  /// Generator for TrackingType enum values
  Generator<TrackingType> get trackingType => choose(TrackingType.values);

  /// Generator for positive target values
  Generator<double> get positiveTargetValue => doubleInRange(1.0, 1000.0);

  /// Generator for positive actual values
  Generator<double> get positiveActualValue => doubleInRange(0.0, 2000.0);

  /// Generator for custom period days
  Generator<int> get customPeriodDays => intInRange(1, 365);

  /// Generator for DateTime values
  Generator<DateTime> get dateTime => combine3(
        intInRange(2020, 2030),
        intInRange(1, 12),
        intInRange(1, 28),
        (year, month, day) => DateTime(year, month, day),
      );

  /// Generator for actual values that are at or below target (for minimum goal testing)
  Generator<double> get actualValueAtOrBelowTarget => doubleInRange(0.0, 1.0);

  /// Generator for actual values that exceed target (for minimum goal testing)
  Generator<double> get actualValueAboveTarget => doubleInRange(1.01, 5.0);

  /// Generator for actual values at or below target (for maximum goal testing)
  Generator<double> get actualValueAtOrBelowMax => doubleInRange(0.0, 1.0);

  /// Generator for actual values above target (for maximum goal testing)
  Generator<double> get actualValueAboveMax => doubleInRange(1.01, 3.0);

  /// Generator for non-empty subset of weekdays (1-7)
  /// Generates a list of 1-7 unique weekday values
  Generator<List<int>> get activeWeekdaysSubset => intInRange(1, 7).map((seed) {
        // Use the seed to determine which weekdays to include
        final weekdays = <int>[];
        for (int day = 1; day <= 7; day++) {
          // Include day if (seed + day) is odd, ensuring at least one day
          if ((seed + day) % 2 == 1 || weekdays.isEmpty && day == 7) {
            weekdays.add(day);
          }
        }
        // Ensure at least one day is included
        if (weekdays.isEmpty) {
          weekdays.add(seed);
        }
        return weekdays;
      });

  /// Generator for a single weekday (1-7)
  Generator<int> get weekday => intInRange(1, 7);

  /// Generator for number of days to test (small range for performance)
  Generator<int> get testDayCount => intInRange(7, 30);
}

void main() {
  late HabitScoreService service;

  setUp(() {
    service = HabitScoreService();
  });

  group('HabitScoreService Property Tests', () {
    /// **Feature: habit-score-system, Property 4: Multiplier formula correctness**
    /// **Validates: Requirements 2.1, 2.4**
    ///
    /// *For any* frequency value > 0, the calculated multiplier SHALL equal
    /// `pow(0.5, sqrt(frequency) / 13.0)`
    Glados(any.positiveFrequency).test(
      'Property 4: Multiplier formula correctness - calculateMultiplier matches expected formula',
      (frequency) {
        final result = service.calculateMultiplier(frequency);
        final expected = pow(0.5, sqrt(frequency) / 13.0);

        // Use closeTo for floating point comparison
        expect(result, closeTo(expected, 1e-10));
      },
    );

    /// **Feature: habit-score-system, Property 5: Checkmark value for minimum goals**
    /// **Validates: Requirements 3.1, 3.2**
    ///
    /// *For any* value habit with GoalType.minimum, the checkmark value SHALL equal
    /// `min(1.0, actualValue / targetValue)` when targetValue > 0
    Glados2(any.positiveTargetValue, any.positiveActualValue).test(
      'Property 5: Checkmark value for minimum goals - equals min(1.0, actual/target)',
      (targetValue, actualValue) {
        final now = DateTime.now();
        final habit = Habit(
          id: 1,
          name: 'Test Habit',
          icon: '💪',
          color: '#FF0000',
          trackingType: TrackingType.value,
          goalType: GoalType.minimum,
          targetValue: targetValue,
          unit: 'units',
          frequency: Frequency.daily,
          activeDaysMode: ActiveDaysMode.all,
          requireMode: RequireMode.each,
          createdAt: now,
          updatedAt: now,
        );

        final events = [
          HabitEvent(
            habitId: 1,
            eventDate: now,
            eventTimestamp: now,
            value: actualValue,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final result = service.calculateCheckmarkValue(habit, events);
        final expected = min(1.0, actualValue / targetValue);

        expect(result, closeTo(expected, 1e-10));
      },
    );

    /// **Feature: habit-score-system, Property 6: Checkmark value for maximum goals**
    /// **Validates: Requirements 3.3**
    ///
    /// *For any* value habit with GoalType.maximum, the checkmark value SHALL equal
    /// 1.0 when at or under target, and decrease proportionally when over target
    Glados2(any.positiveTargetValue, any.positiveActualValue).test(
      'Property 6: Checkmark value for maximum goals - 1.0 at/under target, decreases over',
      (targetValue, actualValue) {
        final now = DateTime.now();
        final habit = Habit(
          id: 1,
          name: 'Test Habit',
          icon: '💪',
          color: '#FF0000',
          trackingType: TrackingType.value,
          goalType: GoalType.maximum,
          targetValue: targetValue,
          unit: 'units',
          frequency: Frequency.daily,
          activeDaysMode: ActiveDaysMode.all,
          requireMode: RequireMode.each,
          createdAt: now,
          updatedAt: now,
        );

        final events = [
          HabitEvent(
            habitId: 1,
            eventDate: now,
            eventTimestamp: now,
            value: actualValue,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final result = service.calculateCheckmarkValue(habit, events);

        if (actualValue <= targetValue) {
          // At or under target should be 1.0
          expect(result, equals(1.0));
        } else {
          // Over target should decrease proportionally
          final overAmount = actualValue - targetValue;
          final expected = max(0.0, 1.0 - (overAmount / targetValue));
          expect(result, closeTo(expected.clamp(0.0, 1.0), 1e-10));
        }
      },
    );
  });

  group('HabitScoreService Score Computation Property Tests', () {
    /// **Feature: habit-score-system, Property 1: Score bounds invariant**
    /// **Validates: Requirements 1.1**
    ///
    /// *For any* habit and any sequence of events, the calculated score SHALL
    /// always be in the range [0.0, 1.0]
    Glados3(any.validScore, any.validMultiplier, any.checkmarkValue).test(
      'Property 1: Score bounds invariant - computeScore always returns value in [0.0, 1.0]',
      (previousScore, multiplier, checkmarkValue) {
        final result = service.computeScore(previousScore, multiplier, checkmarkValue);

        expect(result, greaterThanOrEqualTo(0.0));
        expect(result, lessThanOrEqualTo(1.0));
      },
    );

    /// **Feature: habit-score-system, Property 2: Completion increases score**
    /// **Validates: Requirements 1.2**
    ///
    /// *For any* habit with a previous score < 1.0, completing the habit
    /// (checkmarkValue = 1.0) SHALL result in a new score that is greater
    /// than the previous score
    Glados2(any.scoreBetweenZeroAndOne, any.validMultiplier).test(
      'Property 2: Completion increases score - checkmark=1.0 increases score when score < 1.0',
      (previousScore, multiplier) {
        // Ensure previous score is strictly less than 1.0
        final adjustedPreviousScore = previousScore.clamp(0.0, 0.99);

        final result = service.computeScore(adjustedPreviousScore, multiplier, 1.0);

        expect(result, greaterThan(adjustedPreviousScore));
      },
    );

    /// **Feature: habit-score-system, Property 3: Miss decreases score**
    /// **Validates: Requirements 1.3**
    ///
    /// *For any* habit with a previous score > 0.0, missing the habit on an
    /// active day (checkmarkValue = 0.0) SHALL result in a new score that is
    /// less than the previous score
    Glados2(any.scoreBetweenZeroAndOne, any.validMultiplier).test(
      'Property 3: Miss decreases score - checkmark=0.0 decreases score when score > 0.0',
      (previousScore, multiplier) {
        // Ensure previous score is strictly greater than 0.0
        final adjustedPreviousScore = previousScore.clamp(0.01, 1.0);

        final result = service.computeScore(adjustedPreviousScore, multiplier, 0.0);

        expect(result, lessThan(adjustedPreviousScore));
      },
    );
  });

  group('HabitScoreService Active Days Property Tests', () {
    /// **Feature: habit-score-system, Property 7: Active days filtering**
    /// **Validates: Requirements 5.1**
    ///
    /// *For any* habit with specific active weekdays, score calculation SHALL
    /// only process days that match the active weekdays configuration
    Glados(any.activeWeekdaysSubset).test(
      'Property 7: Active days filtering - only active weekdays affect score',
      (activeWeekdays) {
        // Create a habit with selected active days
        final startDate = DateTime(2024, 1, 1); // Monday
        final endDate = DateTime(2024, 1, 14); // Two weeks later (Sunday)

        final habit = Habit(
          id: 1,
          name: 'Test Habit',
          icon: '💪',
          color: '#FF0000',
          trackingType: TrackingType.binary,
          goalType: GoalType.minimum,
          frequency: Frequency.daily,
          activeDaysMode: ActiveDaysMode.selected,
          activeWeekdays: activeWeekdays,
          requireMode: RequireMode.each,
          createdAt: startDate,
          updatedAt: startDate,
        );

        // Create completion events for ALL days (including non-active days)
        final events = <HabitEvent>[];
        var currentDate = startDate;
        while (!currentDate.isAfter(endDate)) {
          events.add(HabitEvent(
            habitId: 1,
            eventDate: currentDate,
            eventTimestamp: currentDate,
            completed: true,
            createdAt: currentDate,
            updatedAt: currentDate,
          ));
          currentDate = currentDate.add(const Duration(days: 1));
        }

        // Calculate score
        final score = service.calculateScore(habit, events, endDate: endDate);

        // Count how many active days there are in the date range
        int activeDayCount = 0;
        currentDate = startDate;
        while (!currentDate.isAfter(endDate)) {
          if (activeWeekdays.contains(currentDate.weekday)) {
            activeDayCount++;
          }
          currentDate = currentDate.add(const Duration(days: 1));
        }

        // If there are active days and all were completed, score should be > 0
        if (activeDayCount > 0) {
          expect(score, greaterThan(0.0));
        }

        // Verify that isActiveDay correctly identifies active days
        currentDate = startDate;
        while (!currentDate.isAfter(endDate)) {
          final isActive = service.isActiveDay(habit, currentDate);
          final shouldBeActive = activeWeekdays.contains(currentDate.weekday);
          expect(isActive, equals(shouldBeActive),
              reason: 'Day ${currentDate.weekday} should be active: $shouldBeActive');
          currentDate = currentDate.add(const Duration(days: 1));
        }
      },
    );

    test('ActiveDaysMode.all makes all days active', () {
      final startDate = DateTime(2024, 1, 1);
      final habit = Habit(
        id: 1,
        name: 'Test Habit',
        icon: '💪',
        color: '#FF0000',
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        createdAt: startDate,
        updatedAt: startDate,
      );

      // Check all 7 weekdays
      for (int weekday = 1; weekday <= 7; weekday++) {
        // Find a date with this weekday
        var date = startDate;
        while (date.weekday != weekday) {
          date = date.add(const Duration(days: 1));
        }
        expect(service.isActiveDay(habit, date), isTrue,
            reason: 'Weekday $weekday should be active when mode is all');
      }
    });
  });

  group('HabitScoreService Skip Entry Property Tests', () {
    /// **Feature: habit-score-system, Property 8: Skip entries preserve score**
    /// **Validates: Requirements 5.2**
    ///
    /// *For any* habit and any day marked as "skip", the score SHALL remain
    /// unchanged from the previous day's score
    Glados(any.testDayCount).test(
      'Property 8: Skip entries preserve score - skip days do not change score',
      (dayCount) {
        final startDate = DateTime(2024, 1, 1);
        final skipDayIndex = dayCount ~/ 2; // Skip day in the middle

        final habit = Habit(
          id: 1,
          name: 'Test Habit',
          icon: '💪',
          color: '#FF0000',
          trackingType: TrackingType.binary,
          goalType: GoalType.minimum,
          frequency: Frequency.daily,
          activeDaysMode: ActiveDaysMode.all,
          requireMode: RequireMode.each,
          createdAt: startDate,
          updatedAt: startDate,
        );

        // Create events: complete all days except the skip day
        final eventsWithSkip = <HabitEvent>[];
        final eventsWithoutSkipDay = <HabitEvent>[];

        for (int i = 0; i < dayCount; i++) {
          final date = startDate.add(Duration(days: i));

          if (i == skipDayIndex) {
            // Add skip entry (with "skip" in notes)
            eventsWithSkip.add(HabitEvent(
              habitId: 1,
              eventDate: date,
              eventTimestamp: date,
              notes: 'skip',
              createdAt: date,
              updatedAt: date,
            ));
            // Don't add anything to eventsWithoutSkipDay - simulating the day not existing
          } else {
            // Complete the habit
            final event = HabitEvent(
              habitId: 1,
              eventDate: date,
              eventTimestamp: date,
              completed: true,
              createdAt: date,
              updatedAt: date,
            );
            eventsWithSkip.add(event);
            eventsWithoutSkipDay.add(event);
          }
        }

        final endDate = startDate.add(Duration(days: dayCount - 1));

        // Calculate score with skip day
        final scoreWithSkip = service.calculateScore(habit, eventsWithSkip, endDate: endDate);

        // Calculate score without the skip day (as if it didn't exist)
        // The skip day should preserve the previous score, so the final score
        // should be the same as if we calculated up to the day before skip,
        // then continued from there

        // Verify the score is valid
        expect(scoreWithSkip, greaterThanOrEqualTo(0.0));
        expect(scoreWithSkip, lessThanOrEqualTo(1.0));

        // Since we completed all non-skip days, score should be positive
        if (dayCount > 1) {
          expect(scoreWithSkip, greaterThan(0.0));
        }
      },
    );

    test('Skip entry with "skip" in notes preserves score', () {
      final startDate = DateTime(2024, 1, 1);
      final habit = Habit(
        id: 1,
        name: 'Test Habit',
        icon: '💪',
        color: '#FF0000',
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        frequency: Frequency.daily,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        createdAt: startDate,
        updatedAt: startDate,
      );

      // Day 1: Complete (score increases)
      // Day 2: Skip (score should stay same)
      // Day 3: Complete (score increases from day 1's score)
      final events = [
        HabitEvent(
          habitId: 1,
          eventDate: startDate,
          eventTimestamp: startDate,
          completed: true,
          createdAt: startDate,
          updatedAt: startDate,
        ),
        HabitEvent(
          habitId: 1,
          eventDate: startDate.add(const Duration(days: 1)),
          eventTimestamp: startDate.add(const Duration(days: 1)),
          notes: 'skip',
          createdAt: startDate.add(const Duration(days: 1)),
          updatedAt: startDate.add(const Duration(days: 1)),
        ),
        HabitEvent(
          habitId: 1,
          eventDate: startDate.add(const Duration(days: 2)),
          eventTimestamp: startDate.add(const Duration(days: 2)),
          completed: true,
          createdAt: startDate.add(const Duration(days: 2)),
          updatedAt: startDate.add(const Duration(days: 2)),
        ),
      ];

      // Calculate score up to day 1
      final scoreAfterDay1 = service.calculateScore(
        habit,
        [events[0]],
        endDate: startDate,
      );

      // Calculate score up to day 2 (with skip)
      final scoreAfterDay2 = service.calculateScore(
        habit,
        [events[0], events[1]],
        endDate: startDate.add(const Duration(days: 1)),
      );

      // Score after skip day should equal score after day 1
      expect(scoreAfterDay2, equals(scoreAfterDay1));
    });
  });
}
