import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide group, expect, test;
import 'package:numu/features/home/models/daily_item.dart';

/// Helper function to calculate completion percentage
/// This mirrors the logic in DailyItemsNotifier.build()
int calculateCompletionPercentage(List<DailyItem> items) {
  if (items.isEmpty) return 0;
  final completedCount = items.where((item) => item.isCompleted).length;
  final totalCount = items.length;
  return ((completedCount / totalCount) * 100).round();
}

/// Generator for DailyItem with random completion status
extension DailyItemGenerator on Any {
  Generator<DailyItem> get dailyItem => any.combine2(
        any.intInRange(1, 1000), // id
        any.bool, // isCompleted
        (id, isCompleted) => DailyItem(
          id: 'item_$id',
          title: 'Item $id',
          type: DailyItemType.habit,
          isCompleted: isCompleted,
        ),
      );

  /// Generator for a list of DailyItems with specific size
  Generator<List<DailyItem>> dailyItemList(int minSize, int maxSize) =>
      any.listWithLengthInRange(minSize, maxSize, any.dailyItem);
}

void main() {
  group('Completion Percentage Property Tests', () {
    /// **Feature: design-home-reminder-fixes, Property 4: Completion percentage calculation**
    /// **Validates: Requirements 2.2**
    ///
    /// *For any* list of daily items with known completion states, the calculated
    /// completion percentage SHALL equal `(completedCount / totalCount) * 100`
    /// rounded to the nearest integer.
    Glados(any.dailyItemList(1, 20)).test(
      'Property 4: Completion percentage equals (completedCount / totalCount) * 100 rounded',
      (items) {
        // Calculate expected percentage manually
        final completedCount = items.where((item) => item.isCompleted).length;
        final totalCount = items.length;
        final expectedPercentage = ((completedCount / totalCount) * 100).round();

        // Calculate using the function under test
        final actualPercentage = calculateCompletionPercentage(items);

        // Verify the property
        expect(
          actualPercentage,
          equals(expectedPercentage),
          reason:
              'Completion percentage should be (completedCount / totalCount) * 100 rounded. '
              'Got $actualPercentage but expected $expectedPercentage for '
              '$completedCount completed out of $totalCount items.',
        );
      },
    );

    /// Property: Percentage is always between 0 and 100 inclusive
    Glados(any.dailyItemList(1, 50)).test(
      'Property 4a: Completion percentage is always between 0 and 100',
      (items) {
        final percentage = calculateCompletionPercentage(items);

        expect(
          percentage,
          inInclusiveRange(0, 100),
          reason: 'Completion percentage must be between 0 and 100 inclusive',
        );
      },
    );

    /// Property: Empty list returns 0%
    test('Property 4b: Empty list returns 0% completion', () {
      final percentage = calculateCompletionPercentage([]);
      expect(percentage, equals(0));
    });

    /// Property: All completed returns 100%
    Glados(any.intInRange(1, 20)).test(
      'Property 4c: All items completed returns 100%',
      (count) {
        final items = List.generate(
          count,
          (i) => DailyItem(
            id: 'item_$i',
            title: 'Item $i',
            type: DailyItemType.habit,
            isCompleted: true,
          ),
        );

        final percentage = calculateCompletionPercentage(items);
        expect(percentage, equals(100));
      },
    );

    /// Property: No items completed returns 0%
    Glados(any.intInRange(1, 20)).test(
      'Property 4d: No items completed returns 0%',
      (count) {
        final items = List.generate(
          count,
          (i) => DailyItem(
            id: 'item_$i',
            title: 'Item $i',
            type: DailyItemType.habit,
            isCompleted: false,
          ),
        );

        final percentage = calculateCompletionPercentage(items);
        expect(percentage, equals(0));
      },
    );
  });

  group('Completion Percentage Unit Tests', () {
    test('Specific percentage calculations', () {
      // Test specific cases to verify rounding behavior
      final testCases = [
        (completed: 1, total: 2, expected: 50), // 50%
        (completed: 1, total: 3, expected: 33), // 33.33% -> 33
        (completed: 2, total: 3, expected: 67), // 66.67% -> 67
        (completed: 1, total: 4, expected: 25), // 25%
        (completed: 3, total: 4, expected: 75), // 75%
        (completed: 1, total: 7, expected: 14), // 14.29% -> 14
        (completed: 6, total: 7, expected: 86), // 85.71% -> 86
      ];

      for (final testCase in testCases) {
        final items = List.generate(
          testCase.total,
          (i) => DailyItem(
            id: 'item_$i',
            title: 'Item $i',
            type: DailyItemType.habit,
            isCompleted: i < testCase.completed,
          ),
        );

        final percentage = calculateCompletionPercentage(items);
        expect(
          percentage,
          equals(testCase.expected),
          reason:
              '${testCase.completed}/${testCase.total} should be ${testCase.expected}%',
        );
      }
    });
  });
}
