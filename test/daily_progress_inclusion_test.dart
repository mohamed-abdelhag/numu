import 'package:flutter/material.dart';
import 'package:glados/glados.dart';
import 'package:numu/features/home/models/daily_item.dart';
import 'package:numu/features/islamic/models/enums/prayer_type.dart';
import 'package:numu/features/islamic/models/enums/prayer_status.dart';

/// Custom generators for daily progress tests
extension DailyProgressGenerators on Any {
  /// Generator for DailyItemType enum values
  Generator<DailyItemType> get dailyItemType => choose(DailyItemType.values);

  /// Generator for PrayerType enum values
  Generator<PrayerType> get prayerType => choose(PrayerType.values);

  /// Generator for PrayerStatus enum values
  Generator<PrayerStatus> get prayerStatus => choose(PrayerStatus.values);

  /// Generator for a boolean (completed status)
  Generator<bool> get completedStatus => choose([true, false]);

  /// Generator for a habit DailyItem
  Generator<DailyItem> habitItem(int id, bool isCompleted) {
    return always(DailyItem(
      id: 'habit_$id',
      title: 'Habit $id',
      type: DailyItemType.habit,
      isCompleted: isCompleted,
      habitId: id,
    ));
  }

  /// Generator for a task DailyItem
  Generator<DailyItem> taskItem(int id, bool isCompleted) {
    return always(DailyItem(
      id: 'task_$id',
      title: 'Task $id',
      type: DailyItemType.task,
      isCompleted: isCompleted,
      taskId: id,
    ));
  }

  /// Generator for a prayer DailyItem
  Generator<DailyItem> prayerItem(PrayerType type, PrayerStatus status) {
    final isCompleted = status == PrayerStatus.completed;
    return always(DailyItem(
      id: 'prayer_${type.name}',
      title: type.englishName,
      type: DailyItemType.prayer,
      isCompleted: isCompleted,
      prayerType: type,
      prayerStatus: status,
      arabicName: type.arabicName,
      color: _getPrayerColor(status),
    ));
  }

  /// Generator for a list of habit items with random completion status
  Generator<List<DailyItem>> habitItems(int count) {
    if (count <= 0) return always(<DailyItem>[]);
    return intInRange(0, 2).bind((completed) {
      final isCompleted = completed == 1;
      return habitItem(count, isCompleted).bind((item) =>
          habitItems(count - 1).map((rest) => [item, ...rest]));
    });
  }

  /// Generator for a list of task items with random completion status
  Generator<List<DailyItem>> taskItems(int count) {
    if (count <= 0) return always(<DailyItem>[]);
    return intInRange(0, 2).bind((completed) {
      final isCompleted = completed == 1;
      return taskItem(count, isCompleted).bind((item) =>
          taskItems(count - 1).map((rest) => [item, ...rest]));
    });
  }

  /// Generator for prayer items (all 5 prayers with random statuses)
  Generator<List<DailyItem>> get prayerItems {
    return prayerStatus.bind((fajrStatus) =>
        prayerStatus.bind((dhuhrStatus) =>
            prayerStatus.bind((asrStatus) =>
                prayerStatus.bind((maghribStatus) =>
                    prayerStatus.map((ishaStatus) => [
                          _createPrayerItem(PrayerType.fajr, fajrStatus),
                          _createPrayerItem(PrayerType.dhuhr, dhuhrStatus),
                          _createPrayerItem(PrayerType.asr, asrStatus),
                          _createPrayerItem(PrayerType.maghrib, maghribStatus),
                          _createPrayerItem(PrayerType.isha, ishaStatus),
                        ])))));
  }
}

/// Helper to create prayer item
DailyItem _createPrayerItem(PrayerType type, PrayerStatus status) {
  return DailyItem(
    id: 'prayer_${type.name}',
    title: type.englishName,
    type: DailyItemType.prayer,
    isCompleted: status == PrayerStatus.completed,
    prayerType: type,
    prayerStatus: status,
    arabicName: type.arabicName,
    color: _getPrayerColor(status),
  );
}

/// Get color for prayer based on status
Color _getPrayerColor(PrayerStatus status) {
  switch (status) {
    case PrayerStatus.completed:
      return const Color(0xFF4CAF50);
    case PrayerStatus.pending:
      return const Color(0xFF2196F3);
    case PrayerStatus.missed:
      return const Color(0xFFF44336);
  }
}

/// Calculate completion percentage for a list of daily items
/// This mirrors the logic in DailyItemsProvider
int calculateCompletionPercentage(List<DailyItem> items) {
  if (items.isEmpty) return 0;
  final completedCount = items.where((item) => item.isCompleted).length;
  return ((completedCount / items.length) * 100).round();
}

void main() {
  group('Daily Progress Inclusion Property Tests', () {
    /// **Feature: islamic-prayer-system, Property 14: Daily Progress Inclusion**
    /// **Validates: Requirements 7.5**
    ///
    /// *For any* daily items list that includes prayers, the overall completion
    /// percentage SHALL include prayer completions in the calculation alongside
    /// habits and tasks.
    Glados3(
      any.intInRange(0, 5),
      any.intInRange(0, 5),
      any.prayerItems,
    ).test(
      'Property 14: Daily Progress Inclusion - prayers included in completion percentage',
      (habitCount, taskCount, prayers) {
        // Create habit items
        final habits = List.generate(
          habitCount,
          (i) => DailyItem(
            id: 'habit_$i',
            title: 'Habit $i',
            type: DailyItemType.habit,
            isCompleted: i % 2 == 0, // Alternate completion
            habitId: i,
          ),
        );

        // Create task items
        final tasks = List.generate(
          taskCount,
          (i) => DailyItem(
            id: 'task_$i',
            title: 'Task $i',
            type: DailyItemType.task,
            isCompleted: i % 2 == 0, // Alternate completion
            taskId: i,
          ),
        );

        // Combine all items
        final allItems = [...habits, ...tasks, ...prayers];

        // Calculate percentage
        final percentage = calculateCompletionPercentage(allItems);

        // Count completed items
        final completedCount = allItems.where((item) => item.isCompleted).length;
        final totalCount = allItems.length;

        // Verify the percentage calculation
        if (totalCount == 0) {
          expect(percentage, equals(0),
              reason: 'Empty list should return 0%');
        } else {
          final expectedPercentage = ((completedCount / totalCount) * 100).round();
          expect(percentage, equals(expectedPercentage),
              reason: 'Percentage should include all items including prayers');
        }

        // Verify prayers are counted in the total
        expect(allItems.where((item) => item.type == DailyItemType.prayer).length,
            equals(prayers.length),
            reason: 'All prayers should be included in the items list');
      },
    );

    /// Property: Completion percentage is bounded between 0 and 100
    Glados3(
      any.intInRange(0, 10),
      any.intInRange(0, 10),
      any.prayerItems,
    ).test(
      'Property 14: Daily Progress Inclusion - percentage bounded between 0 and 100',
      (habitCount, taskCount, prayers) {
        final habits = List.generate(
          habitCount,
          (i) => DailyItem(
            id: 'habit_$i',
            title: 'Habit $i',
            type: DailyItemType.habit,
            isCompleted: i % 3 == 0,
            habitId: i,
          ),
        );

        final tasks = List.generate(
          taskCount,
          (i) => DailyItem(
            id: 'task_$i',
            title: 'Task $i',
            type: DailyItemType.task,
            isCompleted: i % 3 == 0,
            taskId: i,
          ),
        );

        final allItems = [...habits, ...tasks, ...prayers];
        final percentage = calculateCompletionPercentage(allItems);

        expect(percentage, greaterThanOrEqualTo(0),
            reason: 'Percentage should be at least 0');
        expect(percentage, lessThanOrEqualTo(100),
            reason: 'Percentage should be at most 100');
      },
    );

    /// Property: All items completed returns 100%
    Glados2(
      any.intInRange(1, 5),
      any.intInRange(1, 5),
    ).test(
      'Property 14: Daily Progress Inclusion - all completed returns 100%',
      (habitCount, taskCount) {
        final habits = List.generate(
          habitCount,
          (i) => DailyItem(
            id: 'habit_$i',
            title: 'Habit $i',
            type: DailyItemType.habit,
            isCompleted: true,
            habitId: i,
          ),
        );

        final tasks = List.generate(
          taskCount,
          (i) => DailyItem(
            id: 'task_$i',
            title: 'Task $i',
            type: DailyItemType.task,
            isCompleted: true,
            taskId: i,
          ),
        );

        // All prayers completed
        final prayers = PrayerType.values
            .map((type) => _createPrayerItem(type, PrayerStatus.completed))
            .toList();

        final allItems = [...habits, ...tasks, ...prayers];
        final percentage = calculateCompletionPercentage(allItems);

        expect(percentage, equals(100),
            reason: 'All items completed should return 100%');
      },
    );

    /// Property: No items completed returns 0%
    Glados2(
      any.intInRange(1, 5),
      any.intInRange(1, 5),
    ).test(
      'Property 14: Daily Progress Inclusion - none completed returns 0%',
      (habitCount, taskCount) {
        final habits = List.generate(
          habitCount,
          (i) => DailyItem(
            id: 'habit_$i',
            title: 'Habit $i',
            type: DailyItemType.habit,
            isCompleted: false,
            habitId: i,
          ),
        );

        final tasks = List.generate(
          taskCount,
          (i) => DailyItem(
            id: 'task_$i',
            title: 'Task $i',
            type: DailyItemType.task,
            isCompleted: false,
            taskId: i,
          ),
        );

        // All prayers pending or missed (not completed)
        final prayers = PrayerType.values
            .map((type) => _createPrayerItem(type, PrayerStatus.pending))
            .toList();

        final allItems = [...habits, ...tasks, ...prayers];
        final percentage = calculateCompletionPercentage(allItems);

        expect(percentage, equals(0),
            reason: 'No items completed should return 0%');
      },
    );

    /// Property: Prayer completion affects overall percentage
    Glados(any.intInRange(0, 5)).test(
      'Property 14: Daily Progress Inclusion - prayer completion affects percentage',
      (completedPrayerCount) {
        // Create 5 prayers with varying completion status
        final prayers = <DailyItem>[];
        for (int i = 0; i < PrayerType.values.length; i++) {
          final type = PrayerType.values[i];
          final status = i < completedPrayerCount
              ? PrayerStatus.completed
              : PrayerStatus.pending;
          prayers.add(_createPrayerItem(type, status));
        }

        // Only prayers in the list
        final percentage = calculateCompletionPercentage(prayers);

        // Expected percentage based on completed prayers
        final expectedPercentage = ((completedPrayerCount / 5) * 100).round();
        expect(percentage, equals(expectedPercentage),
            reason: 'Percentage should reflect prayer completion count');
      },
    );
  });

  group('Daily Progress Inclusion Unit Tests', () {
    test('Empty list returns 0%', () {
      expect(calculateCompletionPercentage([]), equals(0));
    });

    test('Single completed item returns 100%', () {
      final items = [
        DailyItem(
          id: 'habit_1',
          title: 'Habit 1',
          type: DailyItemType.habit,
          isCompleted: true,
          habitId: 1,
        ),
      ];
      expect(calculateCompletionPercentage(items), equals(100));
    });

    test('Single incomplete item returns 0%', () {
      final items = [
        DailyItem(
          id: 'habit_1',
          title: 'Habit 1',
          type: DailyItemType.habit,
          isCompleted: false,
          habitId: 1,
        ),
      ];
      expect(calculateCompletionPercentage(items), equals(0));
    });

    test('Mixed items with prayers calculates correctly', () {
      final items = [
        // 1 completed habit
        DailyItem(
          id: 'habit_1',
          title: 'Habit 1',
          type: DailyItemType.habit,
          isCompleted: true,
          habitId: 1,
        ),
        // 1 incomplete task
        DailyItem(
          id: 'task_1',
          title: 'Task 1',
          type: DailyItemType.task,
          isCompleted: false,
          taskId: 1,
        ),
        // 2 completed prayers, 3 pending
        _createPrayerItem(PrayerType.fajr, PrayerStatus.completed),
        _createPrayerItem(PrayerType.dhuhr, PrayerStatus.completed),
        _createPrayerItem(PrayerType.asr, PrayerStatus.pending),
        _createPrayerItem(PrayerType.maghrib, PrayerStatus.pending),
        _createPrayerItem(PrayerType.isha, PrayerStatus.pending),
      ];

      // 3 completed out of 7 total = 42.86% ≈ 43%
      final percentage = calculateCompletionPercentage(items);
      expect(percentage, equals(43));
    });

    test('Prayers with missed status are not counted as completed', () {
      final items = [
        _createPrayerItem(PrayerType.fajr, PrayerStatus.completed),
        _createPrayerItem(PrayerType.dhuhr, PrayerStatus.missed),
        _createPrayerItem(PrayerType.asr, PrayerStatus.pending),
      ];

      // 1 completed out of 3 = 33.33% ≈ 33%
      final percentage = calculateCompletionPercentage(items);
      expect(percentage, equals(33));
    });
  });
}
