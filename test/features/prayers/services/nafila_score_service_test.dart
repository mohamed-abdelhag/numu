import 'package:glados/glados.dart';
import 'package:numu/features/islamic/models/nafila_event.dart';
import 'package:numu/features/islamic/models/enums/nafila_type.dart';
import 'package:numu/features/islamic/services/nafila_score_service.dart';

/// Custom generators for NafilaScoreService tests
extension NafilaScoreGenerators on Any {
  /// Generator for NafilaType enum values (excluding custom for defined types)
  Generator<NafilaType> get nafilaType => choose([
        NafilaType.sunnahFajr,
        NafilaType.duha,
        NafilaType.shafiWitr,
      ]);

  /// Generator for a valid date (date-only, no time component)
  Generator<DateTime> get dateOnly => intInRange(2020, 2025).bind((year) =>
      intInRange(1, 12).bind((month) => intInRange(1, 28).map((day) =>
          DateTime(year, month, day))));

  /// Generator for rakat count within valid range
  Generator<int> get rakatCount => intInRange(2, 12);

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

}

void main() {
  late NafilaScoreService service;

  setUp(() {
    service = NafilaScoreService();
  });

  group('NafilaScoreService Property Tests', () {
    /// **Feature: nafila-prayer-system, Property 7: Streak Calculation Consistency**
    /// **Validates: Requirements 4.4**
    ///
    /// *For any* sequence of NafilaEvent objects for a given NafilaType, the calculated
    /// current streak should equal the count of consecutive days with completions ending
    /// at the most recent event date.
    Glados(any.consecutiveDates(1, 20)).test(
      'Property 7: Streak Calculation Consistency - longest streak >= current streak',
      (dates) {
        // Create events for all dates
        final events = dates.map((date) => NafilaEvent(
              nafilaType: NafilaType.sunnahFajr,
              eventDate: date,
              eventTimestamp: DateTime(date.year, date.month, date.day, 5, 0),
              rakatCount: 2,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )).toList();

        final streaks = service.calculateStreak(events, endDate: dates.last);

        // Longest streak should always be >= current streak
        expect(streaks.longestStreak, greaterThanOrEqualTo(streaks.currentStreak),
            reason: 'Longest streak must be >= current streak');

        // For consecutive dates, longest streak should equal the number of dates
        expect(streaks.longestStreak, equals(dates.length),
            reason: 'Consecutive dates should form a streak equal to count');
      },
    );

    Glados(any.intInRange(1, 15)).test(
      'Property 7: Streak Calculation Consistency - current streak counts from end date',
      (numDays) {
        final endDate = DateTime(2024, 6, 15);
        final events = <NafilaEvent>[];

        // Create consecutive events ending at endDate
        for (int i = numDays - 1; i >= 0; i--) {
          final date = endDate.subtract(Duration(days: i));
          events.add(NafilaEvent(
            nafilaType: NafilaType.duha,
            eventDate: date,
            eventTimestamp: DateTime(date.year, date.month, date.day, 8, 0),
            rakatCount: 4,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }

        final streaks = service.calculateStreak(events, endDate: endDate);

        // Current streak should equal numDays since all are consecutive ending at endDate
        expect(streaks.currentStreak, equals(numDays),
            reason: 'Current streak should count consecutive days ending at endDate');
      },
    );


    /// **Feature: nafila-prayer-system, Property 8: Rakat Aggregation Accuracy**
    /// **Validates: Requirements 4.5, 4.6**
    ///
    /// *For any* list of NafilaEvent objects of a given type, the total rakats should
    /// equal the sum of all rakatCount values, and the average should equal total
    /// divided by event count.
    Glados(any.intInRange(1, 20)).test(
      'Property 8: Rakat Aggregation Accuracy - total rakats equals sum',
      (eventCount) {
        final baseDate = DateTime(2024, 1, 1);
        final events = <NafilaEvent>[];
        int expectedTotal = 0;

        // Create events with varying rakat counts
        for (int i = 0; i < eventCount; i++) {
          final rakats = 2 + (i % 10); // 2-11 rakats
          expectedTotal += rakats;
          events.add(NafilaEvent(
            nafilaType: NafilaType.shafiWitr,
            eventDate: baseDate.add(Duration(days: i)),
            eventTimestamp: DateTime(2024, 1, 1 + i, 21, 0),
            rakatCount: rakats,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }

        final totalRakats = service.calculateTotalRakats(events);
        final averageRakats = service.calculateAverageRakats(events);

        expect(totalRakats, equals(expectedTotal),
            reason: 'Total rakats should equal sum of all rakatCount values');

        expect(averageRakats, closeTo(expectedTotal / eventCount, 0.0001),
            reason: 'Average rakats should equal total / count');
      },
    );

    Glados2(any.intInRange(1, 10), any.intInRange(2, 12)).test(
      'Property 8: Rakat Aggregation Accuracy - uniform rakats',
      (eventCount, uniformRakats) {
        final baseDate = DateTime(2024, 1, 1);
        final events = List.generate(eventCount, (i) => NafilaEvent(
              nafilaType: NafilaType.duha,
              eventDate: baseDate.add(Duration(days: i)),
              eventTimestamp: DateTime(2024, 1, 1 + i, 9, 0),
              rakatCount: uniformRakats,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));

        final totalRakats = service.calculateTotalRakats(events);
        final averageRakats = service.calculateAverageRakats(events);

        expect(totalRakats, equals(eventCount * uniformRakats),
            reason: 'Total should be count * uniform value');

        expect(averageRakats, closeTo(uniformRakats.toDouble(), 0.0001),
            reason: 'Average should equal uniform value when all same');
      },
    );
  });

  group('NafilaScoreService Unit Tests', () {
    test('calculateMultiplier returns correct value for daily frequency', () {
      final multiplier = service.calculateMultiplier(1.0);
      expect(multiplier, closeTo(0.948, 0.001));
    });

    test('calculateCheckmarkValue returns 0 for empty events', () {
      final value = service.calculateCheckmarkValue([]);
      expect(value, equals(0.0));
    });

    test('calculateCheckmarkValue returns 1.0 for non-empty events', () {
      final events = [
        NafilaEvent(
          nafilaType: NafilaType.sunnahFajr,
          eventDate: DateTime(2024, 1, 15),
          eventTimestamp: DateTime(2024, 1, 15, 5, 0),
          rakatCount: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      final value = service.calculateCheckmarkValue(events);
      expect(value, equals(1.0));
    });

    test('computeScore clamps result between 0 and 1', () {
      final highScore = service.computeScore(1.0, 0.5, 1.0);
      expect(highScore, lessThanOrEqualTo(1.0));

      final lowScore = service.computeScore(0.0, 0.5, 0.0);
      expect(lowScore, greaterThanOrEqualTo(0.0));
    });

    test('calculateStreak returns 0 for empty events', () {
      final streaks = service.calculateStreak([]);
      expect(streaks.currentStreak, equals(0));
      expect(streaks.longestStreak, equals(0));
    });

    test('calculateTotalRakats returns 0 for empty events', () {
      final total = service.calculateTotalRakats([]);
      expect(total, equals(0));
    });

    test('calculateAverageRakats returns 0 for empty events', () {
      final average = service.calculateAverageRakats([]);
      expect(average, equals(0.0));
    });

    test('calculateScore returns 0 for empty events', () {
      final score = service.calculateScore(NafilaType.sunnahFajr, []);
      expect(score, equals(0.0));
    });

    test('calculateStreak handles gap in dates correctly', () {
      final events = [
        NafilaEvent(
          nafilaType: NafilaType.duha,
          eventDate: DateTime(2024, 1, 1),
          eventTimestamp: DateTime(2024, 1, 1, 8, 0),
          rakatCount: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        NafilaEvent(
          nafilaType: NafilaType.duha,
          eventDate: DateTime(2024, 1, 2),
          eventTimestamp: DateTime(2024, 1, 2, 8, 0),
          rakatCount: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        // Gap on Jan 3
        NafilaEvent(
          nafilaType: NafilaType.duha,
          eventDate: DateTime(2024, 1, 4),
          eventTimestamp: DateTime(2024, 1, 4, 8, 0),
          rakatCount: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        NafilaEvent(
          nafilaType: NafilaType.duha,
          eventDate: DateTime(2024, 1, 5),
          eventTimestamp: DateTime(2024, 1, 5, 8, 0),
          rakatCount: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final streaks = service.calculateStreak(events, endDate: DateTime(2024, 1, 5));

      // Current streak should be 2 (Jan 4-5)
      expect(streaks.currentStreak, equals(2));
      // Longest streak should be 2 (either Jan 1-2 or Jan 4-5)
      expect(streaks.longestStreak, equals(2));
    });
  });
}
