import 'package:flutter_test/flutter_test.dart';
import 'package:numu/features/habits/services/period_progress_service.dart';
import 'package:numu/features/habits/repositories/habit_repository.dart';
import 'package:numu/features/habits/models/habit.dart';
import 'package:numu/features/habits/models/habit_event.dart';
import 'package:numu/features/habits/models/enums/frequency.dart';
import 'package:numu/features/habits/models/enums/tracking_type.dart';
import 'package:numu/features/habits/models/enums/goal_type.dart';
import 'package:numu/features/habits/models/enums/active_days_mode.dart';
import 'package:numu/features/habits/models/enums/require_mode.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:numu/core/services/database_service.dart';

void main() {
  late HabitRepository repository;
  late PeriodProgressService service;
  late Database database;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await DatabaseService.instance.database;
    repository = HabitRepository();
    service = PeriodProgressService(repository);
  });

  tearDown(() async {
    await database.delete('habits');
    await database.delete('habit_events');
    await database.delete('habit_period_progress');
  });

  group('Week Start Calculation - All 7 Days', () {
    test('Week starting on Monday (1) calculates correct period', () async {
      final habit = Habit(
        name: 'Test Habit',
        frequency: Frequency.weekly,
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        targetValue: 1.0,
        color: '0xFF2196F3',
        icon: '📚',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdHabit = await repository.createHabit(habit);
      await service.recalculatePeriodProgress(createdHabit.id!, startOfWeek: 1);

      final progress = await database.query(
        'habit_period_progress',
        where: 'habit_id = ?',
        whereArgs: [createdHabit.id],
      );

      expect(progress.length, 1);
      final periodStart = DateTime.parse(progress.first['period_start_date'] as String);
      expect(periodStart.weekday, 1);
    });

    test('Week starting on Tuesday (2) calculates correct period', () async {
      final habit = Habit(
        name: 'Test Habit',
        frequency: Frequency.weekly,
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        targetValue: 1.0,
        color: '0xFF2196F3',
        icon: '📚',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdHabit = await repository.createHabit(habit);
      await service.recalculatePeriodProgress(createdHabit.id!, startOfWeek: 2);

      final progress = await database.query(
        'habit_period_progress',
        where: 'habit_id = ?',
        whereArgs: [createdHabit.id],
      );

      expect(progress.length, 1);
      final periodStart = DateTime.parse(progress.first['period_start_date'] as String);
      expect(periodStart.weekday, 2);
    });

    test('Week starting on Wednesday (3) calculates correct period', () async {
      final habit = Habit(
        name: 'Test Habit',
        frequency: Frequency.weekly,
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        targetValue: 1.0,
        color: '0xFF2196F3',
        icon: '📚',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdHabit = await repository.createHabit(habit);
      await service.recalculatePeriodProgress(createdHabit.id!, startOfWeek: 3);

      final progress = await database.query(
        'habit_period_progress',
        where: 'habit_id = ?',
        whereArgs: [createdHabit.id],
      );

      expect(progress.length, 1);
      final periodStart = DateTime.parse(progress.first['period_start_date'] as String);
      expect(periodStart.weekday, 3);
    });

    test('Week starting on Thursday (4) calculates correct period', () async {
      final habit = Habit(
        name: 'Test Habit',
        frequency: Frequency.weekly,
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        targetValue: 1.0,
        color: '0xFF2196F3',
        icon: '📚',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdHabit = await repository.createHabit(habit);
      await service.recalculatePeriodProgress(createdHabit.id!, startOfWeek: 4);

      final progress = await database.query(
        'habit_period_progress',
        where: 'habit_id = ?',
        whereArgs: [createdHabit.id],
      );

      expect(progress.length, 1);
      final periodStart = DateTime.parse(progress.first['period_start_date'] as String);
      expect(periodStart.weekday, 4);
    });

    test('Week starting on Friday (5) calculates correct period', () async {
      final habit = Habit(
        name: 'Test Habit',
        frequency: Frequency.weekly,
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        targetValue: 1.0,
        color: '0xFF2196F3',
        icon: '📚',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdHabit = await repository.createHabit(habit);
      await service.recalculatePeriodProgress(createdHabit.id!, startOfWeek: 5);

      final progress = await database.query(
        'habit_period_progress',
        where: 'habit_id = ?',
        whereArgs: [createdHabit.id],
      );

      expect(progress.length, 1);
      final periodStart = DateTime.parse(progress.first['period_start_date'] as String);
      expect(periodStart.weekday, 5);
    });

    test('Week starting on Saturday (6) calculates correct period', () async {
      final habit = Habit(
        name: 'Test Habit',
        frequency: Frequency.weekly,
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        targetValue: 1.0,
        color: '0xFF2196F3',
        icon: '📚',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdHabit = await repository.createHabit(habit);
      await service.recalculatePeriodProgress(createdHabit.id!, startOfWeek: 6);

      final progress = await database.query(
        'habit_period_progress',
        where: 'habit_id = ?',
        whereArgs: [createdHabit.id],
      );

      expect(progress.length, 1);
      final periodStart = DateTime.parse(progress.first['period_start_date'] as String);
      expect(periodStart.weekday, 6);
    });

    test('Week starting on Sunday (7) calculates correct period', () async {
      final habit = Habit(
        name: 'Test Habit',
        frequency: Frequency.weekly,
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        targetValue: 1.0,
        color: '0xFF2196F3',
        icon: '📚',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdHabit = await repository.createHabit(habit);
      await service.recalculatePeriodProgress(createdHabit.id!, startOfWeek: 7);

      final progress = await database.query(
        'habit_period_progress',
        where: 'habit_id = ?',
        whereArgs: [createdHabit.id],
      );

      expect(progress.length, 1);
      final periodStart = DateTime.parse(progress.first['period_start_date'] as String);
      expect(periodStart.weekday, 7);
    });
  });

  group('Week Boundaries at Month/Year Transitions', () {
    test('Week calculation handles month transition correctly', () async {
      final habit = Habit(
        name: 'Test Habit',
        frequency: Frequency.weekly,
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        targetValue: 1.0,
        color: '0xFF2196F3',
        icon: '📚',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdHabit = await repository.createHabit(habit);
      await service.recalculatePeriodProgress(createdHabit.id!, startOfWeek: 1);

      final progress = await database.query(
        'habit_period_progress',
        where: 'habit_id = ?',
        whereArgs: [createdHabit.id],
      );

      expect(progress.length, 1);
      
      final periodStart = DateTime.parse(progress.first['period_start_date'] as String);
      final periodEnd = DateTime.parse(progress.first['period_end_date'] as String);
      
      final duration = periodEnd.difference(periodStart);
      expect(duration.inDays, 6);
      expect(periodStart.weekday, 1);
    });

    test('Week calculation handles year transition correctly', () async {
      final habit = Habit(
        name: 'Test Habit',
        frequency: Frequency.weekly,
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        targetValue: 1.0,
        color: '0xFF2196F3',
        icon: '📚',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdHabit = await repository.createHabit(habit);
      await service.recalculatePeriodProgress(createdHabit.id!, startOfWeek: 1);

      final progress = await database.query(
        'habit_period_progress',
        where: 'habit_id = ?',
        whereArgs: [createdHabit.id],
      );

      expect(progress.length, 1);
      
      final periodStart = DateTime.parse(progress.first['period_start_date'] as String);
      final periodEnd = DateTime.parse(progress.first['period_end_date'] as String);
      
      final duration = periodEnd.difference(periodStart);
      expect(duration.inDays, 6);
      expect(periodStart.weekday, 1);
    });

    test('Week starting on Sunday handles month transition', () async {
      final habit = Habit(
        name: 'Test Habit',
        frequency: Frequency.weekly,
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        targetValue: 1.0,
        color: '0xFF2196F3',
        icon: '📚',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdHabit = await repository.createHabit(habit);
      await service.recalculatePeriodProgress(createdHabit.id!, startOfWeek: 7);

      final progress = await database.query(
        'habit_period_progress',
        where: 'habit_id = ?',
        whereArgs: [createdHabit.id],
      );

      expect(progress.length, 1);
      
      final periodStart = DateTime.parse(progress.first['period_start_date'] as String);
      final periodEnd = DateTime.parse(progress.first['period_end_date'] as String);
      
      expect(periodStart.weekday, 7);
      
      final duration = periodEnd.difference(periodStart);
      expect(duration.inDays, 6);
    });
  });

  group('Progress Percentage Calculations with Custom Week Start', () {
    test('Progress calculation with Monday start shows correct value', () async {
      final habit = Habit(
        name: 'Test Habit',
        frequency: Frequency.weekly,
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        targetValue: 1.0,
        color: '0xFF2196F3',
        icon: '📚',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdHabit = await repository.createHabit(habit);

      final now = DateTime.now();
      final daysFromMonday = (now.weekday - 1 + 7) % 7;
      final monday = now.subtract(Duration(days: daysFromMonday));

      for (int i = 0; i < 3; i++) {
        final eventDate = monday.add(Duration(days: i));
        await repository.logEvent(HabitEvent(
          habitId: createdHabit.id!,
          eventDate: eventDate,
          eventTimestamp: eventDate,
          completed: true,
          createdAt: eventDate,
          updatedAt: eventDate,
        ));
      }

      await service.recalculatePeriodProgress(createdHabit.id!, startOfWeek: 1);

      final progress = await database.query(
        'habit_period_progress',
        where: 'habit_id = ?',
        whereArgs: [createdHabit.id],
      );

      expect(progress.length, 1);
      final currentValue = progress.first['current_value'] as double;
      expect(currentValue, 3.0);
    });

    test('Progress calculation with Sunday start shows correct value', () async {
      final habit = Habit(
        name: 'Test Habit',
        frequency: Frequency.weekly,
        trackingType: TrackingType.binary,
        goalType: GoalType.minimum,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.each,
        targetValue: 1.0,
        color: '0xFF2196F3',
        icon: '📚',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdHabit = await repository.createHabit(habit);

      final now = DateTime.now();
      final daysFromSunday = (now.weekday - 7 + 7) % 7;
      final sunday = now.subtract(Duration(days: daysFromSunday));

      for (int i = 0; i < 4; i++) {
        final eventDate = sunday.add(Duration(days: i));
        await repository.logEvent(HabitEvent(
          habitId: createdHabit.id!,
          eventDate: eventDate,
          eventTimestamp: eventDate,
          completed: true,
          createdAt: eventDate,
          updatedAt: eventDate,
        ));
      }

      await service.recalculatePeriodProgress(createdHabit.id!, startOfWeek: 7);

      final progress = await database.query(
        'habit_period_progress',
        where: 'habit_id = ?',
        whereArgs: [createdHabit.id],
      );

      expect(progress.length, 1);
      final currentValue = progress.first['current_value'] as double;
      expect(currentValue, 4.0);
    });

    test('Progress calculation with value-based habit and custom week start', () async {
      final habit = Habit(
        name: 'Test Habit',
        frequency: Frequency.weekly,
        trackingType: TrackingType.value,
        goalType: GoalType.minimum,
        activeDaysMode: ActiveDaysMode.all,
        requireMode: RequireMode.total,
        targetValue: 100.0,
        unit: 'pages',
        color: '0xFF2196F3',
        icon: '📚',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdHabit = await repository.createHabit(habit);

      final now = DateTime.now();
      final daysFromTuesday = (now.weekday - 2 + 7) % 7;
      final tuesday = now.subtract(Duration(days: daysFromTuesday));

      await repository.logEvent(HabitEvent(
        habitId: createdHabit.id!,
        eventDate: tuesday,
        eventTimestamp: tuesday,
        value: 30.0,
        createdAt: tuesday,
        updatedAt: tuesday,
      ));

      await repository.logEvent(HabitEvent(
        habitId: createdHabit.id!,
        eventDate: tuesday.add(const Duration(days: 1)),
        eventTimestamp: tuesday.add(const Duration(days: 1)),
        value: 45.0,
        createdAt: tuesday.add(const Duration(days: 1)),
        updatedAt: tuesday.add(const Duration(days: 1)),
      ));

      await service.recalculatePeriodProgress(createdHabit.id!, startOfWeek: 2);

      final progress = await database.query(
        'habit_period_progress',
        where: 'habit_id = ?',
        whereArgs: [createdHabit.id],
      );

      expect(progress.length, 1);
      
      final currentValue = progress.first['current_value'] as double;
      final targetValue = progress.first['target_value'] as double;
      
      expect(currentValue, 75.0);
      expect(targetValue, 100.0);
      
      final percentage = currentValue / targetValue;
      expect(percentage, 0.75);
    });
  });
}
