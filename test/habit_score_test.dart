import 'package:glados/glados.dart';
import 'package:numu/features/habits/models/habit_score.dart';

/// Custom generator for HabitScore
extension HabitScoreGenerators on Any {
  /// Generator for valid habit IDs (positive integers)
  Generator<int> get habitId => intInRange(1, 1000000);

  /// Generator for valid scores (0.0 to 1.0)
  Generator<double> get validScore => doubleInRange(0.0, 1.0);

  /// Generator for DateTime values
  Generator<DateTime> get dateTime => combine3(
        intInRange(2020, 2030), // year
        intInRange(1, 12), // month
        intInRange(1, 28), // day (safe for all months)
        (year, month, day) => DateTime(year, month, day),
      );

  /// Generator for optional DateTime values
  Generator<DateTime?> get optionalDateTime => either(
        always<DateTime?>(null),
        dateTime.map((dt) => dt as DateTime?),
      );

  /// Generator for valid HabitScore objects
  Generator<HabitScore> get habitScore => combine4(
        habitId,
        validScore,
        dateTime,
        optionalDateTime,
        (id, score, calculatedAt, lastEventDate) => HabitScore(
          habitId: id,
          score: score,
          calculatedAt: calculatedAt,
          lastEventDate: lastEventDate,
        ),
      );
}

void main() {
  group('HabitScore Property Tests', () {
    /// **Feature: habit-score-system, Property 9: Score serialization round-trip**
    /// **Validates: Requirements 7.3, 7.4**
    ///
    /// *For any* valid HabitScore object, serializing to map and deserializing
    /// back SHALL produce an equivalent object
    Glados(any.habitScore).test(
      'Property 9: Score serialization round-trip - toMap then fromMap produces equivalent object',
      (habitScore) {
        // Serialize to map
        final map = habitScore.toMap();

        // Deserialize back to HabitScore
        final restored = HabitScore.fromMap(map);

        // Verify all fields are preserved
        expect(restored.habitId, equals(habitScore.habitId));
        expect(restored.score, equals(habitScore.score));
        expect(restored.calculatedAt, equals(habitScore.calculatedAt));
        expect(restored.lastEventDate, equals(habitScore.lastEventDate));

        // Verify equality
        expect(restored, equals(habitScore));
      },
    );
  });

  group('HabitScore Unit Tests', () {
    test('percentage getter returns correct value', () {
      final score = HabitScore(
        habitId: 1,
        score: 0.75,
        calculatedAt: DateTime.now(),
      );
      expect(score.percentage, equals(75));
    });

    test('percentage getter rounds correctly', () {
      final score = HabitScore(
        habitId: 1,
        score: 0.756,
        calculatedAt: DateTime.now(),
      );
      expect(score.percentage, equals(76));
    });

    test('percentage getter handles boundary values', () {
      expect(
        HabitScore(habitId: 1, score: 0.0, calculatedAt: DateTime.now())
            .percentage,
        equals(0),
      );
      expect(
        HabitScore(habitId: 1, score: 1.0, calculatedAt: DateTime.now())
            .percentage,
        equals(100),
      );
    });

    test('copyWith creates new instance with updated values', () {
      final original = HabitScore(
        habitId: 1,
        score: 0.5,
        calculatedAt: DateTime(2024, 1, 1),
        lastEventDate: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(score: 0.8);

      expect(updated.habitId, equals(1));
      expect(updated.score, equals(0.8));
      expect(updated.calculatedAt, equals(DateTime(2024, 1, 1)));
      expect(updated.lastEventDate, equals(DateTime(2024, 1, 1)));
    });

    test('toString returns readable representation', () {
      final score = HabitScore(
        habitId: 1,
        score: 0.75,
        calculatedAt: DateTime(2024, 1, 1),
      );
      expect(score.toString(), contains('habitId: 1'));
      expect(score.toString(), contains('score: 0.75'));
      expect(score.toString(), contains('percentage: 75%'));
    });
  });
}
